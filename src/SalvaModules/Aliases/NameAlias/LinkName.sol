// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Resolve} from "@Resolve/Resolve.sol";

/**
 * @title LinkName
 * @notice Entry point for binding namespaced aliases to addresses or numbers.
 * @dev Combines namespace retrieval, name normalization, and storage-key welding.
 */
abstract contract LinkName is Resolve {
    /**
     * @notice Links a name alias (e.g., "charles") to a destination under the caller's namespace.
     * @dev Callable only by registered registries. Enforces one-link-to-data and anti-phishing rules.
     * @param name The local alias bytes (e.g., "charles").
     * @param wallet The destination wallet address. Set to address(0) if linking to a number.
     * @param number The destination account number. Set to 0 if linking to a wallet.
     * @return isLinked True on successful storage write.
     */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — NAMESPACE RETRIEVAL
    // ─────────────────────────────────────────────────────────────────────────
    // 1. Query sender() in the Registry mapping.
    // 2. Extract bytes16 handle (e.g., "@salva") and its length.
    // 3. If namespace is 0x00, the caller isn't a registered registry -> REVERT.
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — NAME DATA EXTRACTION (Calldata)
    // ─────────────────────────────────────────────────────────────────────────
    // name (bytes calldata) Layout:
    // [ 0x00 - 0x1F ]: length (e.g., 7 for "charles")
    // [ 0x20 - 0x3F ]: raw data ("charles") -> loaded into nameToBytes
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — STORAGE KEY WELDING
    // ─────────────────────────────────────────────────────────────────────────
    // fullLength = nameLength + namespaceLength
    // 1. _normalizeAndValidate: Flips "a_b" to "b_a" (alphabetical) for phishing protection.
    // 2. _computeNameHash:
    //    [ Normalized Name ][ Namespace ]
    //    ├────── name ─────┤├─ handle ──┤ -> keccak256 -> nameHash
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — CONDITIONAL STORAGE WRITE
    // ─────────────────────────────────────────────────────────────────────────
    // if (wallet != 0) -> Sstore(nameHash, wallet)
    // else             -> Sstore(nameHash, number)
    // ─────────────────────────────────────────────────────────────────────────
    function linkNameAlias(bytes calldata name, address wallet, uint256 number)
        external
        onlyOneLinkToData
        returns (bool isLinked)
    {
        // Action: Fetch caller's assigned namespace
        (bytes16 namespaceHandle, bytes1 namespaceLength) = namespace(sender());
        if (namespaceHandle == bytes16(0)) {
            revert Errors__Not_Registered();
        }

        uint256 nameLength;
        bytes32 nameToBytes;
        assembly {
            // Action: Extract local name length from calldata
            nameLength := name.length
            // Action: Load raw bytes into a word for normalization
            nameToBytes := calldataload(name.offset)
        }

        // Action: Perform Anti-Phishing Flip & Character Validation
        // mark: 0 = Enforce strict a-z, 2-9, _ rules for WRITE operations
        uint256 processedNameLen = _normalizeAndValidate(nameLength, nameToBytes, 0);

        // Action: Calculate total size for the hash buffer (Name + @Namespace)
        uint256 fullLength = processedNameLen + uint256(uint8(namespaceLength));

        // Action: Generate the unique storage pointer (welded key)
        // storageCheck: 0 = Perform collision check to ensure name isn't "Taken"
        bytes32 nameHash = _computeNameHash(namespaceHandle, nameLength, fullLength, 0);

        // Action: Determine link type and execute storage write
        // Diagram: [ nameHash ] -> { address } OR { uint256 }
        isLinked =
            wallet == address(0) ? _performLinkToNumber(nameHash, number) : _performLinkToWallet(nameHash, wallet);
    }
}
