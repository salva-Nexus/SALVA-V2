// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Storage
 * @notice Base storage layout for the Salva singleton.
 * @dev Defines persistent mappings and structs for Account Abstraction namespacing.
 */
abstract contract Storage {
    // ─────────────────────────────────────────────────────────────────────────
    // IMMUTABLE / INTERNAL ACCESS (Slots 0+)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice The Salva MultiSig contract address.
     * @dev Only this address may call `initializeRegistry`.
     */
    address internal _MULTISIG;

    // ─────────────────────────────────────────────────────────────────────────
    // NAMESPACE MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Tracks which namespace handles have been claimed.
     * @dev Key: bytes16 handle | Value: bool status.
     */
    mapping(bytes16 _namespace => bool _initialized) internal _isInitialized;

    /**
     * @notice Maps registry addresses to their assigned namespace metadata.
     * @dev Key: address registry | Value: Namespace { handle, length }.
     */
    mapping(address _registry => Namespace _namespace) internal _registryNamespace;

    struct Namespace {
        bytes16 _namespace;
        bytes1 _length;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // THE "GHOST" MAPPINGS (Fixed Position)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Ownership index for unlinking verification.
     * @dev Maps a hash(nameHash + owner) back to the nameHash.
     */
    mapping(bytes32 _senderHash => bytes32 _nameHash) internal _senderToHash;

    /**
     * @notice Explicitly declares the name-to-address mapping in storage.
     * @dev Even though `Resolve.sol` uses inline assembly `sload(nameHash)`,
     * this declaration ensures the Solidity compiler reserves the appropriate
     * storage context and prevents collision with future variables.
     * * Key:   bytes32 nameHash (The "Welded" hash from NameLib)
     * Value: address wallet   (The destination Safe or EOA)
     */
    mapping(bytes32 _nameHash => address _resolvedWallet) public _nameToWallet;

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADEABILITY PROTECTION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Gap for future variables to prevent storage collisions
     * when adding new features to the base logic.
     */
    uint256[50] private __gap;
}
