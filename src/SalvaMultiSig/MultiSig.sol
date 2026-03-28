// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";
import {MultiSigHelper} from "@MultiSigHelper/MultiSigHelper.sol";
import {Events} from "@Events/Events.sol";

/// @title Salva Administrative MultiSig
/// @author cboi@Salva
/// @notice Manages protocol-level administrative actions including registry initialization and validator set updates.
/// @dev Implements a majority-based quorum and a mandatory security timelock to prevent single-point-of-failure attacks.
/**
 * VALIDATOR QUORUM
 * ─────────────────
 * Required validations = floor((_numOfValidators - 1) / 2) + 1
 * Requires a simple majority (> 50%) of active validators to reach quorum.
 *
 * SECURITY TIMELOCK
 * ─────────────────
 * Once quorum is reached, a `_timeInterval` delay (intended to be 24-48h) is enforced.
 * This window allows any validator to audit and potentially `cancel` a malicious proposal.
 *
 * RECOVERY MODE
 * ───────────────────
 * Authorized cold-storage addresses can bypass the quorum count to immediately trigger the timelock.
 * Execution still requires the timelock to expire. Use only in event of validator key compromise.
 */
contract MultiSig is Events, MultiSigHelper {
    /// @notice Initializes the MultiSig with the deployer as the first validator.
    constructor() {
        _isValidator[sender()] = true;
        _numOfValidators = 1;
    }

    /// @notice Sets the Salva Singleton address.
    /// @dev Can only be called once. Separated from constructor to resolve circular deployment dependencies.
    /// @param singleton The address of the deployed Salva Singleton contract.
    function setSingleton(address singleton) external onlyValidators {
        SalvaSingleton storage s = _salvaSingleton;
        if (s._isSet) revert Errors__Singleton_Already_Set();
        s._singleton = singleton;
        s._isSet = true;
    }

    /// @notice Proposes a new registry namespace (e.g., "@coinbase") for initialization.
    /// @dev Proposer must still call `validateRegistry` to count their vote.
    /// @param _nspace The string identifier for the namespace. Must be <= 16 bytes.
    /// @param registry The registry contract address being linked to this namespace.
    /// @return The registry address, string namespace, bytes16 namespace, and success status.
    function proposeInitialization(string memory _nspace, address registry)
        external
        onlyValidators
        enforceBytes16(_nspace)
        returns (address, string memory, bytes16, uint32)
    {
        Registry storage reg = _registry[registry];
        if (reg.isProposed || reg.isExecuted) revert Errors__Registry_Init_Proposed();

        bytes16 toBytes = bytes16(bytes(_nspace));
        uint32 required = uint32((_numOfValidators - 1) / 2) + 1;
        reg.registryAddress = registry;
        reg.nspace = toBytes;
        reg.requiredValidationCount = required;
        reg.remaining = required;
        reg.isProposed = true;

        emit RegistryInitializationProposed(registry, _nspace, toBytes);
        return (registry, _nspace, toBytes, required);
    }

    /// @notice Proposes adding or removing a validator from the set.
    /// @param _addr The target address to be updated.
    /// @param _action True to add, False to remove.
    /// @return The target address, action type, and success status.
    function proposeValidatorUpdate(address _addr, bool _action)
        external
        onlyValidators
        returns (address, bool, uint32)
    {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        if (update.isProposed || update.isExecuted) revert Errors__Validator_Update_Proposed();

        uint32 required = uint32((_numOfValidators - 1) / 2) + 1;
        update.addr = _addr;
        update.action = _action;
        update.requiredValidationCount = required;
        update.remaining = required;
        update.isProposed = true;

        emit ValidatorUpdateProposed(_addr, _action);
        return (_addr, _action, required);
    }

    /// @notice Casts a vote to approve a registry initialization.
    /// @dev Reaching quorum triggers the `timeLock`. Recovery addresses trigger it immediately.
    /// @param registry The address of the proposed registry.
    /// @return The registry address, namespace, remaining votes needed, and success status.
    function validateRegistry(address registry) external onlyValidators returns (address, bytes16, uint32) {
        Registry storage reg = _registry[registry];
        if (!reg.isProposed) revert Errors__Registry_Init_Not_Proposed();
        if (reg.hasValidated[sender()]) revert Errors__Has_Validated();

        reg.hasValidated[sender()] = true;
        reg.validationCount++;

        if (reg.validationCount >= reg.requiredValidationCount || _recovery[sender()]) {
            reg.timeLock = block.timestamp + _timeInterval;
            reg.isValidated = true;
        }

        bytes16 nspace = reg.nspace;
        uint32 remainingValidation = reg.requiredValidationCount - reg.validationCount;
        reg.remaining = remainingValidation;
        emit RegistryValidated(registry, nspace, remainingValidation);
        return (registry, nspace, remainingValidation);
    }

    /// @notice Casts a vote to approve a validator set change.
    /// @param _addr The target address of the validator update.
    /// @return The target address, action type, remaining votes needed, and success status.
    function validateValidator(address _addr) external onlyValidators returns (address, bool, uint32) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        if (!update.isProposed) revert Errors__Validator_Update_Not_Proposed();
        if (update.hasValidated[sender()]) revert Errors__Has_Validated();

        update.hasValidated[sender()] = true;
        update.validationCount++;

        if (update.validationCount >= update.requiredValidationCount || _recovery[sender()]) {
            update.timeLock = block.timestamp + _timeInterval;
            update.isValidated = true;
        }

        bool action = update.action;
        uint32 remainingValidation = update.requiredValidationCount - update.validationCount;
        update.remaining = remainingValidation;
        emit ValidatorValidated(_addr, update.action, remainingValidation);
        return (_addr, action, remainingValidation);
    }

    /// @notice Cancels a pending registry proposal and wipes its state.
    /// @dev Acts as a circuit breaker if a malicious proposal reaches the timelock stage.
    /// @param registry The address of the registry proposal to cancel.
    function cancelInit(address registry) external onlyValidators returns (bool) {
        Registry storage reg = _registry[registry];
        reg.hasValidated[sender()] = false;
        delete _registry[registry];
        emit RegistryInitializationCancelled(registry);
        return true;
    }

    /// @notice Cancels a pending validator update proposal.
    /// @param _addr The address of the validator in the update request.
    function cancelValidatorUpdate(address _addr) external onlyValidators returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        update.hasValidated[sender()] = false;
        delete _updateValidator[_addr];
        emit ValidatorUpdateCancelled(_addr);
        return true;
    }

    /// @notice Finalizes registry initialization once the timelock expires.
    /// @dev Calls the Singleton contract to permanently claim the namespace.
    /// @param registry The address of the validated registry.
    function executeInit(address registry) external onlyValidators returns (bool) {
        Registry storage reg = _registry[registry];
        if (!reg.isValidated || block.timestamp < reg.timeLock) {
            revert Error__Invalid_Or_Not_Enough_Time();
        }
        reg.isValidated = false;
        reg.isExecuted = true;

        emit InitializationSuccess(registry, reg.nspace);
        return _executeInit(registry, reg.nspace);
    }

    /// @notice Finalizes a validator set update once the timelock expires.
    /// @param _addr The address being added or removed.
    function executeUpdateValidator(address _addr) external onlyValidators returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        if (!update.isValidated || block.timestamp < update.timeLock) {
            revert Error__Invalid_Or_Not_Enough_Time();
        }
        update.isValidated = false;
        update.isExecuted = true;

        emit ValidatorUpdated(_addr, update.action);
        return _executeUpdateValidator(_addr, update.action);
    }

    /// @notice Manages recovery addresses that can bypass validator quorum.
    /// @custom:security Extremely sensitive. Recovery addresses should be cold-wallets.
    /// @param recovery The address to update.
    /// @param _action True to grant recovery rights, False to revoke.
    function updateRecovery(address recovery, bool _action) external onlyValidators returns (bool) {
        _recovery[recovery] = _action;
        return true;
    }

    /// @dev Internal execution logic for registry initialization.
    function _executeInit(address registry, bytes16 _nspace) internal returns (bool) {
        ISalvaSingleton(_salvaSingleton._singleton).initializeRegistry(registry, _nspace);
        return true;
    }

    /// @dev Internal execution logic for validator set modification.
    function _executeUpdateValidator(address _addr, bool _action) internal returns (bool) {
        if (_action) {
            _isValidator[_addr] = true;
            _numOfValidators++;
        } else {
            _isValidator[_addr] = false;
            _numOfValidators--;
        }
        return true;
    }
}

