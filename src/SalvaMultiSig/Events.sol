// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Salva Governance Events
 * @notice Interface containing all events emitted by the Salva Registry and Validator governance modules.
 * @dev Use these events to track the lifecycle of naming registries and validator set updates.
 */
abstract contract Events {
    event RegistryInitialized(address indexed registry, string nspace);

    /**
     * @notice Emitted when a change to the validator set is proposed.
     * @param addr The address of the validator to be added or removed.
     * @param action True for addition, false for removal.
     */
    event ValidatorUpdateProposed(address indexed addr, bool action);

    /**
     * @notice Emitted when a validator provides a signature/vote for a validator update.
     * @param addr The address of the validator subject to the update.
     * @param action The type of update being voted on.
     * @param rem The remaining number of validations required to reach quorum.
     */
    event ValidatorValidated(address indexed addr, bool action, uint128 rem);

    /**
     * @notice Emitted when a pending validator update is cancelled by a validator.
     * @param addr The address of the validator whose update was cancelled.
     */
    event ValidatorUpdateCancelled(address indexed addr);

    /**
     * @notice Emitted when a validator update is successfully executed after the timelock.
     * @param addr The address added to or removed from the validator set.
     * @param action The type of update that was executed (true = added, false = removed).
     */
    event ValidatorUpdated(address indexed addr, bool action);
}
