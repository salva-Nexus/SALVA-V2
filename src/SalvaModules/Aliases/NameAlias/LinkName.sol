// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Initialize } from "@Initialize/Initialize.sol";

/**
 * @title LinkName
 * @author cboi@Salva
 * @notice Entry point for binding a namespaced alias to a wallet address.
 * @dev Orchestrates namespace retrieval, name normalization, storage-key
 *      welding, and the final wallet-address write in a single atomic call.
 *
 *      Inherits `Initialize` (→ `Resolve` → `NameLib` → `Modifier` → `Errors`
 *                             → `Storage` → `Context`).
 *
 *      Call flow:
 *        Registry → `linkNameAlias` → `_normalizeAndValidate`
 *                                   → `_computeNameHash`
 *                                   → `_performLinkToWallet`
 */
abstract contract LinkName is Initialize {
    // ─────────────────────────────────────────────────────────────────────────
    // ALIAS WRITE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Links a local name alias to a destination wallet address under the
     *         calling registry's namespace.
     *
     * @dev Only registered registry contracts may call this function. The caller's
     *      namespace is read from Singleton storage — it is never supplied by the user.
     *      The name is normalized and welded with the namespace to produce a
     *      collision-resistant storage key.
     *
     *      STEP 1 — NAMESPACE RETRIEVAL
     *        1. Resolve `_msgSender()` against `_registryNamespace` in storage.
     *        2. Extract the `bytes31` namespace handle and its length.
     *        3. If the handle is `bytes31(0)` the caller is not registered → REVERT.
     *
     *      STEP 2 — NAME EXTRACTION (calldata)
     *        `name` (bytes calldata) layout:
     *          [ 0x00 – 0x1F ] length word  (e.g. 7 for `"charles"`)
     *          [ 0x20 – 0x3F ] raw UTF-8 bytes → loaded into `nameBytes`
     *
     *      STEP 3 — STORAGE-KEY WELDING
     *        `fullLength` = `normalizedNameLength` + `namespaceLength`
     *        a. `_normalizeAndValidate` (mark=0) — enforces a–z / 2–9 / `_` rules
     *           and applies the anti-phishing alphabetical flip.
     *        b. `_computeNameHash` (skipCollision=0) — welds and hashes, runs
     *           collision guard to reject already-taken names.
     *
     *      STEP 4 — STORAGE WRITE
     *        `_performLinkToWallet(nameHash, wallet, caller)`
     *          → sstore(nameHash, wallet)                        — forward resolution
     *          → sstore(keccak256(nameHash ++ caller), nameHash) — ownership index
     *
     * @param name    Raw alias bytes supplied by the user (e.g. `"charles"`).
     *                Must be ≤ 32 bytes, lowercase a–z, digits 2–9, max one `_`.
     * @param wallet  Destination wallet address to bind to the alias.
     * @param caller  The originating user EOA, captured by the registry as `msg.sender`
     *                and forwarded here for ownership indexing.
     * @return isLinked `true` on a successful storage write.
     */
    function linkNameAlias(bytes calldata name, address wallet, address caller)
        external
        nonReentrant
        whenNotPaused(_paused)
        returns (bool isLinked)
    {
        (bytes31 namespaceHandle, bytes1 namespaceLength) = namespace(_msgSender());
        if (namespaceHandle == bytes31(0)) {
            revert Errors__NotRegistered();
        }

        uint256 nameLength;
        bytes32 nameBytes;
        assembly {
            nameLength := name.length
            nameBytes := calldataload(name.offset)
        }

        // validationMode = 0 → enforce strict a-z, 2-9, _ rules (write path)
        uint256 processedNameLen = _normalizeAndValidate(nameLength, nameBytes, 0);

        uint256 fullLength = processedNameLen + uint256(uint8(namespaceLength));

        // skipCollisionCheck = 0 → reject already-taken names
        bytes32 nameHash = _computeNameHash(namespaceHandle, processedNameLen, fullLength, 0);

        isLinked = _performLinkToWallet(nameHash, wallet, caller);
    }
}
