// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Initialize} from "@Initialize/Initialize.sol";
import {LinkName} from "@LinkName/LinkName.sol";
import {UnlinkName} from "@UnlinkName/UnlinkName.sol";
import {Price} from "@Price/Price.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Singleton
 * @notice The primary entry point for SALVA's name-to-wallet/number infrastructure.
 * @dev Combines registry initialization, resolution, linking, and unlinking.
 */
contract Singleton is Initializable, UUPSUpgradeable, Initialize, LinkName, UnlinkName, Price {
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
    constructor() {
        _disableInitializers();
    }

    function initialize(address _multiSig) external initializer {
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

    function _authorizeUpgrade(address newImplementation) internal override onlyMultiSig(_MULTISIG) {}

    receive() external payable {}
}
