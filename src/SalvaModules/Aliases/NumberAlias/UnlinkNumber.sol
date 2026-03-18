// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract UnlinkNumber is BaseSingleton {
    /**
     * @notice Unlinks a 10-digit number alias from a wallet address under the caller's namespace.
     * @dev    Only a registered registry may call this. No existence check is performed —
     *         if the number or wallet passed does not exist or is already unlinked, the call
     *         silently zeroes the relevant storage slots. Registries are expected to pass
     *         correct, existing data — callers passing garbage waste only their own gas.
     *
     * @param _num    The 10-digit number alias to unlink.
     * @param _wallet The wallet address to remove the number alias from.
     */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — CALLER VERIFICATION
    // ─────────────────────────────────────────────────────────────────────────
    // Confirm the caller is a registered registry by loading their namespace.
    // If zero, they never called initializeRegistry → revert.
    //
    //   Storage pointer:
    //   add(or(shl(0x08, caller()), _registryNamespace.slot), _NSPACE_SALT)
    //
    //   iszero(nSpace) → revert if unregistered.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — NUMBER POINTER DERIVATION
    // ─────────────────────────────────────────────────────────────────────────
    // Derive the storage pointer for _numberToWallet[nSpace][_num].
    // keccak256 is required here — the composite key (nSpace ++ _num ++ slot)
    // is 96 bytes, too wide for the OR + salt pattern.
    //
    //   mstore(0xa0, nSpace)
    //   mstore(0xc0, _num)
    //   mstore(0xe0, _numberToWallet.slot)
    //   numToWalletPtr = keccak256(0xa0, 0x60)
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — WALLET ALIAS POINTER + NUMBER SIDE ISOLATION
    // ─────────────────────────────────────────────────────────────────────────
    // Derive the WalletAlias storage pointer for _wallet and load the packed slot.
    // To preserve the bytes24 name side untouched, AND out only the uint64 right side:
    //
    //   walletAliasesPtr = add(or(shl(0x08, _wallet), _walletAliases.slot), _WALLET_ALIASES_SALT)
    //
    //   WALLETALIAS SLOT LAYOUT
    //   ┌────────────────────────────────────────────────┬────────────────┐
    //   │          bytes24 / uint192  (LEFT)             │ uint64 (RIGHT) │
    //   │          name alias  ← PRESERVE                │ number ← ZERO  │
    //   └────────────────────────────────────────────────┴────────────────┘
    //
    //   not(0xffffffffffffffff)
    //   = 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
    //      ├──────────────────── keep left 24 bytes ────────────────┤├─ 0 ─┤
    //
    //   EXAMPLE — wallet has both name and number linked:
    //   walletAliases = 0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //                    ├──────────── bytes24 ("charles@salva") ──────────────┤├─uint64─┤
    //
    //   AND result (_cleanedNumber):
    //   0x636861726c65734073616c766100000000000000000000000000000000000000
    //    ├──────────── bytes24 preserved ───────────────────────┤├── 0 ──┤
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — STORAGE WRITES
    // ─────────────────────────────────────────────────────────────────────────
    // Two writes, no existence checks:
    //
    // 1. sstore(numToWalletPtr, 0x00)
    //    Clears the number → wallet mapping in _numberToWallet.
    //    resolveAddressViaNumber will now return address(0) for this number.
    //
    // 2. sstore(walletAliasesPtr, _cleanedNumber)
    //    Writes back the WalletAlias slot with the uint64 right side zeroed out,
    //    bytes24 name side preserved exactly as it was.
    //
    //    BEFORE:
    //    0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //     ├──────────── bytes24 (name) ────────────────────────────┤├─num─┤
    //
    //    AFTER:
    //    0x636861726c65734073616c766100000000000000000000000000000000000000
    //     ├──────────── bytes24 (name unchanged) ──────────────────┤├─ 0 ─┤
    function unlinkNumber(uint64 _num, address _wallet) external {
        assembly {
            let nSpace := sload(add(or(shl(0x08, caller()), _registryNamespace.slot), _NSPACE_SALT))
            if iszero(nSpace) {
                revert(0x00, 0x00)
            }

            mstore(0xa0, nSpace)
            mstore(0xc0, _num)
            mstore(0xe0, _numberToWallet.slot)
            let numToWalletPtr := keccak256(0xa0, 0x60)
            let walletAliasesPtr := add(or(shl(0x08, _wallet), _walletAliases.slot), _WALLET_ALIASES_SALT)
            let _cleanedNumber := and(sload(walletAliasesPtr), not(0xffffffffffffffff))

            // No existence check — registry is expected to pass correct, existing data.
            // Passing non-existent aliases silently zeroes storage. Caller wastes only their own gas.
            sstore(numToWalletPtr, 0x00)
            sstore(walletAliasesPtr, _cleanedNumber)
        }
    }
}
