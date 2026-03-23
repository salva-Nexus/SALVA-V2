// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract Storage {
    // The MultiSig contract address — the only account authorized to call initializeRegistry.
    // Immutable — set once at Singleton deployment, never changed.
    address internal immutable _MULTISIG;

    // Tracks whether a given namespace (e.g. 0x4073616c766100000000000000000000 = "@salva")
    // has already been claimed. Prevents two registries from registering the same namespace.
    // key   → bytes16 namespace
    // value → true if claimed, false if available
    mapping(bytes16 _namespace => bool _initialized) internal _isInitialized;

    // Stores the namespace assigned to each registered registry contract.
    // key   → registry contract address
    // value → bytes16 namespace (e.g. "@salva" left-aligned in bytes16)
    mapping(address _registry => bytes16 _namespace) internal _registryNamespace;

    // Resolves a welded full name (e.g. "charles@salva" packed as bytes32) to a wallet address.
    // key   → bytes32 fullName (name bytes OR-welded with namespace)
    // value → wallet address
    mapping(bytes32 fullName => address _wallet) internal _nameToWallet;

    // Resolves a namespaced number alias to a wallet address.
    // The key is a keccak256 hash of (namespace OR number + mapping slot) —
    // namespacing ensures the same number can exist across registries without collision.
    // key   → keccak256(add(or(nspace, _num), _numberToWallet.slot))
    // value → wallet address
    mapping(bytes32 numAndNamsapaceHash => address _wallet) internal _numberToWallet;

    // Bidirectional mapping — tracks which aliases a wallet already holds.
    // Enforces: one wallet can hold AT MOST one name alias and one number alias per registry.
    //
    // WALLETALIAS LAYOUT
    // ┌──────────────────────────────────┬────────────────┐
    // │  bytes32 name  (full welded name)│  uint128 num   │
    // └──────────────────────────────────┴────────────────┘
    // key   → wallet address
    // value → WalletAlias struct
    struct WalletAlias {
        bytes32 name;
        uint128 num;
    }
    mapping(address _wallet => WalletAlias _linkedAliases) internal _walletAliases;
}
