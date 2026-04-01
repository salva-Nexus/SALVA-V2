// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";
import {MultiSigHelper} from "@MultiSigHelper/MultiSigHelper.sol";
import {Events} from "@Events/Events.sol";

/**
 * @title Salva Administrative MultiSig
 * @author cboi@Salva
 * @notice Manages protocol-level administrative actions including registry initialization and validator set updates.
 * @dev Implements a majority-based quorum and a mandatory security timelock.
 */
contract MultiSig is Events, MultiSigHelper {
    /**
     * @notice Initializes the MultiSig with the deployer as the first validator.
     * * ─────────────────────────────────────────────────────────────────────────
     * BOOTSTRAP PHASE
     * ─────────────────────────────────────────────────────────────────────────
     * 1. Sets _isValidator[sender()] = true.
     * 2. Sets _numOfValidators = 1.
     */
    constructor() {
        _isValidator[sender()] = true;
        _numOfValidators = 1;
    }

    /**
     * @notice Sets the Salva Singleton address.
     * @dev Can only be called once (Write-Once Guard).
     * * DIAGRAMMATIC ACTION:
     * [ MultiSig ] ──────> [ Singleton Address ]
     */
    function setSingleton(address singleton) external onlyValidators {
        SalvaSingleton storage s = _salvaSingleton;
        if (s._isSet) revert Errors__Singleton_Already_Set();
        s._singleton = singleton;
        s._isSet = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY PROPOSALS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Proposes a new registry namespace (e.g., "@coinbase") for initialization.
     * * DIAGRAMMATIC FLOW:
     * 1. Convert string handle to bytes16.
     * 2. Calculate Quorum: floor((total - 1) / 2) + 1.
     * 3. Set State: [ isProposed = true ] | [ remaining = quorum ].
     */
    function proposeInitialization(string memory _nspace, address registry)
        external
        onlyValidators
        enforceBytes16(_nspace)
        returns (address, string memory, bytes16, uint32)
    {
        Registry storage reg = _registry[registry];
        if (reg.isProposed || reg.isExecuted) revert Errors__Registry_Init_Proposed();

        // forge-lint: disable-next-line(unsafe-typecast)
        bytes16 toBytes = bytes16(bytes(_nspace));
        uint32 required = uint32((_numOfValidators - 1) / 2) + 1;

        reg.registryAddress = registry;
        reg.nspace = toBytes;
        reg.len = bytes1(uint8(bytes(_nspace).length));
        reg.requiredValidationCount = required;
        reg.remaining = required;
        reg.isProposed = true;

        emit RegistryInitializationProposed(registry, _nspace, toBytes);
        return (registry, _nspace, toBytes, required);
    }

    /**
     * @notice Casts a vote to approve a registry initialization.
     * * DIAGRAMMATIC CONSENSUS:
     * 1. Increment validationCount.
     * 2. Check if (count >= required) OR (caller is Recovery).
     * 3. Trigger Timelock: block.timestamp + 48h.
     */
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

        uint32 remainingValidation = reg.requiredValidationCount - reg.validationCount;
        reg.remaining = remainingValidation;
        emit RegistryValidated(registry, reg.nspace, remainingValidation);
        return (registry, reg.nspace, remainingValidation);
    }

    /**
     * @notice Finalizes registry initialization once the timelock expires.
     * * DIAGRAM: [ Quorum Met ] ──(48h Wait)──> [ ExecuteInit ] ──> [ Singleton.initialize ]
     */
    function executeInit(address registry) external onlyValidators returns (bool) {
        Registry storage reg = _registry[registry];
        if (!reg.isValidated || block.timestamp < reg.timeLock) {
            revert Error__Invalid_Or_Not_Enough_Time();
        }
        reg.isValidated = false;
        reg.isExecuted = true;

        emit InitializationSuccess(registry, reg.nspace);
        return _executeInit(registry, reg.nspace, reg.len);
    }

    /**
     * @notice Cancels a pending registry proposal and wipes its state.
     * * CIRCUIT BREAKER: Deletes the registry struct from storage.
     */
    function cancelInit(address registry) external onlyValidators returns (bool) {
        Registry storage reg = _registry[registry];
        reg.hasValidated[sender()] = false;
        delete _registry[registry];
        emit RegistryInitializationCancelled(registry);
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR SET UPDATES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Proposes adding or removing a validator from the set.
     */
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

    /**
     * @notice Casts a vote for a validator set change.
     */
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

        uint32 remainingValidation = update.requiredValidationCount - update.validationCount;
        update.remaining = remainingValidation;
        emit ValidatorValidated(_addr, update.action, remainingValidation);
        return (_addr, update.action, remainingValidation);
    }

    /**
     * @notice Finalizes a validator update once the timelock expires.
     */
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

    /**
     * @notice Cancels a pending validator update proposal.
     */
    function cancelValidatorUpdate(address _addr) external onlyValidators returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        update.hasValidated[sender()] = false;
        delete _updateValidator[_addr];
        emit ValidatorUpdateCancelled(_addr);
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RECOVERY & INTERNAL LOGIC
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Manages recovery addresses that can bypass validator quorum.
     * * SECURITY: recovery[address] = true allows immediate timelock triggers.
     */
    function updateRecovery(address recovery, bool _action) external onlyValidators returns (bool) {
        _recovery[recovery] = _action;
        return true;
    }

    function _executeInit(address registry, bytes16 _nspace, bytes1 _len) internal returns (bool) {
        ISalvaSingleton(_salvaSingleton._singleton).initializeRegistry(registry, _nspace, _len);
        return true;
    }

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
