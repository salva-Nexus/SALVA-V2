// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Events
 * @author cboi@Salva
 * @notice Centralised event definitions for the Salva MultiSig governance modules.
 * @dev All MultiSig contracts that need to emit governance events inherit this base.
 *      Events are grouped by proposal type for easy off-chain indexing.
 */
abstract contract Events {
    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Emitted when a registry initialization proposal is created.
    event RegistryInitProposed(address indexed registry, string namespace_, uint256 requiredVotes);

    /// @notice Emitted when a validator casts a vote on a registry init proposal.
    event RegistryInitValidated(address indexed voter, bool voted, uint256 remainingVotes);

    /// @notice Emitted when a registry initialization is successfully executed.
    event RegistryInitialized(address indexed registry);

    /// @notice Emitted when a registry initialization proposal is cancelled.
    event RegistryInitCancelled(address indexed registry);

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADES
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Emitted when an upgrade proposal is created.
    event UpgradeProposed(address indexed newImpl, uint256 requiredVotes);

    /// @notice Emitted when a validator casts a vote on an upgrade proposal.
    event UpgradeValidated(address indexed voter, bool voted, uint256 remainingVotes);

    /// @notice Emitted when an upgrade proposal is cancelled.
    event UpgradeCancelled(address indexed newImpl);

    /// @notice Emitted when an upgrade is successfully executed.
    event UpgradeExecuted(address indexed newImpl);

    // ─────────────────────────────────────────────────────────────────────────
    // SIGNER UPDATES
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Emitted when a signer update proposal is created.
    event SignerUpdateProposed(address indexed newSigner, uint256 requiredVotes);

    /// @notice Emitted when a validator casts a vote on a signer update proposal.
    event SignerUpdateValidated(address indexed voter, bool voted, uint256 remainingVotes);

    /// @notice Emitted when a signer update proposal is cancelled.
    event SignerUpdateCancelled(address indexed newSigner);

    /// @notice Emitted when a signer update is successfully executed.
    event SignerUpdateExecuted(address indexed newSigner);

    // ─────────────────────────────────────────────────────────────────────────
    // BASEREGISTRY IMPLEMENTATION UPDATES
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Emitted when a BaseRegistry implementation update proposal is created.
    event BaseRegistryImplUpdateProposed(address indexed newImpl, uint256 requiredVotes);

    /// @notice Emitted when a validator casts a vote on a BaseRegistry impl update proposal.
    event BaseRegistryImplUpdateValidated(
        address indexed voter, bool voted, uint256 remainingVotes
    );

    /// @notice Emitted when a BaseRegistry implementation update proposal is cancelled.
    event BaseRegistryImplUpdateCancelled(address indexed newImpl);

    /// @notice Emitted when a BaseRegistry implementation update is successfully executed.
    event BaseRegistryImplUpdateExecuted(address indexed newImpl);

    // ─────────────────────────────────────────────────────────────────────────
    // PAUSE / UNPAUSE
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Emitted when a pause is applied to a contract or the MultiSig itself.
    event StatePaused(address indexed target);

    /// @notice Emitted when an unpause proposal is created.
    event UnpauseProposed(uint256 requiredVotes);

    /// @notice Emitted when a validator casts a vote on an unpause proposal.
    event UnpauseValidated(address indexed voter, bool voted, uint256 remainingVotes);

    /// @notice Emitted when an unpause proposal is cancelled.
    event UnpauseCancelled(address indexed proxy);

    /// @notice Emitted when an unpause is successfully executed.
    event UnpauseExecuted(address indexed proxy);

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR SET MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Emitted when a validator set update (add or remove) is proposed.
     * @param target The address of the validator to be added or removed.
     * @param action `true` = add; `false` = remove.
     */
    event ValidatorUpdateProposed(address indexed target, bool action);

    /**
     * @notice Emitted when a validator casts a vote on a validator update proposal.
     * @param voter       The voting validator's address.
     * @param voted       Always `true` — confirms vote was cast.
     * @param action      The type of update being voted on.
     * @param remaining   Votes still needed to reach quorum.
     */
    event ValidatorUpdateValidated(
        address indexed voter, bool voted, bool action, uint256 remaining
    );

    /**
     * @notice Emitted when a pending validator update proposal is cancelled.
     * @param target The address whose update was cancelled.
     */
    event ValidatorUpdateCancelled(address indexed target);

    /**
     * @notice Emitted when a validator update is successfully executed after the timelock.
     * @param target  The address added to or removed from the validator set.
     * @param action  `true` = added; `false` = removed.
     */
    event ValidatorUpdated(address indexed target, bool action);
}
