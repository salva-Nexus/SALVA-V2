// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract LinkName is BaseSingleton {
    /**
     * @notice Links a human-readable name alias to a wallet address under the caller's namespace.
     *  @dev    Only a registered registry may call this. The same name can exist
     *          across different registries without collision because the key is
     *          a welded combination of the name and the registry's identifier —
     *          the name alone is never the key.
     */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — CALLER VERIFICATION
    // ─────────────────────────────────────────────────────────────────────────
    // Confirm the caller is a registered registry by loading their namespace
    // from _registryNamespace[caller]. If zero, they never called
    // initializeRegistry → revert.
    //
    //   Storage pointer derivation:
    //   add(or(shl(0x08, caller()), _registryNamespace.slot), _NSPACE_SALT)
    //
    //   shl(0x08, caller()):
    //   0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85600
    //    ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─00─┤
    //
    //   OR .slot (0x01):
    //   0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85601
    //    ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─01─┤
    //
    //   + _NSPACE_SALT (0x0e69ca985d281c235813eed420b4fabc37bf87db9c2fbe28384506a2c9e52e46):
    //   final ptr:
    //   0x0e69ca985d281c235813eed5c2d2e347bba05b5e6d55a3c9199955f6f7b74a47
    //    ├──────────────── scattered 32-byte storage pointer ─────────────┤
    //
    //   sload(ptr) → nSpace
    //
    //   nSpace example:
    //   0x4073616c7661000000000000a208e28AA883dDB5A0Eb52d04D473E589054c856
    //    "@salva" (identifier) ├────── registry address (20 bytes) ──────────┤
    //
    //   iszero(nSpace) → revert if nSpace is 0x00(empty) — caller is not a registered registry.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — IDENTIFIER EXTRACTION
    // ─────────────────────────────────────────────────────────────────────────
    // The namespace packs BOTH the identifier and the registry address into one
    // bytes32 slot. To weld the name, we only need the LEFT side (identifier).
    // We strip the RIGHT side (address, 20 bytes) by ANDing with NOT(address mask):
    //
    //   nSpace:
    //   0x4073616c7661000000000000a208e28AA883dDB5A0Eb52d04D473E589054c856
    //    "@salva" (12 bytes LEFT) ├────── address (20 bytes RIGHT) ──────────┤
    //
    //   not(0xffffffffffffffffffffffffffffffffffffffff)
    //   = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000
    //      ├──── keep left 12 bytes ────────┤├──── zero right 20 bytes ──────┤
    //
    //   AND result (_identifier):
    //   0x4073616c76610000000000000000000000000000000000000000000000000000
    //    "@salva" (6 bytes) ├──────────────── 26 zero bytes ─────────────────┤
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — NAME WELDING
    // ─────────────────────────────────────────────────────────────────────────
    // The weldedName packs the name and identifier into a single bytes32 —
    // producing a namespaced key like "charles@salva".
    //
    // This means "charles" under @salva and "charles" under @coinbase are
    // completely different storage keys — no cross-registry collision possible.
    //
    //   HOW WELDING WORKS
    //   ──────────────────
    //   The identifier is left-aligned in bytes32. To make room for the name
    //   at the left side, we shift the identifier RIGHT by (nameLen × 8) bits,
    //   pushing it just after where the name ends. Then OR with the name.
    //
    //   Example: name = "charles" (7 bytes), identifier = "@salva" (6 bytes)
    //
    //   nameLen = 7
    //   name    = mload(add(_name, 0x20))
    //           = 0x636861726c65730000000000000000000000000000000000000000000000000
    //              "charles" ├──────────────── 25 zero bytes ────────────────────┤
    //
    //   _identifier:
    //   0x4073616c76610000000000000000000000000000000000000000000000000000
    //    "@salva" ├──────────────────── 26 zero bytes ──────────────────────────┤
    //
    //   shr(mul(7, 0x08), _identifier) → shift right 56 bits (7 bytes):
    //   0x0000000000000040 73616c7661000000000000000000000000000000000000000000
    //    ├─── 7 zero bytes ──┤"@salva"├──────── 19 zero bytes ──────────────────┤
    //                         ▲ identifier now sits just after the 7-byte name gap
    //
    //   OR with name:
    //   0x636861726c657340 73616c766100000000000000000000000000000000000000000000
    //    "charles"          "@salva" ├────────── 19 zero bytes ───────────────────┤
    //
    //   weldedName = "charles@salva" packed left-aligned in bytes32 ✓
    //
    //   ┌─────────────────────────────────────────────────────────────────┐
    //   │  bytes32 weldedName layout                                      │
    //   │                                                                 │
    //   │  0x636861726c65734073616c766100000000000000000000000000000000   │
    //   │   "charles"  "@salva" ├──────── 19 zero bytes ──────────────┤   │
    //   │   7 bytes  + 6 bytes  = 13 bytes total                          │
    //   └─────────────────────────────────────────────────────────────────┘
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — NAME COLLISION CHECK
    // ─────────────────────────────────────────────────────────────────────────
    // Check that this welded name is not already linked within this namespace.
    //
    //   Storage pointer:
    //   add(or(weldedName, _nameToWallet.slot), _NAME_TO_WALLET_SALT)
    //
    //   weldedName occupies the LEFT side (up to 24 bytes max, guaranteed by
    //   STEP 6 size check below). .slot occupies the lowest byte (slot 2).
    //   They never overlap — safe to OR directly.
    //
    //   weldedName   = 0x636861726c65734073616c766100000000000000000000000000000000000000
    //                   "charles@salva" ├──────── 19 zero bytes ───────────────────────┤
    //
    //   OR .slot (0x02):
    //   0x636861726c65734073616c766100000000000000000000000000000000000002
    //    "charles@salva" ├──────── 19 zero bytes ────────────────────┤├─02─┤
    //
    //   + _NAME_TO_WALLET_SALT:
    //   0x5415ea9680222ca68b72c70a4b6b69e33e700d6299885d0ba1fa188b932267c1
    //
    //   final ptr:
    //   0xba6f4c22f8472d4af7e530af07f213e6742e0d38321452cbf214205f1c4587c3
    //    ├──────────────── scattered 32-byte storage pointer ─────────────┤
    //
    //   sload(nameToAddrPtr) != 0 → name already linked → revert ✗
    //   sload(nameToAddrPtr) == 0 → name slot empty     → pass   ✓
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 5 — WALLET CHECK (BIDIRECTIONAL MAPPING PROTECTION)
    // ─────────────────────────────────────────────────────────────────────────
    // One wallet can hold AT MOST one name alias. We enforce this by checking
    // the LEFT side (bytes24) of the packed WalletAlias slot:
    //
    //   WALLET ALIASES SLOT LAYOUT
    //   ┌────────────────────────────────────────────────┬────────────────┐
    //   │          bytes24 / uint192  (LEFT)             │ uint64 (RIGHT) │
    //   │          name alias                            │ number alias   │
    //   └────────────────────────────────────────────────┴────────────────┘
    //   bit 255 ◄──────────────────────────────────── 64  63 ──────────── 0
    //
    //   Storage pointer:
    //   add(or(shl(0x08, _wallet), _walletAliases.slot), _WALLET_ALIASES_SALT)
    //
    //   shl(0x08, _wallet):
    //   0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85600
    //    ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─00─┤
    //
    //   OR .slot (0x04):
    //   0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85604
    //    ├─── 11 zero bytes ──────────────┤├── address (20 bytes) ──┤├─04─┤
    //
    //   + _WALLET_ALIASES_SALT:
    //   0x0c57d69214bd4b97e4912ff651178d8aa7d58a9bddae0f2ba850708500a09061
    //
    //   final ptr:
    //   0x0c57d69214bd4b97e4912ff6a260a8701c533e5a42888327535778d500a11865
    //    ├──────────────── scattered 32-byte storage pointer ─────────────┤
    //
    //   sload(walletAliasesPtr) → walletAliases (the packed 32-byte slot)
    //
    //   To check if a name is already linked, isolate the LEFT side (bytes24)
    //   by ANDing with NOT(uint64 mask):
    //
    //   not(0xffffffffffffffff)
    //   = 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
    //      ├──────────────────── keep left 24 bytes ───────────────────┤├─ 0 ─┤
    //
    //   EXAMPLE — wallet with name already linked:
    //   walletAliases:
    //   0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //    ├──────────── bytes24 ("charles@salva") ───────────────┤├─uint64─┤
    //
    //   AND result:
    //   0x636861726c65734073616c766100000000000000000000000000000000000000
    //    ├──────────── bytes24 non-zero ────────────────────────────┤├── 0 ───┤
    //
    //   gt(result, 0) → name side non-zero → wallet already has a name → revert ✗
    //   gt(result, 0) → false             → name side empty            → pass   ✓
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 6 — WELDED NAME SIZE GUARD
    // ─────────────────────────────────────────────────────────────────────────
    // The weldedName is stored in the LEFT side (bytes24 / uint192) of the
    // packed WalletAlias slot. It must NOT bleed into the RIGHT side (uint64)
    // which is reserved for the number alias.
    //
    //   WalletAlias slot boundary:
    //   ┌────────────────────────────────────────────────┬────────────────┐
    //   │          bytes24 (LEFT) — name goes here       │ uint64 (RIGHT) │
    //   │          max 24 bytes = 192 bits               │ MUST stay 0    │
    //   └────────────────────────────────────────────────┴────────────────┘
    //
    //   Guard: weldedName == and(weldedName, not(0xffffffffffffffff))
    //
    //   not(0xffffffffffffffff)
    //   = 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
    //      ├──────────────── left 24 bytes intact ─────────────────────────┤├─ 0 ─┤
    //
    //   PASS — weldedName fits in bytes24 (right 8 bytes are zero):
    //   weldedName = 0x636861726c65734073616c766100000000000000000000000000000000000000
    //                 "charles@salva" ├─────────── 19 zero bytes ──────────────────────┤
    //
    //   AND result = 0x636861726c65734073616c766100000000000000000000000000000000000000
    //
    //   eq(weldedName, AND result) = 1 → fits in bytes24 → pass ✓
    //
    //   FAIL — weldedName overflows into uint64 space (right 8 bytes non-zero):
    //   weldedName = 0x636861726c65734073616c7661636861726c65734073616c7661000060d1f2ea
    //                 ├─── name+identifier too long, bleeds into uint64 ──────────────┤
    //
    //   AND result = 0x636861726c65734073616c7661636861726c65734073616c76610000000000000
    //
    //   eq(weldedName, AND result) = 0 → overflows uint64 space → revert ✗
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 7 — STORAGE WRITES
    // ─────────────────────────────────────────────────────────────────────────
    // Two writes, both necessary:
    //
    // 1. sstore(nameToAddrPtr, _wallet)
    //    Registers the namespaced welded name key → wallet address in _nameToWallet.
    //    This is what resolveAddressViaName reads from.
    //
    // 2. sstore(walletAliasesPtr, or(walletAliases, weldedName))
    //    Updates the packed WalletAlias slot. OR preserves the existing
    //    uint64 number side untouched and writes weldedName into the bytes24 side.
    //
    //    BEFORE (wallet has a number but no name yet):
    //    walletAliases = 0x000000000000000000000000000000000000000000000000000000060d1f2ea
    //                     ├──────────────── bytes24 all zeros ────────────────────────┤├─num─┤
    //
    //    OR weldedName = 0x636861726c65734073616c766100000000000000000000000000000000000000:
    //
    //    AFTER:
    //    walletAliases = 0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //                     ├──────────── bytes24 (name written) ───────────────────────┤├─num─┤
    function linkNameAlias(string memory _name, address _wallet) external phishingProof {
        assembly {
            let nSpace := sload(add(or(shl(0x08, caller()), _registryNamespace.slot), _NSPACE_SALT))
            if iszero(nSpace) {
                revert(0x00, 0x00)
            }

            // clean and pick the identifier
            let _identifier := and(nSpace, not(0xffffffffffffffffffffffffffffffffffffffff))

            // NAME CHECK
            let nameLen := mload(_name)
            let name := mload(add(_name, 0x20))

            // weld name and identifier together to create a unique namespace for this alias,
            // this allows us to have multiple aliases per registry without collision
            // Eq -> Charles@Salva, Charles@Coinbase
            let weldedName := or(shr(mul(nameLen, 0x08), _identifier), name)

            let nameToWalletPtr := add(or(weldedName, _nameToWallet.slot), _NAME_TO_WALLET_SALT)
            // revert if name is already taken, this prevents overwriting existing mappings and ensures one-time assignment
            if sload(nameToWalletPtr) {
                revert(0x00, 0x00)
            }

            // WALLET CHECK - BIDIRECTIONAL MAPPING PROTECTIONj
            let walletAliasesPtr := add(or(shl(0x08, _wallet), _walletAliases.slot), _WALLET_ALIASES_SALT)
            let walletAliases := sload(walletAliasesPtr)

            // bytes24 name Space must be empty
            if gt(and(walletAliases, not(0xffffffffffffffff)), 0x00) {
                revert(0x00, 0x00)
            }

            // we have to make sure that name (name + identifier) doesn't go past uint192, so as not to corrupt the number space.
            // if cleaned up name + identifier exceeds 128 bits, revert
            if iszero(eq(weldedName, and(weldedName, not(0xffffffffffffffff)))) {
                revert(0x00, 0x00)
            }

            sstore(nameToWalletPtr, _wallet)
            sstore(walletAliasesPtr, or(walletAliases, weldedName))
        }
    }
}
