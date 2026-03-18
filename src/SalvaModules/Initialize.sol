// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract Initialize is BaseSingleton {
    /**
     * @notice Registers a new registry contract with a unique namespace identifier.
     * @dev    Called once per registry in its constructor. Reverts on re-registration
     *         or identifier collision.
     */
    //  WHAT IS A NAMESPACE?
    //  ─────────────────────
    //  namespace = identifier OR caller address, packed into one bytes32 slot.
    //  This works because identifier ≤ 12 bytes (left side) and address = 20 bytes
    //  (right side) — they never overlap.
    //
    //    identifier = 0x4073616c76610000000000000000000000000000000000000000000000000000
    //                 "@salva" (6 bytes)    ├────────── 26 zero bytes ────────────────┤
    //
    //    caller     = 0x000000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c856
    //                 ├──── 12 zero bytes ──────────────┤├───── address (20 bytes) ────┤
    //
    //    namespace  = 0x4073616c7661000000000000a208e28AA883dDB5A0Eb52d04D473E589054c856
    //                 "@salva"              ├────── caller address (20 bytes) ──────────┤
    //
    //  VALIDATION ORDER
    //  ─────────────────
    //  [A] phishingProof modifier  — no uppercase in identifier
    //  [B] nonReentrant modifier   — no re-entrant calls
    //  [C] double-init check       — caller has not registered before
    // [D+E] prefix + length check — must start with '@' AND fit ≤ 12 bytes
    //  [F] identifier collision    — identifier not already taken
    //
    //  STORAGE SLOT DERIVATION — OR-based + salt offset
    //  ──────────────────────────────────────────────────
    //  Storage pointers are derived without keccak256 on the key itself:
    //
    //    nSpaceSlot      = add(or(shl(0x08, caller()), _registryNamespace.slot), _NSPACE_SALT)
    //    _identifierSlot = add(or(_identifier, _registryIdentifier.slot),        _IDENTIFIER_SALT)
    //
    //  STEP 1 — OR-pack (see STORAGE LAYOUT above for full diagram)
    //  STEP 2 — ADD salt to scatter the pointer into unpredictable 2²⁵⁶ space:
    //
    //    nSpaceSlot example:
    //    OR result    = 0x0000000000000000000000a208e28AA883dDB5A0Eb52d04D473E589054c85601
    //    _NSPACE_SALT = 0x0e69ca985d281c235813eed420b4fabc37bf87db9c2fbe28384506a2c9e52e46
    //    final ptr    = 0x0e69ca985d281c235813eed5c2d2e347bba05b5e6d55a3c9199955f6f7b74a47
    //                    ├──────────────── scattered 32-byte storage pointer ─────────────┤
    //
    //  IDENTIFIER SOURCE — mload(0xa0)
    //  ──────────────────────────────────
    //  The string identifier is ABI-encoded in calldata. Solidity decodes it and
    //  writes the first 32 bytes of string content to memory at 0xa0 before the
    //  assembly block executes:
    //
    //    calldata layout (string memory identifier):
    //    ┌──────────────────────────────────────────────────────────────────┐
    //    │  0x00  │  4-byte selector                                        │
    //    ├──────────────────────────────────────────────────────────────────┤
    //    │  0x04  │  offset to string data (= 0x20)                        │
    //    ├──────────────────────────────────────────────────────────────────┤
    //    │  0x24  │  string length (bytes)                                  │
    //    ├──────────────────────────────────────────────────────────────────┤
    //    │  0x44  │  string content (left-aligned, zero-padded to 32 bytes) │
    //    └──────────────────────────────────────────────────────────────────┘
    //
    //    Solidity copies the decoded string into memory. After the free memory
    //    pointer and ABI bookkeeping words, the first 32 bytes of string content
    //    land at 0xa0:
    //
    //    memory at 0xa0:
    //    0x4073616c76610000000000000000000000000000000000000000000000000000
    //      "@salva" (6 bytes) ├──────────── 26 zero bytes ──────────────────┤
    //
    //    mload(0xa0) → _identifier  (no pointer arithmetic needed)
    //
    //  CHECK D — PREFIX: first byte must be '@' (0x40)
    //  ─────────────────────────────────────────────────
    //    _identifier = 0x40 73 61 6c 76 61 00 ... 00
    //                   ▲ first byte
    //
    //    shr(0xf8, _identifier) → shift right 248 bits
    //    leaves only the first byte in the lowest position:
    //    result = 0x0000...0040
    //    eq(result, 0x40) = 1 ✓
    //
    //  CHECK E — LENGTH: identifier must fit in ≤ 12 bytes
    //  ──────────────────────────────────────────────────────
    //    mask = shl(0xa0, 0xffffffffffffffffffffffff)
    //         = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000
    //             ├─ left 12 bytes 0xff ─┤├──────── right 20 bytes 0x00 ─────────┤
    //
    //    _clean = AND(_identifier, mask)
    //
    //    identifier fits ≤ 12 bytes:  _clean == _identifier → pass ✓
    //    identifier exceeds 12 bytes: _clean != _identifier → revert ✗
    //
    //  COMBINED CHECK D + E
    //  ──────────────────────
    //    ┌──────────┬──────────┬──────────┬─────────┐
    //    │ prefix=@ │ fits 12b │ and()    │ outcome │
    //    ├──────────┼──────────┼──────────┼─────────┤
    //    │    1     │    1     │    1     │  pass   │
    //    │    1     │    0     │    0     │  revert │
    //    │    0     │    1     │    0     │  revert │
    //    │    0     │    0     │    0     │  revert │
    //    └──────────┴──────────┴──────────┴─────────┘

    function initializeRegistry(address registry, string memory identifier)
        external
        onlyMultiSig(_MULTISIG)
        phishingProof
    {
        assembly {
            // ── CHECK C: double-init guard ───────────────────────────────────
            // Storage pointer: add(or(shl(0x08, caller()), _registryNamespace.slot), _NSPACE_SALT)
            // Caller shifted left 1 byte; slot fills lowest byte; salt scatters pointer.
            // No keccak needed — key and slot never overlap, salt eliminates collision anxiety.

            let nSpaceSlot := add(or(shl(0x08, registry), _registryNamespace.slot), _NSPACE_SALT)
            if sload(nSpaceSlot) {
                revert(0x00, 0x00)
            }

            // Load identifier bytes.
            // Solidity ABI-decodes the string and writes its first 32 content
            // bytes to 0xa0 before entering assembly. No pointer arithmetic needed.
            let _identifier := mload(add(identifier, 0x20))

            // ── CHECK D: prefix must be '@' (0x40) ───────────────────────────
            let _prefix := shr(0xf8, _identifier)

            // ── CHECK E: identifier must fit in 12 bytes ─────────────────────
            let _clean := and(_identifier, shl(0xa0, 0xffffffffffffffffffffffff))

            // Compute _registryIdentifier[identifier] storage slot.
            // OR-packs identifier into upper bytes; mapping slot sits in lowest byte;
            // salt offsets the pointer into scattered 2²⁵⁶ space.
            let _identifierSlot := add(or(_identifier, _registryIdentifier.slot), _IDENTIFIER_SALT)

            // ── COMBINED CHECK D + E ─────────────────────────────────────────
            if iszero(and(eq(_prefix, 0x40), eq(_identifier, _clean))) {
                revert(0x00, 0x00)
            }

            // ── CHECK F: identifier collision guard ───────────────────────────
            if sload(_identifierSlot) {
                revert(0x00, 0x00)
            }

            // ── WRITE ─────────────────────────────────────────────────────────
            // namespace = identifier | caller (no overlap — guaranteed by check E)
            let nSpace := or(_identifier, caller())
            sstore(nSpaceSlot, nSpace)
            sstore(_identifierSlot, 0x01)
        }
    }
}
