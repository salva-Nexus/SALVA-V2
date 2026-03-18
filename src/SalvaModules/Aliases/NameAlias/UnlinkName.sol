// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract UnlinkName is BaseSingleton {
    /**
     * @notice Unlinks a name alias from a wallet address under the caller's namespace.
     * @dev    Only a registered registry may call this. No existence check is performed —
     *         if the name or wallet passed does not exist or is already unlinked, the call
     *         silently zeroes the relevant storage slots. Registries are expected to pass
     *         correct, existing data — callers passing garbage waste only their own gas.
     *
     * @param _name   The fully welded name alias to unlink (e.g. "charles@salva").
     * @param _wallet The wallet address to remove the name alias from.
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
    // STEP 2 — NAME POINTER DERIVATION
    // ─────────────────────────────────────────────────────────────────────────
    // Derive the storage pointer for _nameToWallet[weldedName].
    // The caller passes the fully welded name (e.g. "charles@salva") —
    // the same form that linkNameAlias stored. We read it directly from
    // memory at add(_name, 0x20), which is where Solidity places the
    // first 32 bytes of string content.
    //
    //   _name pointer layout in memory:
    //   ┌──────────────────────────────────────────────────────────┐
    //   │  _name        │  length word (32 bytes)                  │
    //   ├──────────────────────────────────────────────────────────┤
    //   │  _name + 0x20 │  string content (left-aligned, 32 bytes) │
    //   └──────────────────────────────────────────────────────────┘
    //
    //   mload(add(_name, 0x20)) → weldedName bytes32
    //
    //   nameToWalletPtr = add(or(weldedName, _nameToWallet.slot), _NAME_TO_WALLET_SALT)
    //
    //   weldedName occupies the LEFT side (up to 24 bytes).
    //   .slot occupies the lowest byte (slot 2). They never overlap — safe to OR directly.
    //
    //   EXAMPLE — weldedName = "charles@salva":
    //   weldedName   = 0x636861726c65734073616c766100000000000000000000000000000000000000
    //                   "charles@salva" ├──────── 19 zero bytes ───────────────────────┤
    //
    //   OR .slot (0x02):
    //   0x636861726c65734073616c766100000000000000000000000000000000000002
    //    "charles@salva" ├──────── 19 zero bytes ────────────────────┤├─02─┤
    //
    //   + _NAME_TO_WALLET_SALT:
    //   final ptr → scattered 32-byte storage pointer ✓
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — WALLET ALIAS POINTER + NAME SIDE ISOLATION
    // ─────────────────────────────────────────────────────────────────────────
    // Derive the WalletAlias storage pointer for _wallet and load the packed slot.
    // To preserve the uint64 number side untouched, AND out only the bytes24 left side:
    //
    //   walletAliasesPtr = add(or(shl(0x08, _wallet), _walletAliases.slot), _WALLET_ALIASES_SALT)
    //
    //   WALLETALIAS SLOT LAYOUT
    //   ┌────────────────────────────────────────────────┬─────────────────────┐
    //   │          bytes24 / uint192  (LEFT)             │ uint64 (RIGHT)      │
    //   │          name alias  ← ZERO                    │ number ← PRESERVE   │
    //   └────────────────────────────────────────────────┴─────────────────────┘
    //
    //   AND mask to isolate ONLY the uint64 right side:
    //   0x000000000000000000000000000000000000000000000000ffffffffffffffff
    //    ├──────────────────── zero left 24 bytes ───────────────┤├─0xff─┤
    //
    //   EXAMPLE — wallet has both name and number linked:
    //   walletAliases = 0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //                    ├──────────── bytes24 ("charles@salva") ──────────┤├─uint64─┤
    //
    //   AND result (_cleanedName):
    //   0x000000000000000000000000000000000000000000000000000000060d1f2ea
    //    ├──────────────────── all zeros ──────────────┤├─num preserved─┤
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — STORAGE WRITES
    // ─────────────────────────────────────────────────────────────────────────
    // Two writes, no existence checks:
    //
    // 1. sstore(nameToWalletPtr, 0x00)
    //    Clears the name → wallet mapping in _nameToWallet.
    //    resolveAddressViaName will now return address(0) for this name.
    //
    // 2. sstore(walletAliasesPtr, _cleanedName)
    //    Writes back the WalletAlias slot with the bytes24 left side zeroed out,
    //    uint64 number side preserved exactly as it was.
    //
    //    BEFORE:
    //    0x636861726c65734073616c766100000000000000000000000000000060d1f2ea
    //     ├──────────── bytes24 (name) ────────────────────────────┤├─num─┤
    //
    //    AFTER:
    //    0x000000000000000000000000000000000000000000000000000000060d1f2ea
    //     ├──────────────────── all zeros ─────────────────────────┤├─num─┤
    function unlinkName(string memory _name, address _wallet) external {
        assembly {
            let nSpace := sload(add(or(shl(0x08, caller()), _registryNamespace.slot), _NSPACE_SALT))
            if iszero(nSpace) {
                revert(0x00, 0x00)
            }

            let nameToWalletPtr := add(or(mload(add(_name, 0x20)), _nameToWallet.slot), _NAME_TO_WALLET_SALT)
            let walletAliasesPtr := add(or(shl(0x08, _wallet), _walletAliases.slot), _WALLET_ALIASES_SALT)
            let _cleanedName := and(sload(walletAliasesPtr), 0xffffffffffffffff)

            // No existence check — registry is expected to pass correct, existing data.
            // Passing non-existent aliases silently zeroes storage. Caller wastes only their own gas.
            sstore(nameToWalletPtr, 0x00)
            sstore(walletAliasesPtr, _cleanedName)
        }
    }
}
