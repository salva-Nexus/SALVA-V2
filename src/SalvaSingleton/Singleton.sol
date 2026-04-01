// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Initialize} from "@Initialize/Initialize.sol";
import {LinkName} from "@LinkName/LinkName.sol";
import {UnlinkName} from "@UnlinkName/UnlinkName.sol";

/**
 * @title Singleton
 * @notice The primary entry point for SALVA's name-to-wallet/number infrastructure.
 * @dev Combines registry initialization, resolution, linking, and unlinking.
 */
contract Singleton is Initialize, LinkName, UnlinkName {
    // ─────────────────────────────────────────────────────────────────────────
    // PROTOCOL CONSTANTS
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @dev Protocol version stored as a bytecode constant.
     * DIAGRAMMATIC ACTION:
     * [ PUSH1 0x02 ] -> Baked into contract bytecode.
     * Eliminates SLOAD (2100 gas) by replacing it with a cheap PUSH (3 gas).
     */
    uint8 private constant _VERSION = 2;

    /**
     * @notice Sets the administrative MultiSig address during deployment.
     * * ─────────────────────────────────────────────────────────────────────────
     * DEPLOYMENT STATE (Constructor)
     * ─────────────────────────────────────────────────────────────────────────
     * 1. Assigns the immutable _MULTISIG address.
     * 2. This address is the ONLY account capable of calling initializeRegistry.
     * 3. Cannot be updated.
     * * ─────────────────────────────────────────────────────────────────────────
     */
    constructor(address _multiSig) {
        _MULTISIG = _multiSig;
    }

    /**
     * @notice Returns the protocol version identifier.
     * * DIAGRAMMATIC FLOW:
     * 1. Function called (Pure).
     * 2. Returns value 2 directly from bytecode.
     */
    function version() public pure returns (uint8) {
        return _VERSION;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INHERITED CAPABILITIES (Summary)
    // ─────────────────────────────────────────────────────────────────────────
    // 1. Initialize: Handles multi-sig protected registry setup.
    // 2. LinkName:   Handles alias -> address or number binding with anti-phishing.
    // 3. UnlinkName: Handles the removal of alias bindings.
    // 4. Resolve:    (via Link/Unlink) Provides view functions for resolution.
    // ─────────────────────────────────────────────────────────────────────────
}
