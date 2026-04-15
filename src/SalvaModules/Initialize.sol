// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Resolve } from "@Resolve/Resolve.sol";

/**
 * @title Initialize
 * @notice Restricted logic for onboarding new registries into the SALVA ecosystem.
 * @dev Enforces strict namespace uniqueness and MultiSig-only access.
 */
abstract contract Initialize is Resolve {
    /**
     * @notice Registers a unique namespace to a specific registry contract.
     * @dev Callable only by the MultiSig. Reverts on address(0), missing '@' prefix,
     * duplicate registry, or namespace collision.
     * @param _registry The registry contract address to onboard.
     * @param _nspace The bytes16 namespace handle (e.g., "@salva"). Must start with 0x40.
     * @param _len The byte length of the namespace handle.
     * @return bool True on successful registration.
     */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — ACCESS CONTROL (MultiSig)
    // ─────────────────────────────────────────────────────────────────────────
    // 1. Modifier onlyMultiSig checks if sender() == _MULTISIG.
    // 2. This ensures that no namespace (e.g., "@salva") can be claimed
    //    without high-level consensus.
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — DATA INTEGRITY & PREFIX CHECK
    // ─────────────────────────────────────────────────────────────────────────
    // 1. address != address(0)
    // 2. _nspace[0] == 0x40 ('@')
    // DIAGRAMMATIC ACTION:
    // [ 0x40 ][ s ][ a ][ l ][ v ][ a ][ 0x00 ... ]
    // ^ Index 0 MUST be the '@' symbol.
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — COLLISION & DOUBLE-INITIALIZATION CHECK
    // ─────────────────────────────────────────────────────────────────────────
    // 1. Query _registryNamespace[_registry]: Is this contract already registered?
    // 2. Query _isInitialized[_nspace]: Is this handle (e.g., "@salva") already taken?
    // REVERT: Errors__Double_Initialization if either check fails.
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — STORAGE COMMITMENT
    // ─────────────────────────────────────────────────────────────────────────
    // 1. _registryNamespace[_registry] = { _nspace, _len }
    // 2. _isInitialized[_nspace] = true
    // RESULT: The registry is now authorized to link aliases and numbers.
    // ─────────────────────────────────────────────────────────────────────────
    function initializeRegistry(address _registry, bytes16 _nspace, bytes1 _len)
        external
        onlyMultiSig(_MULTISIG)
        returns (bool)
    {
        // Action: Validate registry existence and proper '@' prefixing
        if (_registry == address(0) || _nspace[0] != 0x40) {
            revert Errors__Invalid_Address_Or_Identifier_Too_Long_Or_Invalid_Prefix();
        }

        // Action: Check for existing mapping or namespace collision
        (bytes16 nspace,) = namespace(_registry);
        bool isInitialized = _isInitialized[_nspace];

        if (nspace != bytes16(0) || isInitialized) {
            revert Errors__Double_Initialization();
        }

        // Action: Finalize registration in storage
        // Mapping: [ Registry Address ] -> [ @Handle ]
        _registryNamespace[_registry]._namespace = _nspace;
        _registryNamespace[_registry]._length = _len;

        // Mapping: [ @Handle ] -> [ Claimed ]
        _isInitialized[_nspace] = true;

        return true;
    }
}
