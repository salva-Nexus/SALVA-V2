// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Storage
 * @notice Base storage layer for the SALVA protocol.
 * @dev Defines the mapping structures for aliases, numbers, and registry namespaces.
 */
abstract contract Storage {
    // ─────────────────────────────────────────────────────────────────────────
    // IMMUTABLE PROTOCOL ACCESS
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @notice The MultiSig contract address.
     * DIAGRAMMATIC ACTION:
     * [ Bytecode Injection ]
     * Because it is 'immutable', the address is baked directly into the
     * deployed contract's runtime code, bypassing storage slot lookups.
     * Access Control: Only this address can call initializeRegistry.
     */
    address internal immutable _MULTISIG;

    // ─────────────────────────────────────────────────────────────────────────
    // NAMESPACE MANAGEMENT (Collision Protection)
    // ─────────────────────────────────────────────────────────────────────────

    // Global registry of claimed namespaces.
    // DIAGRAMMATIC FLOW:
    // Key: bytes16 (e.g., "@salva") -> Value: bool
    // [ "@salva" ] -> [ TRUE ]
    // Prevents "Namespace Hijacking" where two different registry contracts
    // attempt to claim the same identifier.
    mapping(bytes16 _namespace => bool _initialized) internal _isInitialized;

    // Mapping of Registry Addresses to their specific handle.
    // DIAGRAMMATIC FLOW:
    // Key: address -> Value: Struct Namespace
    // [ Registry_A ] -> { bytes16: "@salva", bytes1: 6 }
    mapping(address _registry => Namespace _namespace) internal _registryNamespace;

    // Struct to pack namespace handle and its byte length.
    // Packed Layout: [ bytes16 handle ][ bytes1 length ]
    struct Namespace {
        bytes16 _namespace;
        bytes1 _length;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ALIAS RESOLUTION MAPPINGS (The Core Ledger)
    // ─────────────────────────────────────────────────────────────────────────

    // Forward resolution from Alias Hash to Number.
    // DIAGRAMMATIC ACTION:
    // [ nameHash ] -> [ uint256 number ]
    // Used for identifying users via numeric IDs linked to their @handle.
    mapping(bytes32 _nameHash => uint256 _number) internal _nameToNumber;

    // Forward resolution from Alias Hash to Wallet Address.
    // DIAGRAMMATIC ACTION:
    // [ nameHash ] -> [ address wallet ]
    // Used for routing on-chain payments to the correct destination.
    mapping(bytes32 _nameHash => address _wallet) internal _nameToWallet;
}
