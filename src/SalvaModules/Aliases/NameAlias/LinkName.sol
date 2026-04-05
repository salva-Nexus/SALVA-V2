// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Resolve} from "@Resolve/Resolve.sol";

/**
 * @title LinkName
 * @notice Entry point for binding a namespaced alias to a wallet address.
 * @dev Orchestrates namespace retrieval, name normalization, storage-key
 *      welding, and the final wallet-address write in a single atomic call.
 *
 *      Call flow:
 *        Registry → linkNameAlias → _normalizeAndValidate
 *                                 → _computeNameHash
 *                                 → _performLinkToWallet
 */
abstract contract LinkName is Resolve {
    /**
     * @notice Links a local name alias to a destination wallet address under
     *         the calling registry's namespace.
     *
     * @dev Only registered registries may call this function. The caller's
     *      namespace is read from singleton storage — it is never supplied by
     *      the user. The name is normalized and welded with the namespace to
     *      produce a collision-resistant storage key.
     *
     * ── STEP 1 · NAMESPACE RETRIEVAL ────────────────────────────────────────
     *  1. Resolve `sender()` against the registry mapping in singleton storage.
     *  2. Extract the `bytes16` namespace handle and its length.
     *  3. If the handle is `0x00` the caller is not a registered registry → REVERT.
     *
     * ── STEP 2 · NAME EXTRACTION (Calldata) ─────────────────────────────────
     *  `name` (bytes calldata) layout:
     *    [ 0x00 – 0x1F ] length word  (e.g. 7 for "charles")
     *    [ 0x20 – 0x3F ] raw UTF-8 bytes → loaded into `nameToBytes`
     *
     * ── STEP 3 · STORAGE-KEY WELDING ────────────────────────────────────────
     *  `fullLength` = normalizedNameLength + namespaceLength
     *  a. `_normalizeAndValidate` — enforces character rules and applies the
     *     anti-phishing alphabetical flip for underscore-split names.
     *  b. `_computeNameHash`:
     *       [ Normalized Name ][ Namespace Handle ]
     *       ├──── name ───────┤├──── handle ──────┤ → keccak256 → nameHash
     *
     * ── STEP 4 · STORAGE WRITE ──────────────────────────────────────────────
     *  `_performLinkToWallet(nameHash, wallet, _sender)`
     *    → sstore(nameHash, wallet)          — forward resolution
     *    → sstore(senderHash, nameHash)      — ownership index for unlink
     *
     * @param name    Raw alias bytes supplied by the user (e.g. `"charles"`).
     *                Must be ≤ 32 bytes, lowercase a–z, digits 2–9, max one `_`.
     * @param wallet  Destination wallet address to bind to the alias.
     * @param _sender The originating user EOA, captured by the registry as
     *                `msg.sender` and forwarded here for ownership indexing.
     * @return isLinked `true` on a successful storage write.
     */
    function linkNameAlias(bytes calldata name, address wallet, address _sender)
        external
        payable
        nonReentrant
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
        bytes32 nameHash = _computeNameHash(namespaceHandle, processedNameLen, fullLength, 0);

        // Action: Execute wallet-address storage write
        // Diagram: [ nameHash ] → { address wallet }
        isLinked = _performLinkToWallet(nameHash, wallet, _sender);
    }
}
