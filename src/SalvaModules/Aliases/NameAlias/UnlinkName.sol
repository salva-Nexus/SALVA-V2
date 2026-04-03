// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Resolve} from "@Resolve/Resolve.sol";

/**
 * @title UnlinkName
 * @notice Logic for removing the binding between an alias and its stored data.
 * @dev Reconstructs the storage key from calldata to zero out the specific slot.
 */
abstract contract UnlinkName is Resolve {
    /**
     * @notice Unlinks a namespaced alias by clearing its storage slot.
     * @dev Callable only by registered registries. Re-normalizes the name to
     * reconstruct the canonical storage key before zeroing the slot.
     * @param name The local alias bytes to unlink (e.g., "charles").
     * @return _isUnlinked True on successful storage deletion.
     */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — CALLER IDENTITY & NAMESPACE
    // ─────────────────────────────────────────────────────────────────────────
    // 1. Query the registry mapping for the sender().
    // 2. Retrieve the assigned bytes16 namespaceHandle and its length.
    // 3. Ensure the caller is authorized to manage this namespace.
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — RAW DATA RECOVERY (Calldata)
    // ─────────────────────────────────────────────────────────────────────────
    // name (bytes calldata) Layout:
    // [ 0x00 - 0x1F ]: nameLength
    // [ 0x20 - 0x3F ]: raw alias data -> nameToBytes
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — STORAGE KEY RE-WELDING
    // ─────────────────────────────────────────────────────────────────────────
    // fullLength = nameLength + namespaceLength
    // 1. _normalizeAndValidate:
    //    Re-generates the flipped/canonical version of the name.
    //    mark: 1 -> Skipping strict char validation as we are deleting.
    // 2. _computeNameHash:
    //    [ Flipped Name ][ Namespace ] -> keccak256 -> nameHash
    //    storageCheck: 1 -> Skipping the "Taken" check since we are unlinking.
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — STORAGE ZEROING
    // ─────────────────────────────────────────────────────────────────────────
    // _performUnlink(nameHash):
    // assembly { sstore(nameHash, 0x00) }
    // Effectively deletes the link to the address or number.
    // ─────────────────────────────────────────────────────────────────────────
    function unlink(bytes calldata name) external returns (bool _isUnlinked) {
        // Action: Fetch the namespace belonging to the caller
        (bytes16 namespaceHandle, bytes1 namespaceLength) = namespace(sender());
        if (namespaceHandle == bytes16(0)) {
            revert Errors__Not_Registered();
        }

        uint256 nameLength;
        bytes32 nameToBytes;
        assembly {
            // Action: Extract local name length from calldata
            nameLength := name.length
            // Action: Load raw bytes for normalization
            nameToBytes := calldataload(name.offset)
        }

        // Action: Perform Anti-Phishing Flip & Character Validation
        // mark: 0 = Enforce strict a-z, 2-9, _ rules for WRITE operations
        uint256 processedNameLen = _normalizeAndValidate(nameLength, nameToBytes, 1);

        // Action: Calculate total size for the hash buffer (Name + @Namespace)
        uint256 fullLength = processedNameLen + uint256(uint8(namespaceLength));

        // Action: Re-generate the welded storage key
        // storageCheck: 1 = Skipping collision check
        bytes32 nameHash = _computeNameHash(namespaceHandle, nameLength, fullLength, 1);

        // Action: Execute storage deletion
        // Diagram: Sstore(nameHash, 0x00) -> Frees slot & triggers gas refund
        _isUnlinked = _performUnlink(nameHash);
    }
}
