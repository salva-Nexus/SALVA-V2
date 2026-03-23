// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract UnlinkNumber is BaseSingleton {

    // Unlinks a number alias from its wallet address under the caller's namespace.
    // Only a registered registry may call this.
    //
    // Only the number is passed — the wallet address is derived from the number via
    // the storage pointer. This prevents an attacker from passing in another person's
    // wallet address to unlink their alias.
    //
    // No existence check is performed — if the number is not linked, the call
    // silently zeroes already-zero slots. Caller wastes only their own gas.
    /**
    *  @param _num       The number alias to unlink.
    *  @return _isUnlinked  Always true on success.
    */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — CALLER VERIFICATION
    // ─────────────────────────────────────────────────────────────────────────
    // namespace(sender()) loads the caller's bytes16 namespace.
    // If zero, they never called initializeRegistry → revert.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — STORAGE POINTER DERIVATION + WALLET LOAD (assembly)
    // ─────────────────────────────────────────────────────────────────────────
    // Same pointer derivation as linkNumberAlias — reconstructs the same slot:
    //
    //   mstore(0xc0, add(or(nspace, _num), _numberToWallet.slot))
    //   ptr = keccak256(0xc0, 0x20)
    //   _wallet = sload(ptr)    — derive wallet from storage, not from caller input
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — STORAGE WRITES
    // ─────────────────────────────────────────────────────────────────────────
    // 1. sstore(ptr, 0x00)              — zero the forward mapping
    // 2. _walletAliases[_wallet].num = 0 — zero the reverse mapping
    function unlinkNumber(uint128 _num) external returns (bool _isUnlinked) {
        (bytes16 nspace,) = namespace(sender());
        if (nspace == bytes16(0)) {
            revert Errors__Not_Registered();
        }

        address _wallet;
        assembly {
            // OR nspace and _num — namespace left bytes16, _num right bytes16
            // add mapping slot for domain separation, then hash
            mstore(0xc0, add(or(nspace, _num), _numberToWallet.slot))
            let ptr := keccak256(0xc0, 0x20)
            _wallet := sload(ptr)

            sstore(ptr, 0x00)
        }
        _walletAliases[_wallet].num = 0;

        _isUnlinked = true;
    }
}
