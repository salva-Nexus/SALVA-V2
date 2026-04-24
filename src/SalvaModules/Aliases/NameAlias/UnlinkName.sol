// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkName } from "@LinkName/LinkName.sol";

/**
 * @title UnlinkName
 * @author cboi@Salva
 * @notice Logic for removing the binding between an alias and its linked wallet address.
 * @dev Reconstructs the canonical storage key from calldata and zeros out the alias slot.
 *
 *      Inherits `LinkName` (→ `Initialize` → `Resolve` → `NameLib` → `Modifier`
 *                          → `Errors` → `Storage` → `Context`).
 */
abstract contract UnlinkName is LinkName {
    // ─────────────────────────────────────────────────────────────────────────
    // ALIAS REMOVAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Unlinks a namespaced alias by clearing its storage slot.
     *
     * @dev Only registered registry contracts may call this function.
     *      The canonical storage key is reconstructed from calldata to zero the slot.
     *
     *      STEP 1 — CALLER IDENTITY & NAMESPACE
     *        1. Query `_registryNamespace[_msgSender()]`.
     *        2. Retrieve the assigned `bytes31` handle and its length.
     *        3. If the handle is `bytes31(0)` the caller is not registered → REVERT.
     *
     *      STEP 2 — RAW DATA RECOVERY (calldata)
     *        `name` (bytes calldata) layout:
     *          [ 0x00 – 0x1F ] nameLength
     *          [ 0x20 – 0x3F ] raw alias data → `nameBytes`
     *
     *      STEP 3 — STORAGE-KEY RE-WELDING
     *        `fullLength` = `processedNameLen` + `namespaceLength`
     *        a. `_normalizeAndValidate` (mark=1) — re-generates the canonical name
     *           without strict char validation (we are deleting, not writing).
     *        b. `_computeNameHash` (skipCollision=1) — skips the "Taken" guard
     *           since the slot must exist to be removed.
     *
     *      STEP 4 — OWNERSHIP CHECK
     *        `_checkCaller(caller, nameHash)` — verifies `caller` owns the alias
     *        via the ownership-index mapping.
     *
     *      STEP 5 — STORAGE ZEROING
     *        `_performUnlink(nameHash, ownershipKey)`:
     *          → sstore(nameHash,     0x00)  — removes forward resolution
     *          → sstore(ownershipKey, 0x00)  — removes ownership index + triggers gas refund
     *
     * @param name    The local alias bytes to unlink (e.g. `"charles"`).
     * @param caller  The originating user EOA — must match the original registrant.
     * @return isUnlinked `true` on successful storage deletion.
     */
    function unlink(bytes calldata name, address caller) external returns (bool isUnlinked) {
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

        // validationMode = 1 → skip strict char validation (unlink/read path)
        uint256 processedNameLen = _normalizeAndValidate(nameLength, nameBytes, 1);

        uint256 fullLength = processedNameLen + uint256(uint8(namespaceLength));

        // skipCollisionCheck = 1 → slot must already exist, skip guard
        bytes32 nameHash = _computeNameHash(namespaceHandle, processedNameLen, fullLength, 1);

        bytes32 ownershipKey = _checkCaller(caller, nameHash);

        isUnlinked = _performUnlink(nameHash, ownershipKey);
    }
}
