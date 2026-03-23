// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Initialize} from "@Initialize/Initialize.sol";
import {LinkNumber} from "@LinkNumber/LinkNumber.sol";
import {LinkName} from "@LinkName/LinkName.sol";
import {UnlinkNumber} from "@UnlinkNumber/UnlinkNumber.sol";
import {UnlinkName} from "@UnlinkName/UnlinkName.sol";

/**
 *          @title  Salva Singleton
 *          @author cboi@Salva
 *          @notice Core registry enabling namespace-isolated account alias to address resolution.
 */
//         This contract is the final composition layer — it inherits all functional modules
//         and exposes the complete protocol interface. It contains no logic of its own.
//
//         INHERITANCE STRUCTURE
//         ──────────────────────
//         BaseSingleton (Storage + Errors + Modifier)
//              ↑
//         Initialize · LinkNumber · LinkName · UnlinkNumber · UnlinkName
//              ↑
//         Singleton  ←  you are here
//
//         DEPLOYMENT
//         ───────────
//         Deployed once. Immutable. Takes the MultiSig address in the constructor —
//         all privileged functions (initializeRegistry) are gated behind the Admin(s) MultiSig.
//         No upgradability. No admin keys. No second deployment.
contract Singleton is Initialize, LinkNumber, LinkName, UnlinkNumber, UnlinkName {
    /**
     *       @dev Protocol version stored as a bytecode constant.
     */
    //      Declared `constant` so the value is embedded directly in bytecode,
    //      eliminating SLOAD cost.
    uint8 private constant _VERSION = 2;

    // Sets the MultiSig address — the only account authorized to call initializeRegistry.
    // Called once at deployment. Cannot be changed after.
    /**
     *   @param _multiSig  The address of the deployed Salva MultiSig contract.
     */
    constructor(address _multiSig) {
        _MULTISIG = _multiSig;
    }

    // Returns the protocol version baked into bytecode.
    /**
     *   @return uint8  Always 2 for this deployment.
     */
    function version() public pure returns (uint8) {
        return _VERSION;
    }
}
