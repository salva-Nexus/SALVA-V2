// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title MultiSigStorage
 * @author cboi@Salva
 * @notice Canonical storage layout for the Salva MultiSig.
 * @dev Separated from logic to guarantee safe UUPS upgrades. All state variables
 *      used by the MultiSig and its inherited modules are declared here.
 *
 *      Storage hygiene:
 *        · Structs use packed integer types where possible to minimise slot consumption.
 *        · A 50-slot gap is reserved at the end for future variable additions.
 *        · `_TIME_INTERVAL` is a constant — baked into bytecode, no slot consumed.
 */
abstract contract MultiSigStorage {
    // ─────────────────────────────────────────────────────────────────────────
    // PROTOCOL CONSTANTS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Mandatory delay between proposal validation reaching quorum and execution (24 hours).
     * @dev Baked into bytecode as a constant — no storage slot consumed.
     *      All proposal types must wait this duration after `isValidated` is set
     *      before their corresponding `execute*` function can be called.
     */
    uint128 internal constant _TIME_INTERVAL = 24 hours;

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR STATE
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Total number of active validators. Used as the quorum denominator.
    uint256 public _numOfValidators;

    /**
     * @notice Global pause flag for the MultiSig itself.
     * @dev `false` = operational; `true` = paused. Checked by `whenNotPaused`.
     */
    bool internal _multisigPaused;

    /**
     * @notice Active validator set.
     * @dev Key: address → bool (`true` = address is an active validator).
     */
    mapping(address validator => bool isActive) internal _isValidator;

    /**
     * @notice Recovery address registry.
     * @dev Recovery addresses may bypass quorum and trigger the timelock immediately.
     *      Intended for emergency response only — grant sparingly.
     *      Key: address → bool (`true` = recovery privileges active).
     */
    mapping(address account => bool hasRecovery) internal _recovery;

    // ─────────────────────────────────────────────────────────────────────────
    // PROPOSAL STRUCTURES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice State for a registry initialization proposal.
     * @dev Lifecycle: proposed → validated (quorum + timelock) → executed.
     *
     * @param clone          The deployed BaseRegistry clone address.
     * @param namespace_     The packed bytes31 namespace handle.
     * @param namespaceLen   Byte length of the namespace string.
     * @param singleton      The Salva Singleton address for this registry.
     * @param remaining      Votes still required to reach quorum.
     * @param isProposed     Whether this proposal is active.
     * @param hasValidated   Per-validator vote tracking.
     * @param timeLock       Unix timestamp after which execution is permitted.
     * @param isValidated    Whether quorum has been reached.
     * @param isExecuted     Whether this proposal has been executed.
     */
    struct InitRegistryProposal {
        address clone;
        bytes31 namespace_;
        bytes1 namespaceLen;
        address singleton;
        uint256 remaining;
        bool isProposed;
        mapping(address validator => bool voted) hasValidated;
        uint256 timeLock;
        bool isValidated;
        bool isExecuted;
    }

    /// @dev Maps each registry clone address to its active initialization proposal.
    mapping(address clone => InitRegistryProposal proposal) internal _initRegistryProposal;

    /**
     * @notice State for a UUPS upgrade proposal (Singleton, Factory, or MultiSig itself).
     *
     * @param newImpl      The proposed new implementation address.
     * @param proxy        The proxy contract to upgrade (unused when `isMultisig = true`).
     * @param isMultisig   If `true`, the upgrade targets the MultiSig proxy itself.
     * @param remaining    Votes still required to reach quorum.
     * @param isProposed   Whether this proposal is active.
     * @param hasValidated Per-validator vote tracking.
     * @param timeLock     Unix timestamp after which execution is permitted.
     * @param isValidated  Whether quorum has been reached.
     * @param isExecuted   Whether this proposal has been executed.
     */
    struct UpgradeProposal {
        address newImpl;
        address proxy;
        bool isMultisig;
        uint256 remaining;
        bool isProposed;
        mapping(address validator => bool voted) hasValidated;
        uint256 timeLock;
        bool isValidated;
        bool isExecuted;
    }

    /// @dev Maps each proposed implementation address to its active upgrade proposal.
    mapping(address newImpl => UpgradeProposal proposal) internal _upgradeProposal;

    /**
     * @notice State for a validator set update proposal (add or remove a validator).
     *
     * @dev Quorum formula: `floor((N-1)/2) + 1` ensures >50% agreement among
     *      existing validators, excluding the target of the update.
     *
     *      Consensus diagram:
     *        1. Validator A calls `proposeValidatorUpdate(X, ADD)`.
     *        2. Validators vote → `remaining` decrements on each vote.
     *        3. Quorum reached → `timeLock = block.timestamp + _TIME_INTERVAL`.
     *        4. Timelock elapsed → `executeUpdateValidator` sets `_isValidator[X] = true`.
     *
     * @param addr         The target validator address.
     * @param action       `true` = add; `false` = remove.
     * @param remaining    Votes still required to reach quorum.
     * @param isProposed   Whether this proposal is active.
     * @param hasValidated Per-validator vote tracking.
     * @param timeLock     Unix timestamp after which execution is permitted.
     * @param isValidated  Whether quorum has been reached.
     * @param isExecuted   Whether this proposal has been executed.
     */
    struct ValidatorUpdateProposal {
        address addr;
        bool action;
        uint256 remaining;
        bool isProposed;
        mapping(address validator => bool voted) hasValidated;
        uint256 timeLock;
        bool isValidated;
        bool isExecuted;
    }

    /// @dev Maps each target address to its active validator update proposal.
    mapping(address target => ValidatorUpdateProposal proposal) internal _validatorUpdateProposal;

    /**
     * @notice State for a backend signer update proposal.
     *
     * @param newSigner    The proposed new signer address.
     * @param proxy        The RegistryFactory proxy to update.
     * @param remaining    Votes still required to reach quorum.
     * @param isProposed   Whether this proposal is active.
     * @param hasValidated Per-validator vote tracking.
     * @param timeLock     Unix timestamp after which execution is permitted.
     * @param isValidated  Whether quorum has been reached.
     * @param isExecuted   Whether this proposal has been executed.
     */
    struct SignerUpdateProposal {
        address newSigner;
        address proxy;
        uint256 remaining;
        bool isProposed;
        mapping(address validator => bool voted) hasValidated;
        uint256 timeLock;
        bool isValidated;
        bool isExecuted;
    }

    /// @dev Maps each proposed signer address to its active signer update proposal.
    mapping(address newSigner => SignerUpdateProposal proposal) internal _signerUpdateProposal;

    /**
     * @notice State for a BaseRegistry implementation update proposal.
     *
     * @param newImpl      The proposed new BaseRegistry implementation address.
     * @param proxy        The RegistryFactory proxy to update.
     * @param remaining    Votes still required to reach quorum.
     * @param isProposed   Whether this proposal is active.
     * @param hasValidated Per-validator vote tracking.
     * @param timeLock     Unix timestamp after which execution is permitted.
     * @param isValidated  Whether quorum has been reached.
     * @param isExecuted   Whether this proposal has been executed.
     */
    struct BaseRegistryImplUpdateProposal {
        address newImpl;
        address proxy;
        uint256 remaining;
        bool isProposed;
        mapping(address validator => bool voted) hasValidated;
        uint256 timeLock;
        bool isValidated;
        bool isExecuted;
    }

    /// @dev Maps each proposed implementation address to its active BaseRegistry impl update
    /// proposal.
    mapping(address newImpl => BaseRegistryImplUpdateProposal proposal) internal
        _baseRegistryImplUpdateProposal;

    /**
     * @notice State for a pause/unpause proposal targeting a specific contract.
     *
     * @param mark         `0` = MultiSig internal pause; `1` = external contract pause.
     * @param remaining    Votes still required to reach quorum.
     * @param hasValidated Per-validator vote tracking.
     * @param timeLock     Unix timestamp after which execution is permitted.
     * @param isValidated  Whether quorum has been reached.
     * @param isExecuted   Whether this proposal has been executed.
     */
    struct UnpauseProposal {
        uint128 mark;
        uint128 remaining;
        mapping(address validator => bool voted) hasValidated;
        uint256 timeLock;
        bool isValidated;
        bool isExecuted;
    }

    /// @dev Maps each target proxy address to its active unpause proposal.
    mapping(address proxy => UnpauseProposal proposal) internal _unpauseProposal;

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADEABILITY PROTECTION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Reserved gap for future state variables.
     *      Decrement the array size by 1 for each new variable added above.
     */
    uint256[50] private __gap;
}
