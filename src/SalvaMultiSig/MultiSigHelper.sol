// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSigModifier} from "@MultiSigModifier/MultiSigModifier.sol";

/**
 * @title MultiSigHelper
 * @notice Internal view logic for tracking MultiSig validation progress.
 * @dev Provides transparency into the threshold-counting mechanism for registries and validators.
 */
abstract contract MultiSigHelper is MultiSigModifier {
    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY TRACKING
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the number of validations still needed to initialize a registry.
     * * DIAGRAMMATIC FLOW:
     * 1. Access _registry[address] Storage Slot.
     * 2. Load 'remaining' (uint8) counter.
     * 3. Result: Threshold - Current Validations.
     */
    function _registryValidationCountRemains(address registry) external view returns (uint256) {
        Registry storage reg = _registry[registry];
        return uint256(reg.remaining);
    }

    /**
     * @notice Checks if the caller has already signed off on a registry initialization.
     * * DIAGRAMMATIC FLOW:
     * 1. Query Registry struct for the specific target.
     * 2. Check nested mapping: hasValidated[msg.sender].
     * 3. Result: true if caller already voted (Prevents double-signing).
     */
    function _hasValidatedRegistry(address registry) external view returns (bool) {
        Registry storage reg = _registry[registry];
        return reg.hasValidated[sender()];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR UPDATE TRACKING
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the remaining signatures needed for a validator set update.
     * * DIAGRAMMATIC FLOW:
     * 1. Access _updateValidator[_addr] Storage Slot.
     * 2. Load 'remaining' counter.
     * 3. If 0, the update is ready for execution/finalization.
     */
    function _validatorValidationCountRemains(address _addr) external view returns (uint256) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        return uint256(update.remaining);
    }

    /**
     * @notice Checks if the caller has signed off on a specific validator change.
     * * DIAGRAMMATIC FLOW:
     * 1. Access ValidatorUpdateRequest struct.
     * 2. Query hasValidated[sender()].
     * 3. Ensures consensus is built from unique signatures.
     */
    function _hasValidatedValidatorUpdate(address _addr) external view returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        return update.hasValidated[sender()];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RECOVERY STATUS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Verifies if an address is currently recognized as a recovery entity.
     * * DIAGRAMMATIC FLOW:
     * 1. Sload from _recovery[address] mapping.
     * 2. Returns true if the address holds active recovery permissions.
     */
    function isRecovery(address recovery) external view returns (bool) {
        return _recovery[recovery];
    }

    function isValidator(address validator) external view returns (bool) {
        return _isValidator[validator];
    }
}
