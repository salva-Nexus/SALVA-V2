// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Salva Governance Events
 * @notice Interface containing all events emitted by the Salva Registry and Validator governance modules.
 * @dev Use these events to track the lifecycle of naming registries and validator set updates.
 */
abstract contract Events {
    /**
     * @notice Emitted when a new namespace and registry contract are proposed.
     * @param registry The contract address of the proposed registry.
     * @param nspace The human-readable string of the namespace (e.g., "salva").
     * @param nspaceToByte The hex-encoded bytes16 version of the namespace for efficient internal lookup.
     */
    event RegistryInitializationProposed(address indexed registry, string nspace, bytes16 nspaceToByte);

    /**
     * @notice Emitted when a change to the validator set is proposed.
     * @param addr The address of the validator to be added or removed.
     * @param action True for addition, false for removal.
     */
    event ValidatorUpdateProposed(address indexed addr, bool action);

    /**
     * @notice Emitted when a validator provides a signature/vote for a registry proposal.
     * @param registry The address of the registry being validated.
     * @param nspace The namespace associated with the registry.
     * @param rem The remaining number of validations required to reach quorum.
     */
    event RegistryValidated(address indexed registry, bytes16 nspace, uint128 rem);

    /**
     * @notice Emitted when a validator provides a signature/vote for a validator update.
     * @param addr The address of the validator subject to the update.
     * @param action The type of update being voted on.
     * @param rem The remaining number of validations required to reach quorum.
     */
    event ValidatorValidated(address indexed addr, bool action, uint128 rem);

    /**
     * @notice Emitted when a pending registry proposal is cancelled by a validator.
     * @dev Triggering this event wipes the proposal state and stops the timelock.
     * @param registry The address of the cancelled registry proposal.
     */
    event RegistryInitializationCancelled(address indexed registry);

    /**
     * @notice Emitted when a pending validator update is cancelled by a validator.
     * @param addr The address of the validator whose update was cancelled.
     */
    event ValidatorUpdateCancelled(address indexed addr);

    /**
     * @notice Emitted when the timelock expires and the registry is officially activated.
     * @dev This confirms the namespace is now permanent and linked to the registry address.
     * @param registry The newly active registry contract.
     * @param nspace The finalized namespace.
     */
    event InitializationSuccess(address indexed registry, bytes16 nspace);

    /**
     * @notice Emitted when a validator update is successfully executed after the timelock.
     * @param addr The address added to or removed from the validator set.
     * @param action The type of update that was executed (true = added, false = removed).
     */
    event ValidatorUpdated(address indexed addr, bool action);
}
