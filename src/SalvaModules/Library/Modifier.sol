// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Errors} from "@Errors/Errors.sol";
import {Context} from "@Context/Context.sol";

/**
 * @title Modifier
 * @notice Validation logic for input integrity and access control.
 * @dev Uses assembly for high-performance calldata inspection.
 */
abstract contract Modifier is Errors, Context {
    /**
     * @dev Ensures that a name alias links to EITHER a wallet OR a number, never both or none.
     * * ─────────────────────────────────────────────────────────────────────────
     * STEP 1 — CALLDATA INSPECTION (Assembly)
     * ─────────────────────────────────────────────────────────────────────────
     * Based on function: linkNameAlias(bytes name, address wallet, uint256 number)
     * Calldata Layout:
     * [ 0x00 - 0x03 ]: Function Selector
     * [ 0x04 - 0x23 ]: 'name' bytes offset
     * [ 0x24 - 0x43 ]: 'wallet' (address)
     * [ 0x44 - 0x63 ]: 'number' (uint256)
     * * DIAGRAMMATIC ACTION:
     * 1. Calldataload(0x24) -> Extracts the 'wallet' address.
     * 2. Calldataload(0x44) -> Extracts the 'number'.
     * * ─────────────────────────────────────────────────────────────────────────
     * STEP 2 — EXCLUSIVITY LOGIC
     * ─────────────────────────────────────────────────────────────────────────
     * XOR-style validation:
     * - Case A: Wallet is 0x0? Number MUST NOT be 0.
     * - Case B: Wallet is set? Number MUST be 0.
     * ─────────────────────────────────────────────────────────────────────────
     */
    modifier onlyOneLinkToData() {
        address _wallet;
        uint256 _number;
        assembly {
            // Action: Skip selector and name offset to grab parameters
            _wallet := calldataload(0x24)
            _number := calldataload(0x44)
        }

        if (_wallet == address(0)) {
            // Diagram: If no wallet, a number is required for the link.
            if (_number == 0) {
                revert Errors__Invalid_Values();
            }
        } else {
            // Diagram: If wallet is present, number must be empty (prevent dual-link).
            if (_number != 0) {
                revert Errors__Only_One_Value();
            }
        }
        _;
    }

    /**
     * @dev Restricts function access to the Salva MultiSig contract only.
     * * ─────────────────────────────────────────────────────────────────────────
     * ACCESS CONTROL FLOW
     * ─────────────────────────────────────────────────────────────────────────
     * 1. Resolve caller via sender().
     * 2. Compare against protocol-defined multiSig address.
     * 3. Result: Permission granted ONLY for authorized registry initialization.
     * ─────────────────────────────────────────────────────────────────────────
     */
    modifier onlyMultiSig(address multiSig) {
        if (sender() != multiSig) revert Errors__Not_Authorized();
        _;
    }
}
