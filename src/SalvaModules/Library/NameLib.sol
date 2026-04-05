// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Modifier} from "@Modifier/Modifier.sol";
import {Storage} from "@Storage/Storage.sol";

/**
 * @title NameLib
 * @notice Internal library for name normalization and cryptographic hashing.
 * @dev High-performance assembly for name-welding and anti-phishing normalization.
 * This version is namespace-aware; it identifies the namespace prefix to isolate the alias
 * from the namespace suffix during processing.
 */
abstract contract NameLib is Modifier, Storage {
    // ─────────────────────────────────────────────────────────────────────────
    // FUNCTION 1 — NAME HASHING (Storage Slot Generation)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Generates a unique keccak256 pointer by welding the name and namespace.
     * @dev Uses assembly to mstore the namespace immediately after name bytes in memory.
     * @param namespace The 16-byte namespace identifier.
     * @param nameLength Length of the normalized name segment.
     * @param fullLength Total length to hash (normalized name + namespace).
     * @param storageCheck If 0, performs a collision check on the resulting hash.
     */
    function _computeNameHash(bytes16 namespace, uint256 nameLength, uint256 fullLength, uint256 storageCheck)
        internal
        view
        returns (bytes32 nameHash)
    {
        assembly {
            // STEP: APPEND NAMESPACE
            // mstore at the offset of nameLength creates a contiguous byte array:
            // [ name_data ][ namespace ]
            mstore(add(0x00, nameLength), namespace)

            // STEP: GENERATE SLOT KEY
            // we are not following normal hashing with slot.
            // nameHash = keccak256(Memory[0x00 : fullLength])
            // fullLength = name + namespace
            nameHash := keccak256(0x00, fullLength)
        }

        if (storageCheck == 0) {
            _checkCollision(nameHash);
        }
    }

    /**
     * @notice Normalizes split names and strips namespaces for deterministic storage.
     * @dev Handles "charles_okoronkwo" vs "okoronkwo_charles" by sorting segments.
     * It is now robust enough to handle full handles by terminating
     * segment capture when the namespace prefix (0x40) character is detected.
     * @param length Input length of the raw name or full handle.
     * @param nameToBytes The raw bytes32 representation of the name.
     * @param mark Flag to toggle strict character validation (0 for link, 1 for view/unlink).
     * @return processedLength The length of the final normalized name segment.
     */
    function _normalizeAndValidate(uint256 length, bytes32 nameToBytes, uint8 mark)
        internal
        pure
        returns (uint256 processedLength)
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
            bytes1 loopLen = length - 1;

            // ─────────────────────────────────────────────────────────────────
            // STEP 1 — CHARACTER VALIDATION (a-z, 2-9, _)
            // ─────────────────────────────────────────────────────────────────
            if (mark == 0) {
                // if mark == 0?? -> 0 is only write function (link)
                // 1 is unlink and view function, so we skip this check
                if (!(char >= 0x61 && char <= 0x7a) && !(char >= 0x32 && char <= 0x39) && char != 0x5f) {
                    revert Errors__Invalid_Character();
                }
            }

            // ─────────────────────────────────────────────────────────────────
            // STEP 2 — SEGMENT CAPTURE (Memory Buffering)
            // ─────────────────────────────────────────────────────────────────
            if (!isSplit) {
                if (char != 0x5f) {
                    assembly {
                        mstore(add(0x00, cursor), char)
                        cursor := add(cursor, 0x01)
                    }
                }
                // Finalize Segment 1 if end of string or namespace @ symbol detected
                // Cus this function is also called my a view function that take full name(with namespace)
                // We stop the loop so a not to proceed to adding @namespace to the actual name
                if (char == 0x5f || i == loopLen || next == 0x40) {
                    assembly {
                        firstLength := cursor
                        // Extraction: Load segment and shift to high bits for 'upper/lower' check
                        firstPart := shr(sub(0x100, mul(firstLength, 0x08)), mload(0x00))
                        cursor := 0x00
                    }
                }
                if (next == 0x40) {
                    i = loopLen;

                    // New: calldata Length Manipulation Check
                    // Incase the wrong length is passed in raw calldata
                    // We also check if not equal to '@', incase this is being called by a view function
                    // or unlink function, so this doesn't revert
                    // This is robust enough that even if you pass charles@salva in the link function
                    // It will stop the loop right before '@' and use only the name
                    if (next > 0x00 && next != 0x40) {
                        revert Errors__Invalid_Length();
                    }
                }
            } else {
                assembly {
                    mstore(add(0x00, cursor), char)
                    cursor := add(cursor, 0x01)
                }

                // Finalize Segment 1 if end of string or namespace @ symbol detected
                // Cus this function is also called my a view function that take full name(with namespace)
                // We stop the loop so a not to proceed to adding @namespace to the actual name
                if (i == loopLen || next == 0x40) {
                    // This is like a forward, makes i == length, so that i < length will be false and stop the loop
                    i = loopLen;

                    if (next > 0x00 && next != 0x40) {
                        revert Errors__Invalid_Length();
                    }

                    assembly {
                        secondLength := cursor
                        // Extraction: Load segment and shift to high bits for 'upper/lower' check
                        secondPart := shr(sub(0x100, mul(secondLength, 0x08)), mload(0x00))
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

        // ─────────────────────────────────────────────────────────────────
        // STEP 3 — ALPHABETICAL RECONSTRUCTION
        // ─────────────────────────────────────────────────────────────────
        if (underscoreCount > 0) {
            // Compare shifted bytes32 parts (dictionary order)
            bytes32 upper = firstPart > secondPart ? firstPart : secondPart;
            bytes32 lower = firstPart < secondPart ? firstPart : secondPart;
            uint256 bigLen = firstPart > secondPart ? firstLength : secondLength;
            uint256 smlLen = firstPart > secondPart ? secondLength : firstLength;

            assembly {
                // MEMORY REBUILD:
                // 1. Store Upper Part (Left Aligned)
                mstore(0x00, shl(sub(0x100, mul(bigLen, 0x08)), upper))
                // 2. Inject Underscore (0x5f) at offset bigLen
                mstore8(add(0x00, bigLen), 0x5f)
                // 3. Store Lower Part (Left Aligned) immediately after
                mstore(add(add(0x00, bigLen), 0x01), shl(sub(0x100, mul(smlLen, 0x08)), lower))
            }
            processedLength = firstLength + secondLength + 1;
        } else {
            processedLength = secondLength == 0 ? firstLength : firstLength + secondLength;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — STORAGE ENGINE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Internal check to prevent overwriting existing name records.
     */
    function _checkCollision(bytes32 nameHash) internal view {
        bytes32 storedValue;
        assembly {
            storedValue := sload(nameHash) // Check if slot is occupied
        }
        if (storedValue != bytes32(0)) revert Errors__Taken();
    }

    // if the hash stored for this caller, is not the same as the nameHash
    // Revert - name doesn't belong to the caller
    // protects against unlinking another person name
    function _checkCaller(address _sender, bytes32 nameHash) internal view returns (bytes32 _senderHash) {
        assembly {
            mstore(0x00, nameHash)
            mstore(0x20, _sender)
            _senderHash := sload(keccak256(0x00, 0x40))
        }
        if (_senderHash != nameHash) revert Errors__Invalid_Sender();
    }

    /**
     * @dev Maps a name hash to a wallet address in storage.
     */
    function _performLinkToWallet(bytes32 nameHash, address _wallet, address _sender)
        internal
        returns (bool _isLinked)
    {
        assembly {
            sstore(nameHash, _wallet) // Map Hash -> Address
            mstore(0x00, nameHash)
            mstore(0x20, _sender)
            let senderHash := keccak256(0x00, 0x40)
            sstore(senderHash, nameHash)
        }
        _isLinked = true;
    }

    /**
     * @dev Maps a name hash to a numeric value in storage.
     */
    function _performLinkToNumber(bytes32 nameHash, uint256 _number, address _sender)
        internal
        returns (bool _isLinked)
    {
        assembly {
            sstore(nameHash, _number) // Map Hash -> Number
            mstore(0x00, nameHash)
            mstore(0x20, _sender)
            let senderHash := keccak256(0x00, 0x40)
            sstore(senderHash, nameHash)
        }
        _isLinked = true;
    }

    /**
     * @dev Clears a name record from storage.
     */
    function _performUnlink(bytes32 nameHash, bytes32 senderHash) internal returns (bool _isUnLinked) {
        assembly {
            sstore(nameHash, 0x00) // Burn mapping
            sstore(senderHash, 0x00)
        }
        _isUnLinked = true;
    }
}
