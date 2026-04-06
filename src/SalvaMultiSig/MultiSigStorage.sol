// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title MultiSigStorage
 * @author cboi@Salva
 * @notice Centralized storage layout for the Salva MultiSig.
 * @dev Separated from logic to support safe UUPS upgrades. All state variables
 *      are declared here and inherited by MultiSigHelper and MultiSig.
 *
 *      Storage hygiene:
 *        · Structs use packed uint32 counters to minimize slot consumption.
 *        · A 50-slot gap is reserved at the end to allow new variables to be
 *          appended in future upgrades without corrupting existing layout.
 *        · `_timeInterval` is a constant — baked into bytecode, no slot consumed.
 */
abstract contract MultiSigStorage {
    // ─────────────────────────────────────────────────────────────────────────
    // PROTOCOL CONSTANTS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Mandatory delay between proposal validation and execution (48 hours).
     * @dev Baked into bytecode as a constant — no storage slot consumed.
     *      All registry and validator proposals must wait this duration after
     *      quorum is reached before `execute` can be called.
     *
     *      Timing diagram:
     *        [ Quorum Reached ] + [ 172,800 seconds ] = [ Earliest Execution Timestamp ]
     */
    uint128 internal constant _TIME_INTERVAL = 48 hours;

    // ─────────────────────────────────────────────────────────────────────────
    // PROTOCOL ADDRESSES
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Address of the Salva singleton proxy. Set once via `setSingletonAndFactory`.
    address internal _salvaSingleton;

    /// @notice Address of the RegistryFactory. Set once via `setSingletonAndFactory`.
    address internal _registryFactory;

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR STATE
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Total number of active validators. Used as the quorum denominator.
    uint256 internal _numOfValidators;

    /**
     * @notice Recovery address registry.
     * @dev Recovery addresses may bypass quorum and trigger the timelock immediately.
     *      Intended for emergency response only — grant sparingly.
     *
     *      Key:   address → bool (`true` = recovery privileges active)
     */
    mapping(address => bool) internal _recovery;

    /**
     * @notice Active validator set.
     *
     *      Key:   address → bool (`true` = address is an active validator)
     */
    mapping(address => bool) internal _isValidator;

    // ─────────────────────────────────────────────────────────────────────────
    // PROPOSAL STRUCTURES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice State for a single registry namespace initialization proposal.
     * @dev Packed layout minimizes SLOAD/SSTORE costs:
     *        · `registryAddress` + `nspace` + `len` fit in two slots.
     *        · Three uint32 counters share one slot.
     *        · `hasValidated` is a nested mapping — each entry is a separate slot.
     *        · `timeLock` + flags occupy the final slots.
     *
     *      Proposal lifecycle:
     *        unproposed → proposed → validated (timelock starts) → executed
     *
     * @param registryAddress         The registry clone to be initialized.
     * @param nspace                  bytes16 namespace handle (e.g. `0x4073616c766100…`).
     * @param len                     Byte length of the namespace string.
     * @param validationCount         Number of validator votes cast so far.
     * @param requiredValidationCount Quorum threshold computed at proposal time.
     * @param remaining               Votes still needed to reach quorum.
     * @param isProposed              True once the proposal has been opened.
     * @param hasValidated            Tracks which validators have already voted.
     * @param timeLock                Earliest timestamp at which execution is permitted.
     * @param isValidated             True once quorum has been reached.
     * @param isExecuted              True once the proposal has been finalized.
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

    /// @dev Maps each registry address to its active initialization proposal.
    mapping(address => Registry) internal _registry;

    /**
     * @notice State for a single validator set update proposal.
     * @dev Identical lifecycle to the Registry proposal.
     *      `action = true` adds the target; `action = false` removes it.
     *
     *      Consensus diagram:
     *        1. Validator A proposes update(address X, ADD).
     *        2. Validators sign → `remaining` decrements on each vote.
     *        3. Quorum reached → `timeLock` set to `block.timestamp + 48h`.
     *        4. 48h elapsed → `executeUpdateValidator` sets `_isValidator[X] = true`.
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

    /// @dev Maps each target address to its active validator update proposal.
    mapping(address => ValidatorUpdateRequest) internal _updateValidator;

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADE SAFETY GAP
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Reserved storage gap for future upgrades.
     *      Consuming one slot from this gap when adding a new variable in a
     *      future version prevents storage collisions with inherited contracts.
     *      Decrease the array size by 1 for each new variable added above.
     */
    uint256[50] private __gap;
}
