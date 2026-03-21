// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract LinkName is BaseSingleton {
    /**
     * @notice Links a human-readable name alias to a wallet address under the caller's namespace.
     * @dev    Only a registered registry may call this. The same name can exist across
     *         different registries without collision because the storage key is a weld of
     *         the name bytes and the registry's namespace identifier — the name alone
     *         is never the key.
     *
     * @param _name    The name alias to link e.g. "charles". Must be all lowercase —
     *                 enforced by the phishingProof modifier before entering assembly.
     *                 Max length is 16 bytes (bytes16) — enforced inside assembly.
     * @param _wallet  The wallet address to link the name alias to.
     */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — CALLER VERIFICATION
    // ─────────────────────────────────────────────────────────────────────────
    // Confirm the caller is a registered registry by loading their namespace
    // from _registryNamespace[caller]. If zero, they never called
    // initializeRegistry → revert.
    //
    //   Storage pointer derivation — keccak256 on (caller ++ slot):
    //   mstore(0xc0, caller())
    //   mstore(0xe0, _registryNamespace.slot)
    //   nspace = sload(keccak256(0xc0, 0x40))
    //
    //   iszero(nspace) → revert if unregistered.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — NAME LENGTH CHECK
    // ─────────────────────────────────────────────────────────────────────────
    // Since _name is a dynamic string, its length is not enforced at the type
    // level. We enforce a max of 16 bytes (bytes16) here in assembly.
    //
    //   nameLen = mload(_name)  // first word of a string memory is its length
    //
    //   gt(nameLen, 0x10) → name exceeds 16 bytes → revert ✗
    //   gt(nameLen, 0x10) → false → name fits in bytes16 → pass ✓
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — NAME WELDING
    // ─────────────────────────────────────────────────────────────────────────
    // The weldedName packs the name and namespace identifier into a single
    // bytes32 — producing a namespaced key like "charles@salva".
    //
    // This means "charles" under @salva and "charles" under @coinbase are
    // completely different storage keys — no cross-registry collision possible.
    //
    //   name = mload(add(_name, 0x20)) // first 32 bytes of name content
    //
    //   NAMESPACE NORMALIZATION
    //   ────────────────────────
    //   _registryNamespace stores bytes16 values. Solidity left-aligns bytes16
    //   within the right half of a bytes32 slot:
    //
    //   nspace (as loaded from storage):
    //   0x000000000000000000000000000000004073616c766100000000000000000000
    //    ├──────────── 16 zero bytes ────────────────┤├── @salva + padding ──┤
    //                                                 ▲ sitting at position 16
    //
    //   If nameLen < 16, shift namespace left 128 bits to push identifier to far left:
    //   shl(0x80, nspace):
    //   0x4073616c76610000000000000000000000000000000000000000000000000000
    //    ▲ now at far left, ready to weld
    //
    //   If nameLen == 16 (full bytes16 name), no shift needed — the name already
    //   occupies the full left half of bytes32, and the namespace sits naturally
    //   in the right half at its loaded position.
    //
    //   let _nspace := nspace
    //   if iszero(eq(nameLen, 0x10)) {
    //       _nspace := shl(0x80, nspace)
    //   }
    //
    //   HOW WELDING WORKS
    //   ──────────────────
    //   The normalized namespace is shifted RIGHT by (nameLen × 8) bits —
    //   pushing it just after where the name ends. Then OR with the name.
    //
    //   Example: name = "charles" (7 bytes), identifier = "@salva" (6 bytes)
    //
    //   _nspace = 0x4073616c76610000000000000000000000000000000000000000000000000000
    //              "@salva"     ├────────────────── 26 zero bytes ─────────────────┤
    //
    //   shr(mul(7, 0x08), _nspace) → shift right 56 bits (7 bytes):
    //   0x00000000000000 4073616c766100000000000000000000000000000000000000000000
    //    ├── 7 zero bytes ──┤"@salva"├──────────── 19 zero bytes ───────────────┤
    //                        ▲ identifier sits just after the 7-byte name gap
    //
    //   OR with name:
    //   0x636861726c6573 4073616c766100000000000000000000000000000000000000000000
    //    "charles"        "@salva" ├────────────── 19 zero bytes ─────────────────┤
    //
    //   weldedName = "charles@salva" packed left-aligned in bytes32 ✓
    //
    //   ┌─────────────────────────────────────────────────────────────────┐
    //   │  bytes32 weldedName layout                                      │
    //   │                                                                 │
    //   │  0x636861726c65734073616c766100000000000000000000000000000000   │
    //   │   "charles"  "@salva" ├────────── 19 zero bytes ─────────────┤  │
    //   │   7 bytes  + 6 bytes  = 13 bytes total                          │
    //   └─────────────────────────────────────────────────────────────────┘
    //
    //   MAX WELD SIZE
    //   ──────────────
    //   namespace = bytes16 (max 16 bytes)
    //   name      = bytes16 (max 16 bytes, enforced in STEP 2)
    //   weldedName can occupy the full bytes32 slot — up to 32 bytes total.
    //
    // ─────────────────────────────────────────────────────────────────────
    // STEP 4 — NAME COLLISION CHECK
    // ─────────────────────────────────────────────────────────────────────
    // Check that this welded name is not already linked within this namespace.
    //
    //   Storage pointer derivation — ADD-based + slot + salt (no keccak on key):
    //   nameToWalletPtr = add(add(weldedName, _nameToWallet.slot), _NAME_TO_WALLET_SALT)
    //
    //   Salt scatters the pointer into unpredictable 2²⁵⁶ space.
    //
    //   sload(nameToWalletPtr) != 0 → name already linked → revert ✗
    //   sload(nameToWalletPtr) == 0 → name slot empty     → pass   ✓
    //
    // ─────────────────────────────────────────────────────────────────────
    // STEP 5 — WALLET CHECK (BIDIRECTIONAL MAPPING PROTECTION)
    // ─────────────────────────────────────────────────────────────────────
    // One wallet can hold AT MOST one name alias per registry. We enforce this
    // by checking the wallet's reverse mapping before writing.
    //
    //   Storage pointer derivation — address + salt:
    //   walletToNamePtr = add(_wallet, add(_WALLET_ALIASES_SALT, 0x00))
    //
    //   walletToName = sload(walletToNamePtr)
    //
    //   gt(walletToName, 0) → wallet already has a name → revert ✗
    //   gt(walletToName, 0) → false → wallet name slot empty → pass ✓
    //
    // ─────────────────────────────────────────────────────────────────────
    // STEP 6 — STORAGE WRITES
    // ─────────────────────────────────────────────────────────────────────
    // Two writes, both necessary:
    //
    // 1. sstore(nameToWalletPtr, _wallet)
    //    Registers the welded name key → wallet address in _nameToWallet.
    //    This is what resolveAddressViaName reads from.
    //
    // 2. sstore(walletToNamePtr, weldedName)
    //    Registers the reverse mapping: wallet → weldedName.
    //    Enforces the one-name-per-wallet invariant on future calls.
    function linkNameAlias(string memory _name, address _wallet) external phishingProof(_name) {
        assembly {
            // STEP 1 — load namespace via keccak(caller ++ slot)
            mstore(0xc0, caller())
            mstore(0xe0, _registryNamespace.slot)
            let nspace := sload(keccak256(0xc0, 0x40))
            if iszero(nspace) {
                revert(0x00, 0x00)
            }

            // STEP 2 — name length check, max bytes16
            let nameLen := mload(_name)
            let name := mload(add(_name, 0x20))
            if gt(nameLen, 0x10) {
                revert(0x00, 0x00)
            }

            // STEP 3 — weld name + namespace into namespaced storage key
            // charles + @salva → "charles@salva" packed in bytes32
            // bytes16 namespace sits at position 16 in bytes32 — normalize to far left first
            // 0x000000000000000000000000000000004073616c766100000000000000000000
            // if name length is already bytes16, no shift needed
            let _nspace := nspace
            if iszero(eq(nameLen, 0x10)) {
                _nspace := shl(0x80, nspace)
            }
            let weldedName := or(shr(mul(nameLen, 0x08), _nspace), name)

            // STEP 4 — name collision check
            let nameToWalletPtr := add(add(weldedName, _nameToWallet.slot), _NAME_TO_WALLET_SALT)
            if sload(nameToWalletPtr) {
                revert(0x00, 0x00)
            }

            // STEP 5 — wallet check (bidirectional mapping protection)
            let walletToNamePtr := add(_wallet, add(_WALLET_ALIASES_SALT, 0x00))
            let walletToName := sload(walletToNamePtr)
            if gt(walletToName, 0x00) {
                revert(0x00, 0x00)
            }

            // STEP 6 — write both directions
            sstore(nameToWalletPtr, _wallet)
            sstore(walletToNamePtr, weldedName)
        }
    }
}
