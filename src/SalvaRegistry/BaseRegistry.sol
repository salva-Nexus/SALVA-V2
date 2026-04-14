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
 * @notice Primary user interface for a specific Salva namespace.
 * @dev Deployed as an EIP-1167 minimal proxy. Manages signature verification, tiered fee collection,
 * and delegates name-to-address mapping changes to the protocol Singleton.
 */
contract BaseRegistry is Context, Errors {
    using MessageHashUtils for bytes32;
    using SafeERC20 for IERC20;

    /**
     * @notice The protocol Singleton contract for global storage.
     */
    address internal singleton;

    /**
     * @notice The Factory contract providing protocol configuration (Signer and NGNs).
     */
    address internal factory;

    /**
     * @notice The string identifier for this registry's namespace.
     */
    string internal nspace;

    /**
     * @dev Proxy initialization guard.
     */
    bool internal initialized;

    /**
     * @notice Emitted when a name is successfully linked to a wallet.
     * @param name The alias bytes.
     * @param wallet The resolved destination address.
     */
    event LinkSuccess(bytes indexed name, address indexed wallet);

    /**
     * @notice Emitted when a name mapping is removed.
     * @param name The alias bytes that were unlinked.
     */
    event UnlinkSuccess(bytes indexed name);

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Modifier to ensure functions are only called during initial setup.
     */
    modifier isInitialized() {
        _isInitialized();
        _;
    }

    /**
     * @notice Configures the proxy's initial state.
     * @dev Replaces constructor logic for minimal proxy clones.
     * @param _singleton Address of the Salva Singleton.
     * @param _factory Address of the RegistryFactory.
     * @param _namespace The namespace identifier string.
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
     * @notice Links an alias handle to a destination wallet address.
     * @dev Verifies a backend signature and collects a fee before updating the Singleton.
     * Fee logic: 500 units for NGNs (0.5 NGNs), 0.5 units for others (0.5 USDC/USDT).
     * @param _name The name string converted to bytes.
     * @param _wallet The destination address to link.
     * @param _feeToken The ERC20 token used for fee payment.
     * @param signature The backend ECDSA signature authorizing the link.
     * @return _isLinked Boolean success status of the link operation.
     */
    function link(bytes calldata _name, address _wallet, address _feeToken, bytes calldata signature)
        external
        returns (bool _isLinked)
    {
        address _sender = sender();
        bytes32 messageHash;

        // Assembly used for gas-efficient packing and hashing: keccak256(abi.encodePacked(_name, _wallet))
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

        // Tiered fee normalization: 500 units if paying in NGNs, 0.5 units for USDC/USDT.
        uint256 fee = _feeToken == ngns ? 500e6 : 5e5;

        IERC20(_feeToken).safeTransferFrom(_sender, singleton, fee);
        _isLinked = ISalvaSingleton(singleton).linkNameAlias(_name, _wallet, _sender);
        if (_isLinked) {
            emit LinkSuccess(_name, _wallet);
        }
    }

    /**
     * @notice Removes a name mapping from the Singleton.
     * @dev Verification of unlinking rights is handled by the Singleton implementation.
     * @param _name The name bytes to be unlinked.
     * @return _isSuccess Boolean success status of the unlink operation.
     */
    function unlink(bytes calldata _name) external returns (bool _isSuccess) {
        _isSuccess = ISalvaSingleton(singleton).unlink(_name, sender());
        if (_isSuccess) {
            emit UnlinkSuccess(_name);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Resolves a specific name handle to its associated wallet address.
     * @dev Proxies the view call to the protocol Singleton.
     * @param _name The handle to resolve.
     * @return _addr The destination address or address(0) if unmapped.
     */
    function resolveAddress(bytes calldata _name) external view returns (address _addr) {
        _addr = ISalvaSingleton(singleton).resolveAddress(_name);
    }

    /**
     * @notice Returns the namespace identifier for this registry.
     * @return The string name of the managed namespace.
     */
    function namespace() external view returns (string memory) {
        return nspace;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Fetches current protocol configuration from the RegistryFactory.
     */
    function _getSignerAndNGNs() internal view returns (address, address) {
        return RegistryFactory(factory).getSignerAndNGNs();
    }

    /**
     * @dev Internal check to prevent re-initialization of proxy state.
     */
    function _isInitialized() internal {
        if (initialized) {
            revert Errors__Initialized();
        }
        initialized = true;
    }
}
