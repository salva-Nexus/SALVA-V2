// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Context} from "@Context/Context.sol";
import {Errors} from "@Errors/Errors.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";

/**
 * @title BaseRegistry
 * @notice The user-facing gateway for a single Salva namespace.
 * @dev Each registry is deployed by Salva and corresponds to exactly
 *      one namespace.  It enforces backend
 *      authorization via ECDSA signature verification before forwarding any
 *      link request to the singleton.
 *
 *      Security model:
 *        · `link`   — requires a valid signature from `signer` (Salva backend EOA).
 *                     Prevents direct Etherscan calls from bypassing the reserved-
 *                     name whitelist check performed off-chain.
 *        · `unlink` — callable directly by the alias owner; no signature required
 *                     because ownership is verified inside the singleton via the
 *                     ownership index written at link time.
 *
 *      The registry never holds user funds beyond the fee forwarded to the singleton.
 */
contract BaseRegistry is Context, Errors {
    using MessageHashUtils for bytes32;

    /// @notice The Salva singleton contract that owns all namespace storage.
    address internal immutable SINGLETON;

    /// @notice Chainlink data feed used to price the $1 registration fee in ETH.
    address internal immutable DATA_FEED;

    /// @notice Human-readable namespace string.
    string internal NAMESPACE;

    /// @notice Salva backend EOA whose signature must accompany every `link` call.
    address internal signer;

    /**
     * @param _singleton  Address of the deployed Salva singleton.
     * @param _signer     Salva backend EOA authorised to sign link requests.
     * @param _namespace  Human-readable namespace string for this registry.
     * @param _dataFeed   Chainlink ETH/USD price feed address.
     */
    constructor(address _singleton, address _signer, string memory _namespace, address _dataFeed) {
        SINGLETON = _singleton;
        NAMESPACE = _namespace;
        signer = _signer;
        DATA_FEED = _dataFeed;
    }

    /**
     * @notice Links a name alias to a wallet address within this registry's namespace.
     * @dev Workflow:
     *   1. Reconstruct the message hash from `_name` and `_wallet` using the same
     *      assembly packing the backend used when producing `signature`.
     *   2. Apply the Ethereum signed-message prefix and recover the signer via ECDSA.
     *   3. Revert if the recovered address does not match the stored `signer`.
     *   4. ABI-encode a `linkNameAlias` call and forward it to the singleton with
     *      the registration fee attached.
     *
     *      The user's EOA is captured as `sender()` here and forwarded as `_sender`
     *      so the singleton can build the ownership index for future unlinks.
     *
     * @param _name      Raw alias bytes (e.g. `"charles"`). Must satisfy singleton
     *                   character rules: a–z, 2–9, max one `_`, no 0 or 1.
     * @param _wallet    Wallet address to bind to the alias.
     * @param signature  65-byte ECDSA signature produced by the Salva backend over
     *                   `keccak256(abi.encodePacked(_name, _wallet))`.
     */
    function link(bytes calldata _name, address _wallet, bytes calldata signature) external payable {
        bytes32 messageHash;
        assembly ("memory-safe") {
            calldatacopy(0x00, _name.offset, _name.length)
            mstore(_name.length, shl(sub(0x100, mul(0x14, 0x08)), _wallet))
            messageHash := keccak256(0x00, add(_name.length, 0x14))
        }
        bytes32 digest = messageHash.toEthSignedMessageHash();
        address _signer = ECDSA.recover(digest, signature);
        if (_signer != signer) {
            revert Errors__Invalid_Call_Source();
        }
        bytes memory data =
            abi.encodeWithSelector(ISalvaSingleton(SINGLETON).linkNameAlias.selector, _name, _wallet, sender());
        uint256 fee = ISalvaSingleton(SINGLETON).getFeeInEth(DATA_FEED);
        if (msg.value < fee) {
            revert Errors__Not_Enough_Fee();
        }
        (bool success,) = SINGLETON.call{value: fee}(data);
        if (!success) {
            revert Errors_Failed();
        }
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
        _isSuccess = ISalvaSingleton(SINGLETON).unlink(_name, sender());
    }

    /**
     * @notice Resolves a full namespaced alias to its linked wallet address.
     * @dev Delegates to the singleton's `resolveAddress` view function.
     *      Pass the full handle including namespace.
     * @param _name Full alias bytes including the namespace suffix.
     * @return _addr The wallet address bound to the alias, or `address(0)` if unregistered.
     */
    function resolveAddress(bytes calldata _name) external view returns (address _addr) {
        _addr = ISalvaSingleton(SINGLETON).resolveAddress(_name);
    }

    /**
     * @notice Returns the human-readable namespace string for this registry.
     * @return The namespace string.
     */
    function namespace() external view returns (string memory) {
        return NAMESPACE;
    }
}
