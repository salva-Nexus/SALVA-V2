// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Storage
 * @notice Base storage layout for the Salva singleton.
 * @dev Defines all persistent mappings and structs used across the protocol.
 *      Aliases resolve exclusively to wallet addresses — number resolution
 *      is not supported in this version.
 *
 *      Storage hygiene:
 *        · The MultiSig address is `immutable` — baked into runtime bytecode,
 *          no storage slot consumed.
 *        · All alias mappings use keccak256 welded keys (name + namespace) as
 *          slot identifiers, providing collision-resistant namespace isolation.
 */
abstract contract Storage {
    // ─────────────────────────────────────────────────────────────────────────
    // IMMUTABLE PROTOCOL ACCESS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice The Salva MultiSig contract address.
     * @dev Immutable — baked directly into deployed runtime bytecode.
     *      Only this address may call `initializeRegistry`.
     */
    address internal immutable _MULTISIG;

    // ─────────────────────────────────────────────────────────────────────────
    // NAMESPACE MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Tracks which namespace handles have been claimed.
     * @dev Prevents two different registry contracts from claiming the same
     *      namespace identifier (namespace hijacking).
     *
     *      Key:   bytes16 handle
     *      Value: bool            `true` once the namespace is finalized
     */
    mapping(bytes16 _namespace => bool _initialized) internal _isInitialized;

    /**
     * @notice Maps each registry address to its assigned namespace handle and length.
     * @dev Read by the singleton during every `linkNameAlias` and `unlink` call
     *      to determine which namespace the calling registry owns.
     *
     *      Key:   address registry
     *      Value: Namespace { bytes16 handle, bytes1 length }
     */
    mapping(address _registry => Namespace _namespace) internal _registryNamespace;

    /**
     * @notice Packs a namespace handle with its byte length for gas-efficient reads.
     * @dev Packed layout: [ bytes16 _namespace ][ bytes1 _length ]
     *      Stored as a single cold-read struct in `_registryNamespace`.
     */
    struct Namespace {
        bytes16 _namespace;
        bytes1 _length;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ALIAS RESOLUTION MAPPINGS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Ownership index — maps a sender-scoped hash to the alias nameHash.
     * @dev Written at link time:
     *        slot  = keccak256(nameHash ++ senderEOA)
     *        value = nameHash
     *      Read at unlink time by `_checkCaller` to verify the caller owns the alias.
     *
     *      Key:   bytes32 senderHash  (keccak256 of nameHash + owner EOA)
     *      Value: bytes32 nameHash    (the welded alias storage key)
     */
    mapping(bytes32 _senderHash => bytes32 _nameHash) internal _senderToHash;
}
