// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract LinkNumber is BaseSingleton {
    /**
     *  @notice Links a 10-digit number alias to a wallet address under the caller's namespace.
     *   @dev    Only a registered registry may call this. The same number can exist
     *           across different registries without collision because the key is
     *           namespaced — the number alone is never the key.
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
    // STEP 2 — NUMBER CHECK
    // ─────────────────────────────────────────────────────────────────────────
    // Check that this number is not already linked within this namespace.
    //
    // Numbers are NOT globally unique — 1234567890 can exist at @salva AND
    // @coinbase simultaneously. Uniqueness is scoped to the namespace.
    // The key for _numberToWallet combines nSpace + _num + mapping slot.
    //
    // Three values must be hashed together (96 bytes total) — keccak256 is
    // still required here because the key is wider than 32 bytes and cannot
    // be packed via OR + salt without collision risk:
    //
    //   keccak256(nSpace ++ _num ++ _numberToWallet.slot)
    //
    // We write to 0xa0+ to avoid overwriting ABI-decoded args still in use:
    //
    //   mstore(0xa0, nSpace)
    //   mstore(0xc0, _num)
    //   mstore(0xe0, _numberToWallet.slot)
    //
    //   Memory layout for the hash:
    //   ┌──────────────────────────────────────────────────────────────────────┐
    //   │  0xa0  │  nSpace  (32 bytes)                                         │
    //   ├──────────────────────────────────────────────────────────────────────┤
    //   │  0xc0  │  _num    (32 bytes, uint64 zero-padded on the left)         │
    //   ├──────────────────────────────────────────────────────────────────────┤
    //   │  0xe0  │  _numberToWallet.slot (32 bytes, zero-padded on the left)   │
    //   └──────────────────────────────────────────────────────────────────────┘
    //   keccak256(0xa0, 0x60) → numToWalletPtr  (0x60 = 96 bytes = 3 slots)
    //
    //   sload(numToWalletPtr) != 0 → number already linked → revert ✗
    //   sload(numToWalletPtr) == 0 → number slot empty     → pass   ✓
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — WALLET CHECK (BIDIRECTIONAL MAPPING PROTECTION)
    // ─────────────────────────────────────────────────────────────────────────
    // One wallet can hold AT MOST one of each account alias.
    // We enforce this via the WalletAlias struct, which packs BOTH into
    // a single 32-byte storage slot:
    //
    //   WALLET ALIASES SLOT LAYOUT
    //   ┌────────────────────────────────────────────────┬────────────────┐
    //   │          bytes24 / uint192  (LEFT)             │ uint64 (RIGHT) │
    //   │          name alias                            │ number alias   │
    //   └────────────────────────────────────────────────┴────────────────┘
    //
    //   EXAMPLE — wallet with both name and number already linked:
    //   0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //     ├─────────── bytes24 ("charles@salva") ────────┤├────uint64────┤
    //
    //   Storage pointer derivation:
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
    //   + _WALLET_ALIASES_SALT (0x0c57d69214bd4b97e4912ff651178d8aa7d58a9bddae0f2ba850708500a09061):
    //   final ptr:
    //   0x0c57d69214bd4b97e4912ff6a260a8701c533e5a42888327535778d500a11865
    //    ├──────────────── scattered 32-byte storage pointer ─────────────┤
    //
    //   sload(walletAliasesPtr) → walletAliases (the packed 32-byte slot)
    //
    // To check if a number is already linked to this wallet, we isolate
    // the RIGHT side (uint64) by ANDing with 0x000...0ffffffffffffffff:
    //
    //   walletAliases:
    //   0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //    ├──────────── bytes24 (name) ───────────────────┤├─────uint64───┤
    //
    //   AND mask (isolates right 8 bytes only):
    //   0x000000000000000000000000000000000000000000000000ffffffffffffffff
    //    ├──────────── zeroes out bytes24 side ──────────┤├─────0xff─────┤
    //
    //   AND result:
    //   0x0000000000000000000000000000000000000000000000000000000060d1f2ea
    //    ├──────────── all zeros ────────────────────────┤├─────num──────┤
    //
    //   gt(result, 0) → number side non-zero → wallet already has a number → revert ✗
    //   gt(result, 0) → false               → number side empty            → pass   ✓
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — STORAGE WRITES
    // ─────────────────────────────────────────────────────────────────────────
    // Two writes, both necessary:
    //
    // 1. sstore(numToWalletPtr, _wallet)
    //    Registers the namespaced number key → wallet address in _numberToWallet.
    //    This is what resolveAddressViaNumber reads from.
    //
    // 2. sstore(walletAliasesPtr, or(walletAliases, _num))
    //    Updates the packed WalletAlias slot. OR preserves the existing
    //    bytes24 name side untouched and writes _num into the uint64 side.
    //
    //    BEFORE (wallet has a name but no number yet):
    //    walletAliases = 0x636861726c65734073616c766100000000000000000000000000000000000000
    //                     ├──────────── bytes24 (existing name) ───────────────────────┤├─0─┤
    //
    //    OR _num = 0x0000000000000000000000000000000000000000000000000000000060d1f2ea:
    //
    //    AFTER:
    //    walletAliases = 0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //                     ├──────────── bytes24 unchanged ────────────────┤├─────num──────┤

    function linkNumberAlias(uint64 _num, address _wallet) external {
        assembly {
            // STEP 1 — load namespace via OR + salt storage pointer (no keccak on key)
            let nSpace := sload(add(or(shl(0x08, caller()), _registryNamespace.slot), _NSPACE_SALT))
            if iszero(nSpace) {
                revert(0x00, 0x00)
            }

            // NUMBER CHECK
            // Three values to hash (96 bytes) — keccak256 still required here,
            // key is too wide to pack via OR + salt without collision risk.
            mstore(0xa0, nSpace)
            mstore(0xc0, _num)
            mstore(0xe0, _numberToWallet.slot)
            let numToWalletPtr := keccak256(0xa0, 0x60)
            if sload(numToWalletPtr) {
                revert(0x00, 0x00)
            }

            // WALLET CHECK - BIDIRECTIONAL MAPPING PROTECTION
            // OR + salt storage pointer — no keccak needed on key (see STEP 3 above).
            let walletAliasesPtr := add(or(shl(0x08, _wallet), _walletAliases.slot), _WALLET_ALIASES_SALT)

            let walletAliases := sload(walletAliasesPtr)
            if gt(and(walletAliases, 0xffffffffffffffff), 0x00) {
                revert(0x00, 0x00)
            }

            sstore(numToWalletPtr, _wallet)
            sstore(walletAliasesPtr, or(walletAliases, _num))
        }
    }
}
