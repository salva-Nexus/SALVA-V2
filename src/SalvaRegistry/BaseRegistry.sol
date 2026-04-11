// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Context} from "@Context/Context.sol";
import {Errors} from "@Errors/Errors.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";
import {RegistryFactory} from "@RegistryFactory/RegistryFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title BaseRegistry
 * @author cboi@Salva
 * @notice User-facing gateway for a single Salva namespace.
 * @dev Deployed as an EIP-1167 minimal proxy clone by the RegistryFactory.
 *      Each instance corresponds to exactly one namespace.
 *
 *      Security model:
 *        · `link`   — requires a valid ECDSA signature from the Salva backend signer.
 *                     The signer and data feed are read from the factory on every call,
 *                     so a key rotation propagates instantly with no per-clone update.
 *                     This gate ensures all registrations pass the off-chain reserved-name
 *                     whitelist check before touching the chain.
 *        · `unlink` — callable directly by the alias owner; no signature required.
 *                     Ownership is enforced inside the singleton via the ownership index
 *                     written at link time.
 *
 *      This contract never retains user funds — any ETH received is forwarded to the
 *      singleton as the registration fee within the same call.
 */
contract BaseRegistry is Context, Errors {
    using MessageHashUtils for bytes32;
    using SafeERC20 for IERC20;

    /// @notice Address of the Salva singleton that owns all namespace storage.
    address internal singleton;

    /// @notice Address of the RegistryFactory — source of truth for signer and data feed.
    address internal factory;

    /// @notice Human-readable namespace string for this registry instance (e.g. "@salva").
    string internal namespaceName;

    /// @dev Initialization guard — set to true after the first `initialize` call.
    bool internal initialized;

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Reverts if this clone has already been initialized.
    modifier isInitialized() {
        _isInitialized();
        _;
    }

    /**
     * @notice Initializes the registry clone. Can only be called once.
     * @dev Called by the RegistryFactory immediately after cloning.
     *      Replaces the constructor for EIP-1167 clone compatibility.
     * @param _singleton  Address of the Salva singleton.
     * @param _factory    Address of the RegistryFactory (signer + data feed source).
     * @param _namespace  Human-readable namespace string for this registry.
     */
    function initialize(address _singleton, address _factory, string memory _namespace) external isInitialized {
        singleton = _singleton;
        factory = _factory;
        namespaceName = _namespace;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CORE OPERATIONS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Links a name alias to a wallet address within this registry's namespace.
     * @dev Workflow:
     *   1. Reconstruct the message hash from `_name` and `_wallet` using the same
     *      assembly packing the Salva backend used when producing `signature`.
     *   2. Apply the Ethereum signed-message prefix and recover the signer via ECDSA.
     *   3. Revert if the recovered address does not match the factory's active signer.
     *   4. ABI-encode a `linkNameAlias` call and forward it to the singleton with
     *      the registration fee attached.
     *
     *      The user's EOA is captured as `sender()` and forwarded as `_sender` so the
     *      singleton can build the ownership index for future unlink operations.
     *
     * @param _name      Raw alias bytes (e.g. `"charles"`). should satisfy singleton
     *                   character rules: lowercase a–z, digits 2–9, max one `_`, no 0 or 1.
     *                   Although it doesn't check for that here, the singleton does that
     * @param _wallet    Wallet address to bind to the alias.
     * @param signature  65-byte ECDSA signature produced by the Salva backend over
     *                   `keccak256(abi.encodePacked(_name, _wallet))`.
     */
    function link(bytes calldata _name, address _wallet, address _feeToken, bytes calldata signature) external {
        address _sender = sender();
        bytes32 messageHash;
        assembly ("memory-safe") {
            calldatacopy(0x00, _name.offset, _name.length)
            mstore(_name.length, shl(sub(0x100, mul(0x14, 0x08)), _wallet))
            messageHash := keccak256(0x00, add(_name.length, 0x14))
        }
        bytes32 digest = messageHash.toEthSignedMessageHash();
        address _signer = ECDSA.recover(digest, signature);
        (address activeSigner, address ngns) = _getSignerAndNGNs();
        if (_signer != activeSigner) {
            revert Errors__Invalid_Call_Source();
        }
        uint256 fee = _feeToken == ngns ? 1000e6 : 1e6;

        IERC20(_feeToken).safeTransferFrom(_sender, singleton, fee);
        ISalvaSingleton(singleton).linkNameAlias(_name, _wallet, _sender);
    }

    /**
     * @notice Removes the caller's alias binding from the singleton.
     * @dev Forwards to `ISalvaSingleton.unlink`. Ownership verification is
     *      performed inside the singleton — only the address that originally
     *      registered the alias may unlink it.
     * @param _name Raw alias bytes to unlink (e.g. `"charles"`).
     * @return _isSuccess `true` on successful storage zeroing.
     */
    function unlink(bytes calldata _name) external returns (bool _isSuccess) {
        _isSuccess = ISalvaSingleton(singleton).unlink(_name, sender());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Resolves a full namespaced alias to its linked wallet address.
     * @dev Delegates to the singleton's `resolveAddress` view function.
     *      Pass the full handle including the namespace suffix.
     * @param _name Full alias bytes including the namespace suffix.
     * @return _addr The wallet address bound to the alias, or `address(0)` if unregistered.
     */
    function resolveAddress(bytes calldata _name) external view returns (address _addr) {
        _addr = ISalvaSingleton(singleton).resolveAddress(_name);
    }

    /**
     * @notice Returns the human-readable namespace string for this registry instance.
     * @return The namespace string (e.g. `"@salva"`).
     */
    function namespace() external view returns (string memory) {
        return namespaceName;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Fetches the active signer and Chainlink data feed from the factory.
     *      Called on every `link` to reflect signer rotations immediately.
     * @return Active backend signer EOA and Chainlink ETH/USD feed address.
     */
    function _getSignerAndNGNs() internal view returns (address, address) {
        return RegistryFactory(factory).getSignerAndNGNs();
    }

    /**
     * @dev Initialization guard. Reverts if already initialized, sets flag on first call.
     */
    function _isInitialized() internal {
        if (initialized) {
            revert Errors__Initialized();
        }
        initialized = true;
    }
}
