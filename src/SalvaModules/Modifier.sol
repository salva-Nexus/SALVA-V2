// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract Modifier {
    /**
     * @dev Phishing protection modifier. Reverts if the string argument
     *      contains any uppercase ASCII letter (A–Z).
     */
    //  WHY THIS EXISTS
    //  ───────────────
    //  Without this check, an attacker can register "@Salva" when "@salva"
    //  already exists. At the byte level these are DIFFERENT identifiers:
    //
    //    "@salva" → 0x4073616c76610000...   's' = 0x73
    //    "@Salva" → 0x4053616c76610000...   'S' = 0x53  ← different byte!
    //
    //  A user sending to "charles@Salva" instead of "charles@salva" would
    //  unknowingly send funds to an attacker's wallet. This modifier is the
    //  on-chain backstop — it cannot be bypassed regardless of what the
    //  caller sends, even if they bypass the UI entirely.
    //
    //  WHY REVERT INSTEAD OF CONVERTING TO LOWERCASE?
    //  ────────────────────────────────────────────────
    //  Converting costs gas on every single call. The UI normalises input
    //  before submission anyway — honest callers never send uppercase.
    //  Rejecting is cheaper and simpler than silently converting.
    //
    //  ┌────────────────────────────────────────────────────────────┐
    //  │                  THE BIT 5 TRICK                           │
    //  │                                                            │
    //  │  In ASCII, lowercase = uppercase + 0x20.                   │
    //  │  Bit 5 is the ONLY bit that differs between the two:       │
    //  │                                                            │
    //  │   char   binary        hex                                 │
    //  │   'A'  = 0100 0001  = 0x41   bit 5 → 0                     │
    //  │   'a'  = 0110 0001  = 0x61   bit 5 → 1                     │
    //  │              ▲                                             │
    //  │            bit 5 (= 0x20)                                  │
    //  │                                                            │
    //  │   'S'  = 0101 0011  = 0x53   bit 5 → 0                     │
    //  │   's'  = 0111 0011  = 0x73   bit 5 → 1                     │
    //  │                                                            │
    //  │  Therefore: AND(byte, 0x20)                                │
    //  │    → 0x20  if byte is lowercase letter  (bit 5 set)        │
    //  │    → 0x00  if byte is uppercase letter  (bit 5 NOT set)    │
    //  │    → 0x00  if byte is digit 0–9         (bit 5 not set)    │
    //  │  This naturally rejects digits too — names are             │
    //  │  letters only by design. No extra check needed.            │
    //  └────────────────────────────────────────────────────────────┘
    //
    //  MEMORY LAYOUT ASSUMPTION
    //  ─────────────────────────
    //  Solidity places a `string memory` argument at fixed slots:
    //
    //    0x00–0x3f  scratch space        (reserved by Solidity)
    //    0x40       free memory pointer  (reserved by Solidity)
    //    0x60       zero slot            (reserved by Solidity)
    //    0x80  ──►  string LENGTH        ← mload(0x80)
    //    0xa0  ──►  string DATA (32b)    ← mload(0xa0)
    //
    //  We read directly from 0x80 and 0xa0 — no extra mload via pointer.
    //
    //  HOW THE WORD-LEVEL CHECK WORKS (step by step)
    //  ───────────────────────────────────────────────
    //  Example: identifier = "@salva"  (len = 6)
    //
    //  Step 1 — raw bytes loaded from 0xa0
    //
    //    identifier = 0x4073616c766100000000000000000000000000000000000000000000000000
    //                  @  s  a  l  v  a  ├──────── 26 zero-padded bytes ──────────────┤
    //
    //  Step 2 — shift mask right by (len × 8) bits
    //           len=6, shift = 48 bits (₀x3₀)
    //
    //    mask         = 0x2020202020202020202020202020202020202020202020202020202020202020
    //    shr(48, mask)= 0x0000000000002020202020202020202020202020202020202020202020202020
    //                   ├─ 6 zero bytes ─┤├──── 26 bytes of 0x20 (covers trailing zeros) ┤
    //
    //  Step 3 — OR shifted mask into identifier
    //           Trailing zero bytes become 0x20 — they pass the AND check
    //           automatically (zero-padding is not a letter).
    //
    //    OR(
    //      0x4073616c766100000000000000000000000000000000000000000000000000,
    //      0x0000000000002020202020202020202020202020202020202020202020202020
    //    )
    //    nameWithMask = 0x4073616c76612020202020202020202020202020202020202020202020202020
    //                    @  s  a  l  v  a  ├────── trailing bytes all 0x20 ──────────────┤
    //
    //  Step 4 — AND with finalMask to isolate bit 5 of every byte
    //
    //    initializeRegistry uses finalMask with 0x00 in byte 0 to skip '@':
    //    finalMask = 0x0020202020202020202020202020202020202020202020202020202020202020
    //                  ▲
    //                 0x00 — '@' (0x40) has bit 5 = 0, so we must skip it
    //                 or '@' would always cause a revert.
    //
    //    AND(
    //      0x4073616c76612020202020202020202020202020202020202020202020202020,
    //      0x0020202020202020202020202020202020202020202020202020202020202020
    //    )
    //    cleaned = 0x0020202020202020202020202020202020202020202020202020202020202020
    //
    //  Step 5 — cleaned must equal finalMask exactly
    //
    //    cleaned == finalMask → all letters lowercase → PASS ✓
    //    cleaned != finalMask → uppercase found       → REVERT ✗
    //
    //  FAILURE EXAMPLE — "@Salva" (uppercase S = 0x53, bit 5 = 0)
    //  ─────────────────────────────────────────────────────────────
    //    identifier   = 0x4053616c766100...
    //    nameWithMask = 0x4053616c76612020...
    //
    //    AND with finalMask:
    //    cleaned = 0x0000202020202020...  ← byte 1 is 0x00, not 0x20
    //
    //    cleaned ≠ finalMask → revert ✓ attacker blocked.
    //
    //  WHY TWO SWITCH CASES?
    //  ──────────────────────
    //  initializeRegistry → identifier starts with '@' → skip byte 0
    //                     → finalMask = 0x0020...20
    //
    //  linkNameAlias      → name has no '@' prefix → check all bytes
    //                     → finalMask = 0x2020...20
    //
    //  The selector of initializeRegistry(string) = 0xbe5b3436.
    //  We read it from calldataload(0x00) >> 224 (shift right 224 bits
    //  to move the leftmost 4 bytes into the low bits).

    modifier phishingProof() {
        assembly {
            let len := mload(0x80)
            let identifier := mload(0xa0)
            let mask := 0x2020202020202020202020202020202020202020202020202020202020202020

            let selector := eq(shr(0xe0, calldataload(0x00)), 0xe9eda5eb)

            switch selector

            // ── CASE 1: initializeRegistry(string) ──────────────────────────
            // finalMask byte 0 = 0x00 to skip the '@' prefix.
            case 0x01 {
                let finalMask := 0x0020202020202020202020202020202020202020202020202020202020202020
                let nameWithMask := or(identifier, shr(mul(len, 0x08), mask))
                let cleaned := and(nameWithMask, finalMask)
                if iszero(eq(cleaned, finalMask)) {
                    revert(0x00, 0x00)
                }
            }

            // ── DEFAULT: linkNameAlias(string,address) ───────────────────────
            // No '@' prefix — check all bytes with the full mask.
            default {
                let nameWithMask := or(identifier, shr(mul(len, 0x08), mask))
                let cleaned := and(nameWithMask, mask)
                if iszero(eq(cleaned, mask)) {
                    revert(0x00, 0x00)
                }
            }
        }
        _;
    }

    modifier onlyMultiSig(address _multiSig) {
        if (msg.sender != _multiSig) revert();
        _;
    }
}
