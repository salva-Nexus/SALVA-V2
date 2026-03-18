// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Singleton} from "@Singleton/Singleton.sol";

abstract contract MultiSigStorage {
    // Packs the Singleton contract reference and a write-once guard into one slot.
    // _isSet prevents setSingleton from being called more than once.
    struct SalvaSingleton {
        Singleton _singleton;
        bool _isSet;
    }
    SalvaSingleton internal _salvaSingleton;

    // Total number of active validators.
    // Used to compute the quorum threshold for all proposals:
    // quorum = floor((_num_Of_Validators - 1) / 2) + 1
    uint256 internal _num_Of_Validators;

    // Cold-storage recovery addresses. A recovery address can unilaterally
    // execute any pending proposal without waiting for quorum — intended
    // as an emergency escape hatch if validator keys are compromised.
    // These addresses should NEVER be used for day-to-day operations.
    mapping(address => bool) internal _Recovery;

    // Tracks which addresses hold active validator status.
    // true  = active validator, may propose and vote.
    // false = not a validator (default).
    mapping(address => bool) internal _is_Validator;

    /**
     * @notice Proposal struct for a registry namespace initialization request.
     * @dev    Keyed by registry contract address in _registry.
     *         One active proposal per registry address at a time.
     *
     * @param registryAddress          The registry contract address to be initialized.
     * @param registryIdentifier       The namespace identifier e.g. "@coinbase".
     * @param validationCount          Number of validators who have approved so far.
     * @param requiredValidationCount  Quorum threshold — approvals needed to execute.
     * @param isProposed               True once proposeInitialization has been called.
     * @param hasValidated             Tracks which validators have already voted.
     * @param isExecuted               True once the proposal has been executed. Permanent.
     */
    struct Registry {
        address registryAddress;
        string registryIdentifier;
        uint128 validationCount;
        uint128 requiredValidationCount;
        bool isProposed;
        mapping(address => bool) hasValidated;
        bool isExecuted;
    }

    // Active registry initialization proposals, keyed by registry address.
    mapping(address => Registry) internal _registry;

    /**
     * @notice Proposal struct for adding or removing a validator.
     * @dev    Keyed by target validator address in _update_Validator.
     *         One active update proposal per address at a time.
     *
     * @param addr                     The address being added or removed as a validator.
     * @param action                   true = add validator, false = remove validator.
     * @param validationCount          Number of validators who have approved so far.
     * @param requiredValidationCount  Quorum threshold — approvals needed to execute.
     * @param isProposed               True once proposeValidatorUpdate has been called.
     * @param hasValidated             Tracks which validators have already voted.
     * @param isExecuted               True once the proposal has been executed. Permanent.
     */
    struct ValidatorUpdateRequest {
        address addr;
        bool action;
        uint128 validationCount;
        uint128 requiredValidationCount;
        bool isProposed;
        mapping(address => bool) hasValidated;
        bool isExecuted;
    }

    // Active validator update proposals, keyed by target address.
    mapping(address => ValidatorUpdateRequest) internal _update_Validator;
}
