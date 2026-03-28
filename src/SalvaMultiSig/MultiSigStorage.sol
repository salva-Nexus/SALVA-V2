// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Singleton} from "@Singleton/Singleton.sol";

/**
 * @title Salva MultiSig Storage
 * @dev Defers logic to MultiSig.sol. Contains all state variables and proposal structures.
 */
abstract contract MultiSigStorage {
    /// @notice Time Interval before Execution
    uint128 internal constant _timeInterval = 48 hours;

    /// @notice Packs the Singleton address and a write-once guard.
    struct SalvaSingleton {
        address _singleton;
        bool _isSet;
    }
    SalvaSingleton internal _salvaSingleton;

    /// @notice Total count of active validators used for quorum math.
    uint256 internal _numOfValidators;

    /// @notice Emergency recovery addresses that bypass quorum for immediate validation.
    mapping(address => bool) internal _recovery;

    /// @notice Maps addresses to their active validator status.
    mapping(address => bool) internal _isValidator;

    /**
     * @notice Structure for tracking Registry initialization proposals.
     * @param registryAddress The target contract to be initialized.
     * @param nspace The 12-byte namespace identifier (e.g., "@salva").
     * @param validationCount Current number of approvals received.
     * @param requiredValidationCount Quorum required at the time of proposal.
     * @param isProposed Boolean flag to prevent duplicate proposals.
     * @param hasValidated Tracks individual validator votes to prevent double-voting.
     * @param timeLock The Unix timestamp after which final execution is permitted.
     * @param isValidated Flag set once quorum is reached or recovery address intervenes.
     * @param isExecuted Finality flag to prevent re-execution of the same proposal.
     */
    struct Registry {
        address registryAddress;
        bytes16 nspace;
        uint32 validationCount;
        uint32 requiredValidationCount;
        uint32 remaining;
        bool isProposed;
        mapping(address => bool) hasValidated;
        uint256 timeLock;
        bool isValidated;
        bool isExecuted;
    }

    /// @dev Internal mapping of registry addresses to their respective proposals.
    mapping(address => Registry) internal _registry;

    /**
     * @notice Structure for tracking Validator set update proposals.
     * @param addr The address to be added or removed.
     * @param action True for adding, false for removing.
     * @param validationCount Current approvals.
     * @param requiredValidationCount Quorum threshold.
     * @param isProposed Prevents redundant update requests.
     * @param hasValidated Prevents duplicate votes from the same validator.
     * @param timeLock The Unix timestamp after which the final update can be finalized.
     * @param isValidated Flag set once quorum or recovery approval is met.
     * @param isExecuted Permanent flag to mark the update as finished.
     */
    struct ValidatorUpdateRequest {
        address addr;
        bool action;
        uint32 validationCount;
        uint32 requiredValidationCount;
        uint32 remaining;
        bool isProposed;
        mapping(address => bool) hasValidated;
        uint256 timeLock;
        bool isValidated;
        bool isExecuted;
    }

    /// @dev Internal mapping of target addresses to their validator update proposals.
    mapping(address => ValidatorUpdateRequest) internal _updateValidator;
}
