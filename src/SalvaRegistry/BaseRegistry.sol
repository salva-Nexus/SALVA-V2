// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IRegistryFactory } from "@IRegistryFactory/IRegistryFactory.sol";
import { ISalvaSingleton } from "@ISalvaSingleton/ISalvaSingleton.sol";
import { RegistryErrors } from "@RegistryErrors/RegistryErrors.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title BaseRegistry
 * @author cboi@Salva
 * @notice Primary user interface for a specific Salva namespace.
 *         See {IBaseRegistry} for full interface documentation.
 *
 * @dev Deployed as an EIP-1167 minimal proxy by `RegistryFactory`.
 *      Manages ECDSA signature verification and tiered fee collection,
 *      then delegates all name-to-address storage writes to the Singleton.
 *
 *      Configuration (signer, NGNs address, fee) is fetched dynamically from
 *      the `RegistryFactory` on every `link` call, enabling protocol-wide
 *      updates without re-deploying clones.
 */
contract BaseRegistry is RegistryErrors {
    using MessageHashUtils for bytes32;
    using SafeERC20 for IERC20;

    // ─────────────────────────────────────────────────────────────────────────
    // STATE
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev The Singleton contract — global storage layer for all alias writes.
    address internal _singleton;

    /// @dev The RegistryFactory — provides signer, NGNs address, and fee config.
    address internal _factory;

    /// @dev The string namespace identifier for this registry (e.g. `"[at]salva"`).
    string internal _namespace;

    /// @dev Proxy initialization guard. Set to `true` after `initialize` is called.
    bool internal _initialized;

    // ─────────────────────────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Emitted when a name alias is successfully linked to a wallet address.
    event LinkSuccess(bytes name, address indexed wallet);

    /// @notice Emitted when a name alias binding is successfully removed.
    event UnlinkSuccess(bytes name);

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Guards `initialize` so it can only be called once on each clone.
     */
    modifier onlyUninitialized() {
        _requireUninitialized();
        _;
    }

    /// @dev See {IBaseRegistry} for full documentation.
    function initialize(address singleton, address factory, string memory namespace_)
        external
        onlyUninitialized
    {
        _singleton = singleton;
        _factory = factory;
        _namespace = namespace_;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CORE OPERATIONS
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev See {IBaseRegistry} for full documentation.
    function link(bytes calldata name, address wallet, bytes calldata signature)
        external
        returns (bool isLinked)
    {
        address caller = msg.sender;
        bytes32 messageHash;

        // Assembly: gas-efficient keccak256(abi.encodePacked(name, wallet))
        // Avoids ABI encoding overhead for this hot path.
        assembly ("memory-safe") {
            calldatacopy(0x00, name.offset, name.length)
            mstore(name.length, shl(sub(0x100, mul(0x14, 0x08)), wallet))
            messageHash := keccak256(0x00, add(name.length, 0x14))
        }

        bytes32 digest = messageHash.toEthSignedMessageHash();
        address recovered = ECDSA.recover(digest, signature);

        (address activeSigner, address ngns) = _fetchSignerAndNGNs();

        if (recovered != activeSigner) {
            revert Errors__InvalidCallSource();
        }

        uint256 fee = _fetchFee();

        if (fee != 0) {
            IERC20(ngns).safeTransferFrom(caller, _singleton, fee);
        }

        isLinked = ISalvaSingleton(_singleton).linkNameAlias(name, wallet, caller);

        if (isLinked) {
            emit LinkSuccess(name, wallet);
        }
    }

    /// @dev See {IBaseRegistry} for full documentation.
    function unlink(bytes calldata name) external returns (bool isSuccess) {
        isSuccess = ISalvaSingleton(_singleton).unlink(name, msg.sender);
        if (isSuccess) {
            emit UnlinkSuccess(name);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev See {IBaseRegistry} for full documentation.
    function resolveAddress(bytes calldata name) external view returns (address addr) {
        addr = ISalvaSingleton(_singleton).resolveAddress(name);
    }

    /// @dev See {IBaseRegistry} for full documentation.
    function namespace() external view returns (string memory) {
        return _namespace;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Fetches the active signer and NGNs token addresses from the RegistryFactory.
     *      Reverts if the Factory is paused.
     */
    function _fetchSignerAndNGNs() internal view returns (address signer, address ngns) {
        (signer, ngns) = IRegistryFactory(_factory).getSignerAndNGNs();
    }

    /**
     * @dev Fetches the current protocol link fee from the RegistryFactory.
     *      Reverts if the Factory is paused.
     */
    function _fetchFee() internal view returns (uint256 fee) {
        fee = IRegistryFactory(_factory).getFee();
    }

    /**
     * @dev Internal check to prevent re-initialization of proxy state.
     *      Sets `_initialized = true` atomically on first call.
     */
    function _requireUninitialized() internal {
        if (_initialized) revert Errors__AlreadyInitialized();
        _initialized = true;
    }
}
