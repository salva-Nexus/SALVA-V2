// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "@Errors/Errors.sol";

abstract contract MultiSigModifier is Errors {
    // Restricts function access to active validators only.
    // Pass _isValidator[sender()] as the argument.
    modifier onlyValidators(bool _isValidator) {
        if (!_isValidator) {
            revert Errors__Not_Authorized();
        }
        _;
    }

    // Ensures the namespace string fits within bytes16 (128 bits).
    // Used on proposeInitialization to enforce the bytes16 namespace constraint
    // before the string is cast to bytes16 in storage.
    //
    // HOW IT WORKS
    // ─────────────
    // The first 32 bytes of the string content are loaded from memory.
    // A mask zeroes out the LEFT 16 bytes (the bits above 128).
    // If the cleaned value equals the original, the namespace fits in bytes16.
    // If not, data exists beyond byte 16 — the namespace is too long → revert.
    //
    //   nspace  = mload(add(_nspace, 0x20))  // first 32 bytes of string content
    //   cleaned = and(nspace, not(0xffffffffffffffffffffffffffffffff))
    //             keeps only LEFT 16 bytes, zeroes RIGHT 16 bytes
    //
    //   eq(cleaned, nspace) → fits in bytes16 → pass ✓
    //   iszero(eq(...))     → exceeds bytes16 → revert ✗
    modifier enforceBit128(string memory _nspace) {
        assembly {
            let nspace := mload(add(_nspace, 0x20))
            let cleaned := and(nspace, not(0xffffffffffffffffffffffffffffffff))
            if iszero(eq(cleaned, nspace)) {
                revert(0x00, 0x00)
            }
        }
        _;
    }
}
