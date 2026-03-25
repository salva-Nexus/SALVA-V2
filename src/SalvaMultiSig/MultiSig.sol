// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSigModifier} from "@MultiSigModifier/MultiSigModifier.sol";
import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";
import {Events} from "@Events/Events.sol";

// @title  Salva MultiSig
// @author cboi@Salva
// @notice Administrative multisig with a 48-hour security timelock for all sensitive actions.
//
//         VALIDATOR QUORUM
//         ─────────────────
//         Required validations = floor((_numOfValidators - 1) / 2) + 1
//         Simple majority — more than half of all validators must approve.
//
//         24-HOUR TIMELOCK
//         ─────────────────
//         Once quorum is reached, a 24-hour delay is enforced before
//         executeInit or executeUpdateValidator can be called.
//         This gives validators time to detect and respond to a compromised key
//         before a malicious proposal is finalized.
//
//         RECOVERY ADDRESSES
//         ───────────────────
//         Cold-storage recovery addresses can bypass quorum and immediately
//         set the timelock. Intended for emergency use only — validator key compromise.
//         Should NEVER be used for day-to-day operations.
//
//         PROPOSAL LIFECYCLE
//         ───────────────────
//         propose → validate (repeat until quorum) → 48h timelock → execute
//         Once executed, isExecuted is permanent — no re-execution possible.
contract MultiSig is MultiSigModifier, Events {
    // Sets the deployer as the first validator with a count of 1.
    // Singleton address is set separately via setSingleton() after deployment
    // to avoid circular deployment dependency.
    constructor() {
        _isValidator[sender()] = true;
        _numOfValidators = 1;
    }

    // Sets the Salva Singleton contract address. Write-once — reverts if already set.
    // Separated from the constructor to avoid circular deployment dependency.
    // Only callable by active validators.
    // @param singleton  The address of the deployed Salva Singleton contract.
    function setSingleton(address singleton) external onlyValidators {
        SalvaSingleton storage s = _salvaSingleton;
        if (s._isSet) revert Errors__Singleton_Already_Set();
        s._singleton = singleton;
        s._isSet = true;
    }

    // Proposes a new registry namespace initialization for validator approval.
    // The proposer does NOT automatically count as the first vote — explicit
    // validateRegistry call is required from each validator including the proposer.
    // Only one active proposal per registry address at a time.
    // enforceBit128 modifier ensures the namespace fits within bytes16.
    /**
     *  @param _nspace   The namespace identifier e.g. "@coinbase". Must start with '@'.
     *  @param registry  The registry contract address to initialize.
     *  @return          The identifier as passed in and true on success.
     */
    function proposeInitialization(string memory _nspace, address registry)
        external
        onlyValidators
        enforceBytes16(_nspace)
        returns (string memory, bool)
    {
        Registry storage reg = _registry[registry];
        if (reg.isProposed || reg.isExecuted) revert Errors__Registry_Init_Proposed();

        // forge-lint: disable-next-line(unsafe-typecast)
        bytes16 toBytes = bytes16(bytes(_nspace));
        reg.registryAddress = registry;
        reg.nspace = toBytes;
        reg.requiredValidationCount = uint128((_numOfValidators - 1) / 2) + 1;
        reg.isProposed = true;

        emit RegistryInitializationProposed(registry, _nspace, toBytes);
        return (_nspace, true);
    }

    // Proposes an update to the validator set — adding or removing a validator.
    // Only one active update proposal per target address at a time.
    /**
     *  @param _addr    The address to add or remove as a validator.
     *  @param _action  true = add validator, false = remove validator.
     *  @return bool    Always true on success.
     */
    function proposeValidatorUpdate(address _addr, bool _action) external onlyValidators returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        if (update.isProposed || update.isExecuted) revert Errors__Validator_Update_Proposed();

        update.addr = _addr;
        update.action = _action;
        update.requiredValidationCount = uint128((_numOfValidators - 1) / 2) + 1;
        update.isProposed = true;

        emit ValidatorUpdateProposed(_addr, _action);
        return true;
    }

    // Casts a validation vote on a pending registry initialization proposal.
    // Once quorum is reached (or a recovery address votes), a 24-hour timelock
    // is set — executeInit cannot be called until the timelock expires.
    // Each validator may only vote once per proposal.
    /**
     *  @param registry  The registry contract address whose proposal to validate.
     *  @return bool     Always true on success.
     */
    function validateRegistry(address registry) external onlyValidators returns (bool) {
        Registry storage reg = _registry[registry];
        if (!reg.isProposed) revert Errors__Registry_Init_Not_Proposed();
        if (reg.hasValidated[sender()]) revert Errors__Has_Validated();

        reg.hasValidated[sender()] = true;
        reg.validationCount++;

        if (reg.validationCount >= reg.requiredValidationCount || _recovery[sender()]) {
            reg.timeLock = block.timestamp + _timeInterval;
            reg.isValidated = true;
        }

        uint128 remainingValidation = reg.requiredValidationCount - reg.validationCount;
        emit RegistryValidated(registry, reg.nspace, remainingValidation);
        return true;
    }

    // Casts a validation vote on a pending validator update proposal.
    // Once quorum is reached (or a recovery address votes), a 24-hour timelock
    // is set — executeUpdateValidator cannot be called until the timelock expires.
    // Each validator may only vote once per proposal.
    /**
     *  @param _addr  The target address whose validator update proposal to vote on.
     *  @return bool  Always true on success.
     */
    function validateValidator(address _addr) external onlyValidators returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        if (!update.isProposed) revert Errors__Validator_Update_Not_Proposed();
        if (update.hasValidated[sender()]) revert Errors__Has_Validated();

        update.hasValidated[sender()] = true;
        update.validationCount++;

        if (update.validationCount >= update.requiredValidationCount || _recovery[sender()]) {
            update.timeLock = block.timestamp + _timeInterval;
            update.isValidated = true;
        }

        uint128 remainingValidation = update.requiredValidationCount - update.validationCount;
        emit ValidatorValidated(_addr, update.action, remainingValidation);
        return true;
    }

    /**
     * @notice Cancels a pending registry initialization proposal.
     * @dev This serves as a security "circuit breaker." If a malicious registry is proposed or
     * validated, any validator can trigger this within the timelock window to wipe the proposal
     * state. Note: Permanent namespace protection is handled at the singleton/mapping layer,
     * so clearing this record does not allow a previously finalized namespace to be reused.
     * @param registry The contract address of the registry proposal to be purged.
     * @return bool Returns true if the cancellation was successful.
     */
    function cancelInit(address registry) external onlyValidators returns (bool) {
        delete _registry[registry];

        emit RegistryInitializationCancelled(registry);
        return true;
    }

    /**
     * @notice Cancels a pending validator addition or removal request.
     * @dev Resets the ValidatorUpdateRequest struct for the given address to its default state.
     * Used to stop unauthorized or erroneous validator changes during the 48-hour timelock.
     * @param _addr The address of the validator whose update status is being cancelled.
     * @return bool Returns true if the cancellation was successful.
     */
    function cancelValidatorUpdate(address _addr) external onlyValidators returns (bool) {
        delete _updateValidator[_addr];

        emit ValidatorUpdateCancelled(_addr);
        return true;
    }

    // Finalizes a registry initialization after the 24-hour timelock has expired.
    // Calls Singleton.initializeRegistry — the namespace is permanently claimed.
    // Sets isExecuted = true. Cannot be called again.
    /**
     *  @param registry  The address of the validated registry to initialize.
     *  @return bool     Always true on success.
     */
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

    // Finalizes a validator set update after the 24-hour timelock has expired.
    // Adds or removes the target address from the validator set and updates
    // the total validator count accordingly.
    // Sets isExecuted = true. Cannot be called again.
    /**
     *  @param _addr  The address to finalize adding or removing.
     * @return bool  Always true on success.
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

    // Adds or removes a cold-storage recovery address.
    // Recovery addresses bypass quorum — they can unilaterally trigger the timelock.
    // Intended for emergency use only when validator keys are compromised.
    // Should NEVER be used for day-to-day operations.
    /**
     *  @param recovery  The address to add or remove as a recovery address.
     *  @param _action   true = add, false = remove.
     *  @return bool     Always true on success.
     */
    function updateRecovery(address recovery, bool _action) external onlyValidators returns (bool) {
        _recovery[recovery] = _action;
        return true;
    }

    // Calls Singleton.initializeRegistry with the approved registry and namespace.
    // Internal — only called by executeInit after timelock has expired.
    function _executeInit(address registry, bytes16 _nspace) internal returns (bool) {
        ISalvaSingleton(_salvaSingleton._singleton).initializeRegistry(registry, _nspace);
        return true;
    }

    // Adds or removes a validator and updates the total count.
    // Internal — only called by executeUpdateValidator after timelock has expired.
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
