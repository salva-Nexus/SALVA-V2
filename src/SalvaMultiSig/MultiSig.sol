// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {MultiSigStorage} from "@MultiSigStorage/MultiSigStorage.sol";
import {MultiSigModifier} from "@MultiSigModifier/MultiSigModifier.sol";
import {Singleton} from "@Singleton/Singleton.sol";

/**
 * @title Salva MultiSig
 * @author cboi@Salva
 * @notice Administrative multisig with a 24-hour security timelock for all sensitive actions.
 * @dev Proposals require a majority quorum. Once quorum is reached, a 24-hour delay is enforced
 * before executeInit or executeUpdateValidator can be called.
 */
contract MultiSig is MultiSigStorage, MultiSigModifier {
    /**
     * @notice Initializes the contract with the deployer as the first validator.
     */
    constructor() {
        _is_Validator[msg.sender] = true;
        _num_Of_Validators = 1;
    }

    /**
     * @notice Sets the Singleton address. Can only be performed once.
     * @param singleton The address of the Salva Singleton contract.
     */
    function setSingleton(address singleton) external onlyValidators(_is_Validator[msg.sender]) {
        SalvaSingleton storage s = _salvaSingleton;
        if (s._isSet) revert Errors__Singleton_Already_Set();
        s._singleton = Singleton(singleton);
        s._isSet = true;
    }

    /**
     * @notice Proposes a new registry for a specific namespace.
     * @param _nspace The string identifier (must include '@').
     * @param registry The address of the registry contract.
     */
    function proposeInitialization(string memory _nspace, address registry)
        external
        onlyValidators(_is_Validator[msg.sender])
        enforceBit128(_nspace)
        returns (string memory, bool)
    {
        Registry storage reg = _registry[registry];
        if (reg.isProposed || reg.isExecuted) revert Errors__Registry_Init_Proposed();

        reg.registryAddress = registry;
        reg.nspace = bytes16(bytes(_nspace));
        reg.requiredValidationCount = uint128((_num_Of_Validators - 1) / 2) + 1;
        reg.isProposed = true;

        return (_nspace, true);
    }

    /**
     * @notice Proposes adding or removing a validator from the set.
     * @param _addr Target address for the status change.
     * @param _action True to add, false to remove.
     */
    function proposeValidatorUpdate(address _addr, bool _action)
        external
        onlyValidators(_is_Validator[msg.sender])
        returns (bool)
    {
        ValidatorUpdateRequest storage update = _update_Validator[_addr];
        if (update.isProposed || update.isExecuted) revert Errors__Validator_Update_Proposed();

        update.addr = _addr;
        update.action = _action;
        update.requiredValidationCount = uint128((_num_Of_Validators - 1) / 2) + 1;
        update.isProposed = true;

        return true;
    }

    /**
     * @notice Casts a vote to validate a registry. Reaching quorum triggers a 24h timelock.
     * @param registry The registry address to validate.
     */
    function validateRegistry(address registry) external onlyValidators(_is_Validator[msg.sender]) returns (bool) {
        Registry storage reg = _registry[registry];
        if (!reg.isProposed) revert Errors__Registry_Init_Not_Proposed();
        if (reg.hasValidated[msg.sender]) revert Errors__Has_Validated();

        reg.hasValidated[msg.sender] = true;
        reg.validationCount++;

        if (reg.validationCount >= reg.requiredValidationCount || _Recovery[msg.sender]) {
            reg.timeLock = block.timestamp + 24 hours;
            reg.isValidated = true;
        }

        return true;
    }

    /**
     * @notice Casts a vote for a validator update. Reaching quorum triggers a 24h timelock.
     * @param _addr The address being updated.
     */
    function updateValidator(address _addr) external onlyValidators(_is_Validator[msg.sender]) returns (bool) {
        ValidatorUpdateRequest storage update = _update_Validator[_addr];
        if (!update.isProposed) revert Errors__Validator_Update_Not_Proposed();
        if (update.hasValidated[msg.sender]) revert Errors__Has_Validated();

        update.hasValidated[msg.sender] = true;
        update.validationCount++;

        if (update.validationCount >= update.requiredValidationCount || _Recovery[msg.sender]) {
            update.timeLock = block.timestamp + 24 hours;
            update.isValidated = true;
        }

        return true;
    }

    /**
     * @notice Finalizes a registry initialization after the 24-hour timelock has expired.
     * @param registry Address of the validated registry.
     */
    function executeInit(address registry) external onlyValidators(_is_Validator[msg.sender]) returns (bool) {
        Registry storage reg = _registry[registry];
        if (!reg.isValidated || block.timestamp < reg.timeLock) {
            revert Error__Invalid_Or_Not_Enough_Time();
        }
        reg.isValidated = false;
        reg.isExecuted = true;
        return _executeInit(registry, reg.nspace);
    }

    /**
     * @notice Finalizes a validator set update after the 24-hour timelock has expired.
     * @param _addr The address to be added or removed.
     */
    function executeUpdateValidator(address _addr) external onlyValidators(_is_Validator[msg.sender]) returns (bool) {
        ValidatorUpdateRequest storage update = _update_Validator[_addr];
        if (!update.isValidated || block.timestamp < update.timeLock) {
            revert Error__Invalid_Or_Not_Enough_Time();
        }
        update.isValidated = false;
        update.isExecuted = true;
        return _executeUpdateValidator(_addr, update.action);
    }

    /**
     * @notice Manages recovery addresses for emergency quorum bypass.
     * @param _recovery Target recovery address.
     * @param _action True to add, false to remove.
     */
    function updateRecovery(address _recovery, bool _action)
        external
        onlyValidators(_is_Validator[msg.sender])
        returns (bool)
    {
        _Recovery[_recovery] = _action;
        return true;
    }

    function _executeInit(address registry, bytes16 _nspace) internal returns (bool) {
        _salvaSingleton._singleton.initializeRegistry(registry, _nspace);
        return true;
    }

    function _executeUpdateValidator(address _addr, bool _action) internal returns (bool) {
        if (_action) {
            _is_Validator[_addr] = true;
            _num_Of_Validators++;
        } else {
            _is_Validator[_addr] = false;
            _num_Of_Validators--;
        }
        return true;
    }
}
