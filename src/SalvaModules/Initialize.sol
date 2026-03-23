// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract Initialize is BaseSingleton {
    // Registers a new registry contract with a unique namespace identifier.
    // Only callable by the Salva MultiSig — no namespace can be claimed without admin approval.
    // Called once per registry. Reverts on re-registration or identifier collision.
    //
    // Even though registration passes through the MultiSig, this function still
    // validates the data independently — it does not blindly trust its caller.
    //
    // VALIDATION ORDER
    // ─────────────────
    // [A] onlyMultiSig modifier      — caller must be the Salva MultiSig
    // [B] address + prefix check     — registry != address(0), _nspace[0] must be '@' (0x40)
    // [C] double-initialization check — registry has no existing namespace, namespace not already claimed
    /**
     *  @param _registry  The registry contract address to initialize.
     *  @param _nspace    The bytes16 namespace identifier e.g. "@salva", "@coinbase".
     *  @return bool      Always true on success.
     */
    function initializeRegistry(address _registry, bytes16 _nspace) external onlyMultiSig(_MULTISIG) returns (bool) {
        if (_registry == address(0) || _nspace[0] != 0x40) {
            revert Errors__Invalid_Address_Or_Identifier_Too_Long_Or_Invalid_Prefix();
        }

        (bytes16 nspace, bool isInitialized) = namespace(_registry);
        if (nspace != bytes16(0) || isInitialized) {
            revert Errors__Double_Initialization();
        }

        _registryNamespace[_registry] = _nspace;
        _isInitialized[_nspace] = true;
        return true;
    }
}
