// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Modifier } from "@Modifier/Modifier.sol";

/**
 * @title NameLib
 * @author cboi@Salva
 * @notice Core library for alias normalization, storage-key generation, and
 *         ownership-indexed storage writes.
 * @dev All hot paths use inline assembly for predictable gas costs and direct
 *      memory control.
 *
 *      Public surface (consumed by `LinkName`, `UnlinkName`, and `Resolve`):
 *        · `_computeNameHash`       — keccak256 slot generation via namespace welding.
 *        · `_normalizeAndValidate`  — anti-phishing flip + character gating.
 *        · `_checkCollision`        — duplicate-registration guard.
 *        · `_checkCaller`           — ownership verification for unlink.
 *        · `_performLinkToWallet`   — forward + ownership storage write.
 *        · `_performUnlink`         — storage zeroing + ownership cleanup.
 */
abstract contract NameLib is Modifier {
    // ─────────────────────────────────────────────────────────────────────────
    // STORAGE-KEY GENERATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Produces a unique keccak256 storage pointer by welding the
     *         normalized name bytes and the registry's namespace handle.
     *
     * @dev Memory layout after the weld:
     *        [ 0x00 .. nameLength-1      ] — normalized name bytes (written by caller)
     *        [ nameLength .. fullLength-1 ] — namespace handle     (written here)
     *      `keccak256` is then taken over the full `fullLength` byte window.
     *
     *      The name bytes at `0x00` are expected to have been written by
     *      `_normalizeAndValidate` before this function is called.
     *
     * @param namespaceHandle  The 31-byte namespace handle (e.g. `[at]salva\x00...`).
     * @param nameLength       Byte length of the normalized name segment.
     * @param fullLength       Total bytes to hash: `nameLength + namespaceLength`.
     * @param skipCollisionCheck  Pass `0` to run a collision guard; any other value skips it.
     * @return nameHash        The welded keccak256 storage key.
     */
    function _computeNameHash(
        bytes31 namespaceHandle,
        uint256 nameLength,
        uint256 fullLength,
        uint256 skipCollisionCheck
    ) internal view returns (bytes32 nameHash) {
        assembly ("memory-safe") {
            // Append namespace immediately after the name bytes already in memory.
            // Creates a contiguous buffer: [ name_data ][ namespace_handle ]
            mstore(add(0x00, nameLength), namespaceHandle)

            // Hash the full buffer to produce the unique storage key.
            nameHash := keccak256(0x00, fullLength)
        }

        if (skipCollisionCheck == 0) {
            _checkCollision(nameHash);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // NAME NORMALIZATION + VALIDATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Normalizes an alias and validates its character set, writing the
     *         canonical form into memory at `0x00` for subsequent hashing.
     *
     * @dev Anti-phishing guarantee:
     *        Aliases containing exactly one underscore are split into two segments
     *        and reconstructed in ascending lexicographic order. This means
     *        `"charles_okoronkwo"` and `"okoronkwo_charles"` produce identical memory
     *        output and therefore the same storage key — preventing look-alike squatting.
     *
     *      Namespace-aware termination:
     *        If a namespace-prefix byte (`0x40` / `[at]`) is detected as the next character
     *        the loop terminates immediately and only the local-name segment is processed.
     *        This makes the function safe to call with full handles from view or unlink paths.
     *
     *      Character rules enforced when `validationMode == 0` (link write path):
     *        · a–z      (0x61–0x7a)
     *        · 2–9      (0x32–0x39)
     *        · `_`      (0x5f) — maximum one occurrence
     *        · digits 0, 1 and all uppercase letters are rejected
     *
     *      When `validationMode == 1` (unlink or view path) character validation is
     *      skipped so the canonical key can be reconstructed without re-gating.
     *
     * @param length          Byte length of `nameBytes` (or the full handle).
     * @param nameBytes       Raw `bytes32` word loaded from calldata.
     * @param validationMode  `0` = strict write-path validation; `1` = read/unlink path.
     * @return processedLength  Byte length of the canonical name written to memory.
     */
    function _normalizeAndValidate(uint256 length, bytes32 nameBytes, uint8 validationMode)
        internal
        pure
        returns (uint256 processedLength)
    {
        if (length > 0x20) {
            revert Errors__MaxNameLengthExceeded();
        }

        uint8 underscoreCount;
        bytes32 firstSegment;
        uint256 firstSegmentLength;
        bytes32 secondSegment;
        uint256 secondSegmentLength;
        bool isSplit;
        uint256 cursor;

        for (uint256 i = 0; i < length;) {
            bytes1 char = nameBytes[i];
            bytes1 nextChar = (i + 1 < 0x20) ? nameBytes[i + 1] : bytes1(0);
            uint256 lastIdx = length - 1;

            // ── STEP 1 · CHARACTER VALIDATION (write path only)
            // ───────────
            if (validationMode == 0) {
                if (
                    !(char >= 0x61 && char <= 0x7a) && !(char >= 0x32 && char <= 0x39)
                        && char != 0x5f
                ) {
                    revert Errors__InvalidCharacter();
                }
            }

            // ── STEP 2 · SEGMENT CAPTURE
            // ──────────────────────────────────
            if (!isSplit) {
                if (char != 0x5f) {
                    assembly ("memory-safe") {
                        switch eq(cursor, 0x00)
                        case 0x01 {
                            mstore(add(0x00, cursor), char)
                        }
                        default {
                            mstore8(add(0x00, cursor), shr(0xf8, char))
                        }
                        cursor := add(cursor, 0x01)
                    }
                }

                if (char == 0x5f || i == lastIdx || nextChar == 0x40) {
                    assembly ("memory-safe") {
                        firstSegmentLength := cursor
                        firstSegment := mload(0x00)
                        cursor := 0x00
                    }

                    if (nextChar > 0x00 && nextChar != 0x40 && char != 0x5f) {
                        revert Errors__InvalidLength();
                    }
                }
                if (nextChar == 0x40) {
                    i = lastIdx;
                }
            } else {
                assembly ("memory-safe") {
                    switch eq(cursor, 0x00)
                    case 0x01 {
                        mstore(add(0x00, cursor), char)
                    }
                    default {
                        mstore8(add(0x00, cursor), shr(0xf8, char))
                    }
                    cursor := add(cursor, 0x01)
                }

                if (i == lastIdx || nextChar == 0x40) {
                    i = lastIdx;

                    assembly ("memory-safe") {
                        secondSegmentLength := cursor
                        secondSegment := mload(0x00)
                    }

                    if (nextChar > 0x00 && nextChar != 0x40) {
                        revert Errors__InvalidLength();
                    }
                }
            }

            if (char == 0x5f) {
                unchecked {
                    underscoreCount++;
                }
                if (underscoreCount > 1) revert Errors__MaxOneUnderscoreAllowed();
                isSplit = true;
            }
            unchecked {
                i++;
            }
        }

        if (underscoreCount > 0) {
            processedLength = _normalizeSegments(
                firstSegment, firstSegmentLength, secondSegment, secondSegmentLength
            );
        } else {
            processedLength = secondSegmentLength == 0
                ? firstSegmentLength
                : firstSegmentLength + secondSegmentLength;
        }
    }

    /**
     * @notice Reconstructs an underscore-split alias in ascending lexicographic order.
     * @dev Both segments must be non-empty. The larger segment is placed first,
     *      the underscore separator inserted, then the smaller segment appended.
     *      This guarantees a canonical, order-independent storage key.
     *
     * @param firstSegment        Raw bytes32 of the first alias segment.
     * @param firstSegmentLength  Byte length of the first segment.
     * @param secondSegment       Raw bytes32 of the second alias segment.
     * @param secondSegmentLength Byte length of the second segment.
     * @return processedLength    Total byte length of the reconstructed canonical name.
     */
    function _normalizeSegments(
        bytes32 firstSegment,
        uint256 firstSegmentLength,
        bytes32 secondSegment,
        uint256 secondSegmentLength
    ) internal pure returns (uint256 processedLength) {
        if (firstSegmentLength == 0 || secondSegmentLength == 0) {
            revert Errors__InvalidSubNameFormat();
        }

        bytes32 upperSegment = firstSegment > secondSegment ? firstSegment : secondSegment;
        bytes32 lowerSegment = firstSegment < secondSegment ? firstSegment : secondSegment;
        uint256 upperLength =
            firstSegment > secondSegment ? firstSegmentLength : secondSegmentLength;

        assembly ("memory-safe") {
            if lt(secondSegment, firstSegment) {
                mstore(0x00, upperSegment)
            }
            mstore8(add(0x00, upperLength), 0x5f)
            mstore(add(add(0x00, upperLength), 0x01), lowerSegment)
        }

        processedLength = firstSegmentLength + secondSegmentLength + 1;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // STORAGE ENGINE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Reverts if `nameHash` already maps to a non-zero value in storage.
     * @dev Prevents overwriting an existing alias registration.
     * @param nameHash The welded keccak256 key to inspect.
     */
    function _checkCollision(bytes32 nameHash) internal view {
        bytes32 storedValue;
        assembly {
            storedValue := sload(nameHash)
        }
        if (storedValue != bytes32(0)) revert Errors__NameTaken();
    }

    /**
     * @notice Verifies that `sender` is the address that originally registered `nameHash`,
     *         protecting against unauthorised unlinks.
     * @dev The ownership index is stored at:
     *        slot = keccak256(nameHash ++ sender) → nameHash
     *
     * @param sender    The EOA attempting the unlink operation.
     * @param nameHash  The welded storage key of the alias to unlink.
     * @return ownershipKey  The ownership-index slot key for use in `_performUnlink`.
     */
    function _checkCaller(address sender, bytes32 nameHash)
        internal
        view
        returns (bytes32 ownershipKey)
    {
        assembly ("memory-safe") {
            mstore(0x00, nameHash)
            mstore(0x20, sender)
            ownershipKey := sload(keccak256(0x00, 0x40))
        }
        if (ownershipKey != nameHash) revert Errors__InvalidSender();
    }

    /**
     * @notice Writes the alias-to-wallet binding and the ownership index to storage atomically.
     * @dev Two storage slots are written:
     *        1. `nameHash` → `wallet`                       (forward resolution)
     *        2. keccak256(nameHash ++ sender) → `nameHash`  (ownership index)
     *
     * @param nameHash  The welded keccak256 storage key.
     * @param wallet    The wallet address to bind to the alias.
     * @param sender    The registering user's EOA — used to build the ownership index.
     * @return isLinked `true` on success.
     */
    function _performLinkToWallet(bytes32 nameHash, address wallet, address sender)
        internal
        returns (bool isLinked)
    {
        assembly ("memory-safe") {
            sstore(nameHash, wallet)
            mstore(0x00, nameHash)
            mstore(0x20, sender)
            let ownershipKey := keccak256(0x00, 0x40)
            sstore(ownershipKey, nameHash)
        }
        isLinked = true;
    }

    /**
     * @notice Zeroes both the alias-to-wallet slot and the ownership-index slot.
     * @dev Triggers an EVM gas refund for each cleared storage slot (EIP-3529).
     *
     * @param nameHash     The welded keccak256 key of the alias to remove.
     * @param ownershipKey The ownership-index slot key returned by `_checkCaller`.
     * @return isUnlinked `true` on success.
     */
    function _performUnlink(bytes32 nameHash, bytes32 ownershipKey)
        internal
        returns (bool isUnlinked)
    {
        assembly {
            sstore(nameHash, 0x00)
            sstore(ownershipKey, 0x00)
        }
        isUnlinked = true;
    }
}
