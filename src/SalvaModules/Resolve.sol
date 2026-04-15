// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { NameLib } from "@NameLib/NameLib.sol";

/**
 * @title Resolve
 * @notice Logic for resolving human-readable aliases back to addresses or account numbers.
 * @dev Inherits NameLib for assembly-optimized string manipulation and hashing.
 */
abstract contract Resolve is NameLib {
    /**
     * @notice Resolves a namespaced alias (e.g., "charles@salva") to a wallet address.
     * @dev Extracts namespace from calldata by splitting at the '@' boundary,
     * then reconstructs the storage key via _normalizeAndValidate and _computeNameHash.
     */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — CALLDATA EXTRACTION
    // ─────────────────────────────────────────────────────────────────────────
    // aliasName (bytes calldata) layout:
    // [ 0x00 - 0x1F ]: Length of the bytes array
    // [ 0x20 - 0x3F ]: Actual string data (e.g., "charles@salva")
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — NAMESPACE ISOLATION (Assembly)
    // ─────────────────────────────────────────────────────────────────────────
    // To get the namespace handle after the '@':
    // 1. Copy raw calldata to Memory[0x80]
    // 2. Calculate offset: 0x80 + lengthWithoutNamespace
    // 3. Mload bytes16 from that offset to grab the handle.
    //
    // EXAMPLE: "charles@salva"
    // [ c h a r l e s ] [ @ ] [ s a l v a ]
    // ├─ 7 bytes ───┤   ↑   ├─ namespace ┤
    //
    // lengthWithoutNamespace = 7
    // namespaceHandle = Mload(0x80 + 7) -> "@salva"
    // ─────────────────────────────────────────────────────────────────────────
    function resolveAddress(bytes calldata aliasName) external view returns (address wallet) {
        uint256 fullLength;
        bytes32 nameData;
        assembly {
            // Action: Load total length of input bytes
            fullLength := aliasName.length
            // Action: Load first 32 bytes of string data directly from calldata offset
            nameData := calldataload(aliasName.offset)
        }

        // Action: Get length of 'charles' part and normalize order (if underscore exists)
        // mark: 1 = bypass standard char validation for resolution
        uint256 lengthWithoutNamespace = _normalizeAndValidate(fullLength, nameData, 1);

        bytes16 namespaceHandle;

        assembly {
            // Memory Action: Copy 48 bytes of calldata to scratch space starting at 0x80
            calldatacopy(0x80, aliasName.offset, 0x30)

            // Action: Extract the namespace starting immediately after the local name
            // Diagram: [ Local Name ][ @ ][ Namespace ]
            //          ^ 0x80        ^ offset (lengthWithoutNamespace)
            namespaceHandle := mload(add(0x80, lengthWithoutNamespace))
        }

        // Action: Generate the unique storage slot key
        // storageCheck: 1 = View function (skip collision check)
        bytes32 nameHash = _computeNameHash(namespaceHandle, lengthWithoutNamespace, fullLength, 1);

        assembly {
            // Action: Direct Storage Load of the mapped wallet address
            wallet := sload(nameHash)
        }
    }

    /**
     * @notice Returns the namespace and initialization status of a given registry contract.
     * @dev Reads directly from _registryNamespace storage mapping.
     * @param registry The address of the registry contract to query.
     * @return namespaceHandle The bytes16 handle (e.g., "@salva").
     * @return namespaceLength The byte length of the handle including the '@'.
     */
    function namespace(address registry)
        public
        view
        returns (bytes16 namespaceHandle, bytes1 namespaceLength)
    {
        Namespace storage ns = _registryNamespace[registry];
        namespaceHandle = ns._namespace;
        namespaceLength = ns._length;
    }
}
