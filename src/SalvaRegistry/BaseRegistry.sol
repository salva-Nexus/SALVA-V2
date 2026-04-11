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
 * @notice The entry point for users to interact with a specific Salva namespace.
 * @dev This contract is deployed as an EIP-1167 minimal proxy. It handles signature
 * verification and fee collection before delegating the final state change to the Singleton.
 * * Key Architecture:
 * - Each Registry instance is unique to one namespace.
 * - It fetches the protocol `signer` and `NGNs` token address from the Factory on-the-fly.
 * - Registration fees are tiered: 1000 units for NGNs (e.g., 1000 NGNs) or 1 unit for other
 * tokens (e.g., 1 USDC/USDT) to normalize value across assets.
 */
contract BaseRegistry is Context, Errors {
    using MessageHashUtils for bytes32;
    using SafeERC20 for IERC20;

    /**
     * @notice The core protocol storage contract where name-to-address mappings are kept.
     */
    address internal singleton;

    /**
     * @notice The central factory that governs protocol-wide configuration (Signer and NGNs).
     */
    address internal factory;

    /**
     * @notice The human-readable namespace this registry manages
     */
    string internal nspace;

    /**
     * @dev Simple guard to prevent re-initialization of the proxy.
     */
    bool internal initialized;

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Prevents the `initialize` function from being called more than once.
     */
    modifier isInitialized() {
        _isInitialized();
        _;
    }

    /**
     * @notice Configures the newly cloned registry instance.
     * @dev Since clones cannot use constructors, this function sets the initial state.
     * @param _singleton The Salva Singleton address.
     * @param _factory The RegistryFactory address.
     * @param _namespace The string name of this registry's namespace.
     */
    function initialize(address _singleton, address _factory, string memory _namespace) external isInitialized {
        singleton = _singleton;
        factory = _factory;
        nspace = _namespace;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CORE OPERATIONS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Registers an alias and links it to a destination wallet.
     * @dev Validates an off-chain signature to ensure the name choice is authorized.
     * * Security Logic:
     * 1. Rebuilds the Keccak256 hash using assembly for exact parity with backend packing.
     * 2. Verifies the signature against the `activeSigner` stored in the Factory.
     * 3. Determines the fee: 1000 units if paying in NGNs, otherwise 1 unit.
     * 4. Transfers the fee directly to the Singleton and executes the link.
     * * @param _name The alias string (bytes) to be registered.
     * @param _wallet The destination address this name should resolve to.
     * @param _feeToken The ERC20 token the user chooses to pay the registration fee with.
     * @param signature The ECDSA signature from the Salva backend authorizing this link.
     */
    function link(bytes calldata _name, address _wallet, address _feeToken, bytes calldata signature) external {
        address _sender = sender();
        bytes32 messageHash;

        // Manual assembly packing to match: keccak256(abi.encodePacked(_name, _wallet))
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

        // Tiered fee logic: 1000 for NGNs, 1 for others (e.g. USDC)
        uint256 fee = _feeToken == ngns ? 1000e6 : 1e6;

        IERC20(_feeToken).safeTransferFrom(_sender, singleton, fee);
        ISalvaSingleton(singleton).linkNameAlias(_name, _wallet, _sender);
    }

    /**
     * @notice Removes an existing alias mapping.
     * @dev Only the address that originally linked the name can unlink it.
     * This verification is handled by the Singleton.
     * @param _name The alias to be removed.
     * @return _isSuccess Returns true if the unlinking was finalized.
     */
    function unlink(bytes calldata _name) external returns (bool _isSuccess) {
        _isSuccess = ISalvaSingleton(singleton).unlink(_name, sender());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the wallet address associated with a given handle.
     * @dev Queries the Singleton directly for resolution.
     * @param _name The full handle.
     * @return _addr The resolved address, or address(0) if not found.
     */
    function resolveAddress(bytes calldata _name) external view returns (address _addr) {
        _addr = ISalvaSingleton(singleton).resolveAddress(_name);
    }

    /**
     * @notice Returns the name of the namespace this registry governs.
     * @return The string namespace name.
     */
    function namespace() external view returns (string memory) {
        return nspace;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Internal helper to query the Factory for the latest protocol configuration.
     */
    function _getSignerAndNGNs() internal view returns (address, address) {
        return RegistryFactory(factory).getSignerAndNGNs();
    }

    /**
     * @dev Logic for the initialization guard.
     */
    function _isInitialized() internal {
        if (initialized) {
            revert Errors__Initialized();
        }
        initialized = true;
    }
}
