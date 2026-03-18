// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract Storage {
    address internal immutable _MULTISIG;
    // ─────────────────────────────────────────────────────────────────────────────
    // STORAGE LAYOUT
    // ─────────────────────────────────────────────────────────────────────────────
    //
    //  SLOT OVERVIEW
    //  ──────────────
    //  slot 0 → _registryIdentifier
    //  slot 1 → _registryNamespace
    //  slot 2 → _nameToWallet
    //  slot 3 → _numberToWallet
    //  slot 4 → _walletAliases
    //
    //  STORAGE POINTER DERIVATION — OR-based + salt offset
    //  ─────────────────────────────────────────────────────
    //  Storage pointers are derived without keccak256 on the key itself.
    //  Instead, each mapping uses a two-step formula:
    //
    //    ptr = add(or(shl(0x08, key), mappingSlot), DOMAIN_SALT)
    //
    //  STEP 1 — OR-pack key and slot into one word:
    //    or(shl(0x08, key), mappingSlot)
    //
    //    The key is shifted left 1 byte to vacate the lowest byte,
    //    which is then filled by the mapping's slot number (< 0x100).
    //    Key and slot never overlap → the OR is bijective.
    //
    //      key (address):
    //      0x000000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c856
    //       ├──── 12 zero bytes ──────────────┤├───── address (20 bytes) ────┤
    //
    //      shl(0x08, key):
    //      0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85600
    //       ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─00─┤
    //                                                                    ▲ free
    //      mappingSlot = 0x01
    //
    //      OR result:
    //      0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85601
    //       ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─01─┤
    //                                                                    ▲ slot tag
    //
    //  STEP 2 — ADD domain salt to scatter the pointer across 2²⁵⁶:
    //    add(OR result, DOMAIN_SALT)
    //
    //    Each mapping has a unique salt = keccak256("salva.v2.singleton.<name>").
    //    Adding it offsets the pointer by a large, domain-specific constant,
    //    landing it in a region of storage that no sequential slot or naive
    //    mapping derivation would ever reach.
    //
    //      OR result    = 0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85601
    //      _NSPACE_SALT = 0x0e69ca985d281c235813eed420b4fabc37bf87db9c2fbe28384506a2c9e52e46
    //
    //      add() result = 0x0e69ca985d281c235813eed5c2d2e347bba05b5e6d55a3c9199955f6f7b74a47
    //                     ├────────────────── fully scattered 32-byte pointer ─────────────┤
    //
    //    Collision between two different (key, mapping) pairs would require
    //    their OR results to differ by exactly the difference of two salts —
    //    cryptographically negligible given the salts are independent keccak outputs.
    //
    //  ⚠  SLOT INVARIANT
    //  ───────────────────
    //  The OR step still requires mappingSlot < 0x100 (fits in 1 byte).
    //  All mappings occupy slots 0–4 — invariant satisfied.
    //  DO NOT insert new state variables before this block; slot numbers
    //  must remain stable or the pointer arithmetic breaks silently.
    //
    // ─────────────────────────────────────────────────────────────────────────────

    // @dev Tracks whether a given identifier (e.g. "@salva") has already been
    //      claimed by any registry. Prevents two registries from registering
    //      the same human-readable namespace handle.
    //
    //      key   → bytes32 identifier, left-aligned, ≤ 12 bytes, '@'-prefixed
    //      value → true if claimed, false (default) if available
    //
    //      Storage pointer:
    //      ptr = add(or(_identifier, _registryIdentifier.slot), _IDENTIFIER_SALT)
    //
    //      _identifier occupies the LEFT  side (up to 12 bytes)
    //      .slot       occupies the RIGHT side (1 byte, slot 0)
    //      They never overlap — safe to OR directly.
    //
    //        _identifier  = 0x4073616c76610000000000000000000000000000000000000000000000000000
    //                        "@salva" ├──────────────── 26 zero bytes ───────────────────────┤
    //
    //        .slot        = 0x0000000000000000000000000000000000000000000000000000000000000000
    //
    //        OR result    = 0x4073616c76610000000000000000000000000000000000000000000000000000
    //
    //        + _IDENTIFIER_SALT:
    //          0x80103e7017b0f74d4759e05bddf541ff54ad4b18ac89d3a488c014864c95e157
    //
    //        final ptr    = 0xc083aa96700ef74d4759e05bddf541ff54ad4b18ac89d3a488c014864c95e157
    //                        ├──────────────── scattered 32-byte storage pointer ────────────┤
    mapping(bytes32 => bool) internal _registryIdentifier;

    // @dev Stores the namespace for each registered registry contract.
    //      A namespace packs the registry's identifier and its address into
    //      a single bytes32 slot — they never overlap because identifier ≤ 12
    //      bytes (left side) and address = 20 bytes (right side).
    //
    //      key   → registry contract address (the caller of initializeRegistry)
    //      value → packed namespace: identifier OR address
    //
    //      NAMESPACE LAYOUT
    //      ┌─────────────────────────────┬──────────────────────────────┐
    //      │   bytes12 (LEFT)            │   address / bytes20 (RIGHT)  │
    //      │   identifier e.g. "@salva"  │   registry contract address  │
    //      └─────────────────────────────┴──────────────────────────────┘
    //      bit 255 ◄────────────────────────────────────────────────── 0
    //
    //      EXAMPLE:
    //      0x4073616c7661000000000000a208e28AA883dDB5A0Eb52d04D473E589054c856
    //       "@salva" (6 bytes) ├─── 6 zero bytes ───┤├── address (20 bytes) ──┤
    //
    //      Storage pointer:
    //      ptr = add(or(shl(0x08, caller()), _registryNamespace.slot), _NSPACE_SALT)
    //
    //        shl(0x08, caller()):
    //        0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85600
    //         ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─00─┤
    //
    //        OR .slot (0x01):
    //        0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85601
    //         ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─01─┤
    //
    //        + _NSPACE_SALT:
    //          0x0e69ca985d281c235813eed420b4fabc37bf87db9c2fbe28384506a2c9e52e46
    //
    //        final ptr:
    //        0x0e69ca985d281c235813eed5c2d2e347bba05b5e6d55a3c9199955f6f7b74a47
    //         ├──────────────── scattered 32-byte storage pointer ─────────────┤
    mapping(address => bytes32) internal _registryNamespace;

    // @dev Resolves a namespaced name alias to a wallet address.
    //      The key is a bytes32 that packs the registry's namespace and
    //      the human-readable name together — so the same name (e.g. "charles")
    //      can exist under @salva AND @coinbase without collision.
    //
    //      key   → namespaced name: namespace OR name bytes (no overlap guaranteed
    //              by the 12-byte identifier constraint and 20-byte address packing)
    //      value → wallet address the name resolves to
    //
    //      Storage pointer:
    //      ptr = add(or(namespacedName, _nameToWallet.slot), _NAME_TO_WALLET_SALT)
    //
    //      Read by: resolveAddressViaName
    mapping(bytes32 => address) internal _nameToWallet;

    // @dev Resolves a namespaced number alias to a wallet address.
    //      Numbers are NOT globally unique — the same 10-digit number can exist
    //      across multiple registries. Uniqueness is scoped to the namespace.
    //
    //      The storage pointer is derived by hashing nSpace ++ _num ++ slot
    //      (keccak256 is required here — the key is 96 bytes, too wide for
    //      the OR + salt pattern used elsewhere):
    //
    //        mstore(0xa0, nSpace)
    //        mstore(0xc0, _num)
    //        mstore(0xe0, _numberToWallet.slot)
    //        ptr = keccak256(0xa0, 0x60)
    //
    //      key   → uint64 number alias (10 digits, e.g. 1234567890)
    //      value → wallet address the number resolves to
    //
    //      Read by: resolveAddressViaNumber
    mapping(uint64 => address) internal _numberToWallet;

    // @dev Bidirectional mapping protection — tracks which aliases a wallet
    //      already holds. Enforces the invariant: one wallet can hold AT MOST
    //      one name alias and one number alias per registry.
    //
    //      key   → wallet address
    //      value → WalletAlias struct (packed into a single 32-byte slot)
    //
    //      WALLETALIAS SLOT LAYOUT
    //      ┌────────────────────────────────────────────────┬────────────────┐
    //      │          bytes24 / uint192  (LEFT)             │ uint64 (RIGHT) │
    //      │          name alias                            │ number alias   │
    //      └────────────────────────────────────────────────┴────────────────┘
    //      bit 255 ◄──────────────────────────────────── 64  63 ──────────── 0
    //
    //      EXAMPLE — wallet with both aliases set:
    //      0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //       ├──────────── bytes24 ("charles@salva") ────────────────────────┤├─uint64─┤
    //
    //      WHY bytes24 AND NOT bytes32?
    //      The name alias is a namespaced handle: "charles@salva" packed as bytes.
    //      bytes32 would consume the full slot, leaving no room for the uint64
    //      number alias. Truncating to bytes24 (192 bits) leaves exactly 64 bits
    //      on the right for the number — one slot, two aliases, zero waste.
    //
    //      Storage pointer:
    //      ptr = add(or(shl(0x08, _wallet), _walletAliases.slot), _WALLET_ALIASES_SALT)
    //
    //        shl(0x08, _wallet):
    //        0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85600
    //         ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─00─┤
    //
    //        OR .slot (0x04):
    //        0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85604
    //         ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─04─┤
    //
    //        + _WALLET_ALIASES_SALT:
    //          0x0c57d69214bd4b97e4912ff651178d8aa7d58a9bddae0f2ba850708500a09061
    //
    //        final ptr:
    //        0x0c57d69214bd4b97e4912ff6a260a8701c533e5a42888327535778d500a11865
    //         ├──────────────── scattered 32-byte storage pointer ─────────────┤
    struct WalletAlias {
        // Stores the namespaced name handle (e.g. "charles@salva") as bytes24.
        // Truncated from bytes32 to pack alongside the uint64 number alias
        // in a single 32-byte storage slot — saves one SLOAD/SSTORE per lookup.
        bytes24 name;
        // 10-digit number alias (e.g. 1234567890). uint64 max (18446744073709551615)
        // comfortably fits any 10-digit number. Occupies the right 8 bytes of
        // the packed WalletAlias slot.
        uint64 num;
    }
    mapping(address => WalletAlias) internal _walletAliases;
}
