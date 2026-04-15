// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSigHelper} from "@MultiSigHelper/MultiSigHelper.sol";
import {Events} from "@Events/Events.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";
import {RegistryFactory} from "@RegistryFactory/RegistryFactory.sol";

/**
 * @title Salva Administrative MultiSig
 * @author cboi@Salva
 * @notice Central governance contract for managing protocol validators, singleton upgrades, and registry deployments.
 * @dev Implements a majority-based voting system with a timelock mechanism for validator updates and atomic execution for registry management.
 */
contract MultiSig is Initializable, UUPSUpgradeable, Events, MultiSigHelper {
    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Ensures the implementation contract cannot be initialized directly.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the proxy with the deployer as the initial validator.
     * @dev Sets _isValidator and _recovery for the caller and initializes _numOfValidators to 1.
     */
    function initialize() external initializer {
        _isValidator[sender()] = true;
        _recovery[sender()] = true;
        _numOfValidators = 1;
    }

    /**
     * @notice Links the MultiSig to the Salva singleton and Registry factory.
     * @dev Reverts if the singleton and factory addresses have already been set.
     * @param singleton The address of the Salva singleton contract.
     * @param factory The address of the RegistryFactory contract.
     */
    function setSingletonAndFactory(address singleton, address factory) external onlyValidators {
        if (_salvaSingleton != address(0) && _registryFactory != address(0)) revert Errors__Already_Set();
        _salvaSingleton = singleton;
        _registryFactory = factory;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR SET MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Creates a proposal to add or remove a validator.
     * @dev Calculates the required quorum based on the current validator count.
     * @param _addr The address of the target validator.
     * @param _action Boolean flag: true to add, false to remove.
     * @return The target address, the action type, and the calculated quorum required.
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
     * @notice Records a validator's vote for a pending validator update.
     * @dev Triggers a timelock if quorum is reached or if the caller is a recovery address.
     * @param _addr The address subject to the validator update proposal.
     * @return The target address, action type, and remaining votes needed.
     */
    function validateValidator(address _addr) external onlyValidators returns (address, bool, uint32) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        address _sender = sender();
        if (!update.isProposed) revert Errors__Validator_Update_Not_Proposed();
        if (update.hasValidated[_sender]) revert Errors__Has_Validated();

        update.hasValidated[_sender] = true;
        update.validationCount++;

        if (update.validationCount >= update.requiredValidationCount || _recovery[_sender]) {
            update.timeLock = block.timestamp + _TIME_INTERVAL;
            update.isValidated = true;
        }

        uint32 remainingValidation = update.requiredValidationCount - update.validationCount;
        update.remaining = remainingValidation;
        emit ValidatorValidated(_addr, update.action, remainingValidation);
        return (_addr, update.action, remainingValidation);
    }

    /**
     * @notice Finalizes a validated validator update after the timelock expires.
     * @dev Updates the validator mapping and increments/decrements the total validator count.
     * @param _addr The address of the validator being updated.
     * @return Success status of the internal update execution.
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
     * @notice Cancels a proposed validator update and clears the stored request data.
     * @param _addr The address of the validator update to be cancelled.
     * @return Boolean true upon successful cancellation.
     */
    function cancelValidatorUpdate(address _addr) external onlyValidators returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        update.hasValidated[sender()] = false;
        delete _updateValidator[_addr];
        emit ValidatorUpdateCancelled(_addr);
        return true;
    }

    /**
     * @notice Deploys a new registry and initializes it within the singleton in one call.
     * @dev Performs atomic deployment via the factory and registration in the singleton.
     * @param namespace The string namespace for the registry.
     * @return _clone The address of the newly deployed registry clone.
     */
    function deployAndInitRegistry(string memory namespace)
        external
        onlyValidators
        enforceBytes16(namespace)
        returns (address _clone)
    {
        _clone = RegistryFactory(_registryFactory).deployRegistry(address(_salvaSingleton), namespace);
        ISalvaSingleton(_salvaSingleton)
            .initializeRegistry(_clone, _toBytes16(namespace), _toBytes1(bytes(namespace).length));

        emit RegistryInitialized(_clone, namespace);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL & UTILITY
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Internal logic to modify validator state and the total number of validators.
     */
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

    /**
     * @notice Withdraws tokens from the singleton to a receiver address.
     * @param _token The address of the token to withdraw.
     * @param _receiver The destination address for the tokens.
     */
    function withdraw(address _token, address _receiver) external onlyValidators {
        ISalvaSingleton(_salvaSingleton).withdraw(_token, _receiver);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RECOVERY & EMERGENCY CONTROLS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Updates the recovery status for a specified address.
     * @dev Recovery addresses can bypass standard quorum checks in validation flows.
     * @param recovery The target address to modify.
     * @param _action Boolean flag to set or unset recovery status.
     * @return Boolean true upon success.
     */
    function updateRecovery(address recovery, bool _action) external onlyValidators returns (bool) {
        _recovery[recovery] = _action;
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PROTOCOL UPGRADES & SIGNER ROTATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Authorizes a UUPS upgrade for the Salva singleton contract.
     * @param newImpl The address of the new singleton implementation.
     * @param data Calldata for initialization or migration on the new implementation.
     */
    function upgradeSingleton(address newImpl, bytes memory data) external onlyValidators {
        ISalvaSingleton(_salvaSingleton).upgradeToAndCall(newImpl, data);
    }

    /**
     * @notice Updates the authorized signer in the RegistryFactory.
     * @param newSigner The new address to be used for signature verification.
     * @return Boolean status of the factory signer update.
     */
    function updateSigner(address newSigner) external onlyValidators returns (bool) {
        return RegistryFactory(_registryFactory)._updateSigner(newSigner);
    }

    /**
     * @dev Function that reverts if called by any non-validator account during a UUPS upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyValidators {}
}
