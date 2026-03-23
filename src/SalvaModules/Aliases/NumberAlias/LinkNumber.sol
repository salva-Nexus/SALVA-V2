// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract LinkNumber is BaseSingleton {

    // Links a number alias to a wallet address under the caller's namespace.
    // Only a registered registry may call this. The same number can exist across
    // different registries without collision because the storage key is namespaced —
    // the number alone is never the key.
    /**
    *  @param _num     The number alias to link (e.g. 1234567890). uint128 — fits in bytes16.
    *  @param _wallet  The wallet address to link the number alias to.
    *  @return _isLinked  Always true on success.
    */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — CALLER VERIFICATION
    // ─────────────────────────────────────────────────────────────────────────
    // namespace(sender()) loads the caller's bytes16 namespace.
    // If zero, they never called initializeRegistry → revert.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — STORAGE POINTER DERIVATION (assembly)
    // ─────────────────────────────────────────────────────────────────────────
    // namespace and _num each fit in bytes16 — together they fill bytes32.
    // OR-welded into one word, offset by the mapping slot, then hashed:
    //
    //   mstore(0xc0, add(or(nspace, _num), _numberToWallet.slot))
    //   ptr = keccak256(0xc0, 0x20)
    //
    //   or(nspace, _num):
    //   nspace occupies LEFT  16 bytes
    //   _num   occupies RIGHT 16 bytes
    //   They never overlap — safe to OR directly.
    //
    //   add(..., _numberToWallet.slot) domain-separates the key from other mappings.
    //   keccak256(0xc0, 0x20) → unique pointer per (namespace, number) pair.
    //
    //   wallet = sload(ptr) — check if number already linked.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — COLLISION + WALLET CHECK
    // ─────────────────────────────────────────────────────────────────────────
    // Two checks before writing:
    // 1. wallet != address(0)                   → number already taken → revert
    // 2. _walletAliases[_wallet].num != 0       → wallet already has a number → revert
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — STORAGE WRITES
    // ─────────────────────────────────────────────────────────────────────────
    // 1. sstore(ptr, _wallet)                  — forward resolution via assembly
    // 2. _walletAliases[_wallet].num = _num    — reverse mapping (bidirectional protection)
    function linkNumberAlias(uint128 _num, address _wallet) external returns (bool _isLinked) {
        (bytes16 nspace,) = namespace(sender());
        if (nspace == bytes16(0)) {
            revert Errors__Not_Registered();
        }

        bytes32 ptr;
        address wallet;
        assembly {
            // OR nspace and _num — namespace occupies left bytes16, _num occupies right bytes16
            // add mapping slot for domain separation, then hash
            mstore(0xc0, add(or(nspace, _num), _numberToWallet.slot))
            ptr := keccak256(0xc0, 0x20)
            wallet := sload(ptr)
        }

        uint128 checkNumber = _walletAliases[_wallet].num;
        if (wallet != address(0) || checkNumber != 0) {
            revert Errors__Taken();
        }

        assembly {
            sstore(ptr, _wallet)
        }
        _walletAliases[_wallet].num = _num;

        _isLinked = true;
    }
}
