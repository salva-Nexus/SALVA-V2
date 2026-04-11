// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Modifier} from "@Modifier/Modifier.sol";
import {Storage} from "@Storage/Storage.sol";

/**
 * @title NameLib
 * @author cboi@Salva
 * @notice Core library for alias normalization, storage-key generation, and
 * ownership-indexed storage writes.
 * @dev All hot paths use inline assembly for predictable gas costs and direct
 * memory control.
 *
 * Exports (used by LinkName and UnlinkName):
 * - _computeNameHash        : keccak256 slot generation
 * - _normalizeAndValidate   : anti-phishing flip + character gating
 * - _checkCollision         : duplicate-registration guard
 * - _checkCaller            : ownership verification for unlink
 * - _performLinkToWallet    : forward + ownership storage write
 * - _performUnlink          : storage zeroing + ownership cleanup
 */
abstract contract NameLib is Modifier, Storage {
    // ─────────────────────────────────────────────────────────────────────────
    // STORAGE-KEY GENERATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Produces a unique keccak256 storage pointer by welding the
     * normalized name and the registry's namespace handle.
     *
     * @dev Memory layout after the weld:
     * [ 0x00 .. nameLength-1 ] normalized name bytes (written by caller)
     * [ nameLength .. nameLength+15 ] namespace handle (written here)
     * keccak256 is then taken over the full fullLength byte window.
     *
     * The name bytes at 0x00 are expected to have been written by
     * _normalizeAndValidate before this function is called.
     *
     * @param namespace_    The 16-byte namespace handle.
     * @param nameLength    Byte length of the normalized name segment.
     * @param fullLength    Total bytes to hash: nameLength + namespaceLength.
     * @param storageCheck  Pass 0 to run a collision guard; any other value skips it.
     * @return nameHash     The welded keccak256 storage key.
     */
    function _computeNameHash(bytes16 namespace_, uint256 nameLength, uint256 fullLength, uint256 storageCheck)
        internal
        view
        returns (bytes32 nameHash)
    {
        assembly ("memory-safe") {
            // STEP: APPEND NAMESPACE
            // mstore at the offset of nameLength creates a contiguous byte array:
            // [ name_data ][ namespace ]
            mstore(add(0x00, nameLength), namespace_)

            // STEP: GENERATE SLOT KEY
            // we are not following normal hashing with slot.
            // nameHash = keccak256(Memory[0x00 : fullLength])
            nameHash := keccak256(0x00, fullLength)
        }

        if (storageCheck == 0) {
            _checkCollision(nameHash);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // NAME NORMALIZATION + VALIDATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Normalizes an alias and validates its character set, then writes
     * the canonical form into memory at 0x00 for subsequent hashing.
     *
     * @dev Anti-phishing guarantee: aliases that contain exactly one underscore
     * are split into two segments and reconstructed in ascending
     * lexicographic order. This means "charles_okoronkwo" and
     * "okoronkwo_charles" produce identical memory output and therefore
     * the same storage key — preventing look-alike squatting.
     *
     * Namespace-aware termination: if a "namespace prefix" byte (0x40) is detected as the
     * next character, the loop terminates immediately and only the name
     * segment is processed. This makes the function safe to
     * call with full handles from view or unlink paths.
     *
     * Character rules enforced when mark == 0 (link write path):
     * - a–z (0x61–0x7a)
     * - 2–9 (0x32–0x39)
     * - "_" (0x5f) — maximum one occurrence
     * - digits 0, 1 and all uppercase letters are rejected
     *
     * When mark == 1 (unlink or view path) character validation is skipped
     * so the canonical key can be reconstructed without re-gating.
     *
     * @param length         Byte length of nameToBytes (or the full handle).
     * @param nameToBytes    Raw bytes32 word loaded from calldata.
     * @param mark           0 strict write-path validation; 1 read or unlink path.
     * @return pLength       Byte length of the canonical name written to memory.
     */
    function _normalizeAndValidate(uint256 length, bytes32 nameToBytes, uint8 mark)
        internal
        pure
        returns (uint256 pLength)
    {
        if (length > 0x20) {
            revert Errors__Max_Name_Length_Exceeded();
        }

        uint8 underscoreCount;
        bytes32 firstPart;
        uint256 firstLength;
        bytes32 secondPart;
        uint256 secondLength;
        bool isSplit;
        uint256 cursor;

        for (uint256 i = 0; i < length;) {
            bytes1 char = nameToBytes[i];
            bytes1 next = nameToBytes[i + 1];
            uint256 loopLen = length - 1;

            // ─────────────────────────────────────────────────────────────────
            // STEP 1 — CHARACTER VALIDATION (a-z, 2-9, _)
            // ─────────────────────────────────────────────────────────────────
            if (mark == 0) {
                if (!(char >= 0x61 && char <= 0x7a) && !(char >= 0x32 && char <= 0x39) && char != 0x5f) {
                    revert Errors__Invalid_Character();
                }
            }

            // ─────────────────────────────────────────────────────────────────
            // STEP 2 — SEGMENT CAPTURE (Memory Buffering)
            // ─────────────────────────────────────────────────────────────────
            if (!isSplit) {
                if (char != 0x5f) {
                    assembly ("memory-safe") {
                        mstore(add(0x00, cursor), char)
                        cursor := add(cursor, 0x01)
                    }
                }

                if (char == 0x5f || i == loopLen || next == 0x40) {
                    assembly ("memory-safe") {
                        firstLength := cursor
                        firstPart := shr(sub(0x100, mul(firstLength, 0x08)), mload(0x00))
                        cursor := 0x00
                    }

                    if (next > 0x00 && next != 0x40 && char != 0x5f) {
                        revert Errors__Invalid_Length();
                    }
                }
                if (next == 0x40) {
                    i = loopLen;
                }
            } else {
                assembly ("memory-safe") {
                    mstore(add(0x00, cursor), char)
                    cursor := add(cursor, 0x01)
                }

                if (i == loopLen || next == 0x40) {
                    i = loopLen;

                    assembly ("memory-safe") {
                        secondLength := cursor
                        secondPart := shr(sub(0x100, mul(secondLength, 0x08)), mload(0x00))
                    }

                    if (next > 0x00 && next != 0x40) {
                        revert Errors__Invalid_Length();
                    }
                }
            }

            if (char == 0x5f) {
                isSplit = true;
                unchecked {
                    underscoreCount++;
                }
                if (underscoreCount > 1) revert Errors__Max_One_Underscore_Allowed();
            }
            unchecked {
                i++;
            }
        }

        if (underscoreCount > 0) {
            pLength = _normalize(firstPart, firstLength, secondPart, secondLength);
        } else {
            pLength = secondLength == 0 ? firstLength : firstLength + secondLength;
        }
    }

    /**
     * @dev Helper to perform alphabetical reconstruction of split names.
     */
    function _normalize(bytes32 firstPart, uint256 fLength, bytes32 secondPart, uint256 sLength)
        internal
        pure
        returns (uint256 pLength)
    {
        bytes32 upper = firstPart > secondPart ? firstPart : secondPart;
        bytes32 lower = firstPart < secondPart ? firstPart : secondPart;
        uint256 bigLen = firstPart > secondPart ? fLength : sLength;
        uint256 smlLen = firstPart > secondPart ? sLength : fLength;

        assembly ("memory-safe") {
            mstore(0x00, shl(sub(0x100, mul(bigLen, 0x08)), upper))
            mstore8(add(0x00, bigLen), 0x5f)
            mstore(add(add(0x00, bigLen), 0x01), shl(sub(0x100, mul(smlLen, 0x08)), lower))
        }
        pLength = fLength + sLength + 1;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // STORAGE ENGINE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Reverts if nameHash already maps to a non-zero value in storage.
     * @dev Prevents overwriting an existing alias registration.
     * @param nameHash The welded keccak256 key to inspect.
     */
    function _checkCollision(bytes32 nameHash) internal view {
        bytes32 storedValue;
        assembly {
            storedValue := sload(nameHash)
        }
        if (storedValue != bytes32(0)) revert Errors__Taken();
    }

    /**
     * @notice Verifies that sender is the address that originally registered
     * nameHash, protecting against unauthorized unlinks.
     * @dev The ownership index is stored as:
     * slot = keccak256(nameHash ++ sender) -> nameHash
     * @param _sender   The EOA attempting the unlink operation.
     * @param nameHash  The welded storage key of the alias to unlink.
     * @return _senderHash  The ownership-index slot key.
     */
    function _checkCaller(address _sender, bytes32 nameHash) internal view returns (bytes32 _senderHash) {
        assembly ("memory-safe") {
            mstore(0x00, nameHash)
            mstore(0x20, _sender)
            _senderHash := sload(keccak256(0x00, 0x40))
        }
        if (_senderHash != nameHash) revert Errors__Invalid_Sender();
    }

    /**
     * @notice Writes the alias-to-wallet binding and the ownership index to storage.
     * @dev Two storage slots are written atomically.
     * @param nameHash  The welded keccak256 storage key.
     * @param _wallet   The wallet address to bind to the alias.
     * @param _sender   The registering user's EOA (used to build the ownership index).
     * @return _isLinked true on success.
     */
    function _performLinkToWallet(bytes32 nameHash, address _wallet, address _sender)
        internal
        returns (bool _isLinked)
    {
        assembly ("memory-safe") {
            sstore(nameHash, _wallet)
            mstore(0x00, nameHash)
            mstore(0x20, _sender)
            let senderHash := keccak256(0x00, 0x40)
            sstore(senderHash, nameHash)
        }
        _isLinked = true;
    }

    /**
     * @notice Zeroes both the alias-to-wallet slot and the ownership-index slot.
     * @dev Triggers an EVM gas refund for each cleared storage slot.
     * @param nameHash    The welded keccak256 key of the alias to remove.
     * @param senderHash  The ownership-index slot key returned by _checkCaller.
     * @return _isUnLinked true on success.
     */
    function _performUnlink(bytes32 nameHash, bytes32 senderHash) internal returns (bool _isUnLinked) {
        assembly {
            sstore(nameHash, 0x00)
            sstore(senderHash, 0x00)
        }
        _isUnLinked = true;
    }
}
