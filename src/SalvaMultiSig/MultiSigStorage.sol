// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Singleton} from "@Singleton/Singleton.sol";

/**
 * @title Salva MultiSig Storage
 * @notice Centralized state management for the Salva MultiSig infrastructure.
 * @dev Designed with packed structs to optimize SLOAD/SSTORE operations.
 */
abstract contract MultiSigStorage {
    // ─────────────────────────────────────────────────────────────────────────
    // PROTOCOL PARAMETERS
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @notice Time Interval before Execution (48 Hours)
     * DIAGRAMMATIC ACTION:
     * [ Current Timestamp ] + [ 172,800 seconds ] = [ Earliest Execution Time ]
     * Enforces a security buffer for all registry and validator proposals.
     */
    uint128 internal constant _timeInterval = 48 hours;

    /**
     * @notice Singleton Pointer
     * DIAGRAMMATIC ACTION:
     * [ address (20 bytes) ][ isSet (1 byte) ]
     * Packed into a single 32-byte slot. _isSet prevents pointing to a new
     * Singleton once initialized (Write-Once).
     */
    struct SalvaSingleton {
        address _singleton;
        bool _isSet;
    }
    SalvaSingleton internal _salvaSingleton;

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR & RECOVERY STATE
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Tracks the quorum denominator for MultiSig consensus.
    uint256 internal _numOfValidators;

    /// @notice Recovery addresses can bypass quorum for immediate validation.
    mapping(address => bool) internal _recovery;

    /// @notice Tracks active validator permissions.
    mapping(address => bool) internal _isValidator;

    // ─────────────────────────────────────────────────────────────────────────
    // PROPOSAL STRUCTURES (The Consensus Engine)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Registry initialization proposal tracking.
     * * ─────────────────────────────────────────────────────────────────────────
     * STORAGE LAYOUT (Registry Struct)
     * ─────────────────────────────────────────────────────────────────────────
     * 1. registryAddress: The contract to be initialized.
     * 2. nspace/len:      The welded namespace handle (e.g., "@salva").
     * 3. Counters:        validationCount / requiredValidationCount / remaining.
     * (Packed into uint32s to minimize slot usage).
     * 4. hasValidated:    Nested mapping to prevent double-voting.
     * 5. timeLock:        Enforces the 48-hour delay before execution.
     * * ─────────────────────────────────────────────────────────────────────────
     * PROPOSAL FLOW:
     * Proposed -> Validating (Quorum Check) -> Validated (Timelock Start) -> Executed
     * ─────────────────────────────────────────────────────────────────────────
     */
    struct Registry {
        address registryAddress;
        bytes16 nspace;
        bytes1 len;
        uint32 validationCount;
        uint32 requiredValidationCount;
        uint32 remaining;
        bool isProposed;
        mapping(address => bool) hasValidated;
        uint256 timeLock;
        bool isValidated;
        bool isExecuted;
    }

    /// @dev Maps target registry addresses to their active proposals.
    mapping(address => Registry) internal _registry;

    /**
     * @notice Validator set update proposal tracking.
     * * ─────────────────────────────────────────────────────────────────────────
     * UPDATE LOGIC (ValidatorUpdateRequest)
     * ─────────────────────────────────────────────────────────────────────────
     * action: [ True = Add Validator ] | [ False = Remove Validator ]
     * * DIAGRAMMATIC CONSENSUS:
     * 1. Validator A Proposes Update(address X, action ADD).
     * 2. Validator B Signs -> remaining counter decrements.
     * 3. Threshold Met -> timeLock set to block.timestamp + 48h.
     * 4. 48h Passes -> finalizeUpdate() sets _isValidator[X] = true.
     * ─────────────────────────────────────────────────────────────────────────
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

    /// @dev Maps target addresses to their validator update requests.
    mapping(address => ValidatorUpdateRequest) internal _updateValidator;
}
