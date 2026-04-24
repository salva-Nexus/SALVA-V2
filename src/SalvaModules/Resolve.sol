// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { NameLib } from "@NameLib/NameLib.sol";

/**
 * @title Resolve
 * @author cboi@Salva
 * @notice Read-only resolution logic for the Salva Singleton.
 * @dev Resolves human-readable namespaced aliases (e.g. `"charles[at]salva"`) back to
 *      their linked wallet addresses using the same welded-keccak256 storage key
 *      that `LinkName` writes.
 *
 *      Inherits `NameLib` for assembly-optimized string manipulation and hashing.
 */
abstract contract Resolve is NameLib {
    // ─────────────────────────────────────────────────────────────────────────
    // ALIAS RESOLUTION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Resolves a fully qualified namespaced alias to its linked wallet address.
     *
     * @dev Call flow:
     *
     *      STEP 1 — CALLDATA EXTRACTION
     *        `aliasName` (bytes calldata) layout:
     *          [ 0x00 – 0x1F ] length of the bytes array
     *          [ 0x20 – …    ] actual UTF-8 data  (e.g. `"charles[at]salva"`)
     *
     *      STEP 2 — NAMESPACE ISOLATION (assembly)
     *        Goal: split `"charles[at]salva"` into local name `"charles"` and
     *        namespace handle `"[at]salva"`.
     *
     *        Memory layout after `calldatacopy` to `0x80`:
     *          [ c h a r l e s ][at][ s a l v a ]
     *          ├─ 7 bytes ─────┤ ↑  ├─ namespace ─┤
     *
     *        `lengthWithoutNamespace` = 7  (returned by `_normalizeAndValidate`)
     *        `namespaceHandle` = mload(0x80 + 7) → `[at]salva\x00...`
     *
     *      STEP 3 — STORAGE-KEY RECONSTRUCTION
     *        `_normalizeAndValidate` re-applies the anti-phishing flip.
     *        `_computeNameHash` welds the canonical name with the namespace handle.
     *        `skipCollisionCheck = 1` — view function, no collision guard needed.
     *
     *      STEP 4 — DIRECT STORAGE LOAD
     *        `sload(nameHash)` returns the stored wallet address.
     *
     * @param aliasName  Full namespaced alias in UTF-8 bytes (e.g. `"charles[at]salva"`).
     * @return wallet    The wallet address bound to the alias, or `address(0)` if unmapped.
     */
    function resolveAddress(bytes calldata aliasName) external view returns (address wallet) {
        uint256 fullLength;
        bytes32 nameData;
        assembly {
            fullLength := aliasName.length
            nameData := calldataload(aliasName.offset)
        }

        uint256 nameLength;
        if (fullLength > 32) {
            uint256 rem = fullLength - 32;
            nameLength = fullLength - rem;
        }

        // mark = 1 → skip strict character validation (read path)
        uint256 lengthWithoutNamespace =
            _normalizeAndValidate(fullLength > 32 ? nameLength : fullLength, nameData, 1);

        bytes31 namespaceHandle;
        assembly {
            // Copy 48 bytes of calldata to scratch space at 0x80
            calldatacopy(0x80, aliasName.offset, 0x30)

            // Extract the namespace handle starting immediately after the local name.
            // Diagram: [ Local Name ][at][ Namespace ]
            //          ^ 0x80        ^ 0x80 + lengthWithoutNamespace
            namespaceHandle := mload(add(0x80, lengthWithoutNamespace))
        }

        // skipCollisionCheck = 1 → view function, skip collision guard
        bytes32 nameHash = _computeNameHash(namespaceHandle, lengthWithoutNamespace, fullLength, 1);

        assembly {
            wallet := sload(nameHash)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // NAMESPACE QUERY
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the namespace handle and its byte length for a given registry address.
     * @dev Reads directly from `_registryNamespace` storage mapping (declared in `Storage`).
     *
     * @param registry         The registry contract address to query.
     * @return namespaceHandle The bytes31 handle assigned to this registry (e.g.
     * `[at]salva\x00...`).
     * @return namespaceLength The byte length of the handle including the `[at]` prefix.
     */
    function namespace(address registry)
        public
        view
        returns (bytes31 namespaceHandle, bytes1 namespaceLength)
    {
        Namespace storage ns = _registryNamespace[registry];
        namespaceHandle = ns.handle;
        namespaceLength = ns.length;
    }
}
