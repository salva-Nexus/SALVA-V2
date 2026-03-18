// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {MultiSigStorage} from "@MultiSigStorage/MultiSigStorage.sol";
import {MultiSigModifier} from "@MultiSigModifier/MultiSigModifier.sol";
import {Singleton} from "@Singleton/Singleton.sol";

// @title  Salva MultiSig
// @author cboi@Salva
// @notice Administrative multisig that gates access to the Singleton's
//         initializeRegistry function. No namespace can be claimed without
//         approval from a quorum of Salva validators — preventing DOS attacks
//         where squatters pre-register @coinbase, @metamask, etc. before the
//         real protocols integrate.
//
// @dev    Implemented in high-level Solidity (not assembly) because this is an
//         internal administrative contract with infrequent external interactions.
//         Gas optimization is not a priority here — correctness and auditability are.
//
//         VALIDATOR QUORUM
//         ─────────────────
//         Required validations = floor((_num_Of_Validators - 1) / 2) + 1
//         This is a simple majority — more than half of all validators must approve.
//
//         RECOVERY ADDRESSES
//         ───────────────────
//         A cold-storage recovery address is registered.
//         A recovery address can unilaterally execute any pending proposal —
//         bypassing the quorum — to recover from validator key compromise.
//         These addresses should NEVER be used for day-to-day operations.
//
//         SINGLETON REFERENCE
//         ────────────────────
//         The Singleton address is not set in the constructor — it is set once
//         post-deployment via setSingleton(), which is write-once guarded by
//         SalvaSingleton._isSet. This allows the MultiSig to be deployed before
//         the Singleton without a circular dependency.
//
//         PROPOSAL LIFECYCLE
//         ───────────────────
//         propose → validate (repeat until quorum) → auto-execute
//         Once executed, a proposal cannot be re-executed. isExecuted is permanent.
contract MultiSig is MultiSigStorage, MultiSigModifier {
    // Sets the deployer as the first validator with a count of 1.
    // Singleton address is set separately via setSingleton() after deployment.
    constructor() {
        _is_Validator[msg.sender] = true;
        _num_Of_Validators = 1;
    }

    // Sets the Salva Singleton contract address. Write-once — can only be called once.
    // Reverts if already set.
    // Separated from the constructor to avoid circular deployment dependency.
    // Only callable by active validators.
    // @param singleton  The address of the deployed Salva Singleton contract.
    function setSingleton(address singleton) external onlyValidators(_is_Validator[msg.sender]) {
        SalvaSingleton storage s = _salvaSingleton;
        if (s._isSet) revert Errors__Singleton_Already_Set();
        s._singleton = Singleton(singleton);
        s._isSet = true;
    }

    // Proposes a new registry namespace initialization for validator approval.
    // The identifier must carry the '@' prefix and fit within 12 bytes —
    // these constraints are enforced by the Singleton on execution, not here.
    // Only one active proposal per registry address is allowed at a time.
    // @param identifier    The namespace identifier to claim e.g. "@coinbase".
    // @param registry      The registry contract address to initialize.
    // @return _identifier  The identifier as passed in — returned for confirmation.
    // @return _proposed    Always true on success.
    function proposeInitialization(string memory identifier, address registry)
        external
        onlyValidators(_is_Validator[msg.sender])
        returns (string memory _identifier, bool _proposed)
    {
        Registry storage reg = _registry[registry];
        if (reg.isProposed) {
            revert Errors__Registry_Init_Proposed();
        }
        reg.registryAddress = registry;
        reg.registryIdentifier = identifier;
        reg.validationCount = 0;
        reg.requiredValidationCount = uint128((_num_Of_Validators - 1) / 2) + 1;
        reg.isProposed = true;
        reg.hasValidated[msg.sender] = false;
        reg.isExecuted = false;

        return (identifier, true);
    }

    // Proposes an update to the validator set — adding or removing a validator.
    // Only one active update proposal per target address is allowed at a time.
    // @param _addr    The address to add or remove as a validator.
    // @param _action  true = add validator, false = remove validator.
    // @return bool    Always true on success.
    function proposeValidatorUpdate(address _addr, bool _action)
        external
        onlyValidators(_is_Validator[msg.sender])
        returns (bool)
    {
        ValidatorUpdateRequest storage update = _update_Validator[_addr];
        if (update.isProposed) {
            revert Errors__Validator_Update_Proposed();
        }

        update.addr = _addr;
        update.action = _action;
        update.validationCount = 0;
        update.requiredValidationCount = uint128((_num_Of_Validators - 1) / 2) + 1;
        update.isProposed = true;
        update.hasValidated[msg.sender] = false;
        update.isExecuted = false;

        return true;
    }

    // Casts a validation vote on a pending registry initialization proposal.
    // Automatically executes the proposal once the quorum threshold is met.
    // A recovery address may execute immediately regardless of current vote count.
    // Each validator may only vote once per proposal.
    // @param registry  The registry contract address whose proposal to validate.
    // @return bool     true on successful vote or execution.
    function validateRegistry(address registry) external onlyValidators(_is_Validator[msg.sender]) returns (bool) {
        Registry storage reg = _registry[registry];
        uint128 count = reg.validationCount;
        if (!reg.isProposed) {
            revert Errors__Registry_Init_Not_Proposed();
        }
        if (reg.hasValidated[msg.sender]) {
            revert Errors__Has_Validated();
        }
        if (reg.isExecuted) {
            revert Errors__Proposal_Executed();
        }

        reg.hasValidated[msg.sender] = true;
        reg.validationCount = count + 1;

        if (reg.validationCount == reg.requiredValidationCount || _Recovery[msg.sender]) {
            reg.isExecuted = true;
            return _executeInit(registry, reg.registryIdentifier);
        }

        return true;
    }

    // Casts a validation vote on a pending validator update proposal.
    // Automatically executes the proposal once the quorum threshold is met.
    // A recovery address may execute immediately regardless of current vote count.
    // Each validator may only vote once per proposal.
    // @param _addr  The target address whose validator update proposal to vote on.
    // @return bool  true on successful vote or execution.
    function updateValidator(address _addr) external onlyValidators(_is_Validator[msg.sender]) returns (bool) {
        ValidatorUpdateRequest storage update = _update_Validator[_addr];
        uint128 count = update.validationCount;
        if (!update.isProposed) {
            revert Errors__Validator_Update_Not_Proposed();
        }
        if (update.hasValidated[msg.sender]) {
            revert Errors__Has_Validated();
        }
        if (update.isExecuted) {
            revert Errors__Proposal_Executed();
        }

        update.hasValidated[msg.sender] = true;
        update.validationCount = count + 1;

        if (update.validationCount == update.requiredValidationCount || _Recovery[msg.sender]) {
            update.isExecuted = true;
            return _executeUpdateValidator(_addr, update.action);
        }

        return true;
    }

    // Adds or removes a cold-storage recovery address.
    // Recovery addresses can unilaterally execute any pending proposal
    // without waiting for quorum — for emergency use only when validator
    // keys are compromised. Should be kept in cold storage, NEVER used
    // for day-to-day operations. Only callable by active validators.
    // @param _recovery  The address to add or remove as a recovery address.
    // @param _action    true = add recovery address, false = remove recovery address.
    // @return bool      Always true on success.
    function updateRecovery(address _recovery, bool _action)
        external
        onlyValidators(_is_Validator[msg.sender])
        returns (bool)
    {
        if (_action) {
            _Recovery[_recovery] = true;
        } else {
            _Recovery[_recovery] = false;
        }
        return true;
    }

    // Executes an approved registry initialization by calling the Singleton.
    // Internal — only called by validateRegistry once quorum is reached.
    // Forwards the registry address and identifier to Singleton.initializeRegistry.
    // @param registry     The registry contract address to initialize.
    // @param _identifier  The namespace identifier to register e.g. "@coinbase".
    // @return bool        true on success.
    function _executeInit(address registry, string memory _identifier) internal returns (bool) {
        _salvaSingleton._singleton.initializeRegistry(registry, _identifier);
        return true;
    }

    // Executes an approved validator set update.
    // Internal — only called by updateValidator once quorum is reached.
    // Adds or removes the target address from the validator set and
    // updates the total validator count accordingly.
    // @param _addr    The address to add or remove.
    // @param _action  true = add, false = remove.
    // @return bool    true on success.
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
