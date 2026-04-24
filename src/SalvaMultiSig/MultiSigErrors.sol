// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Events } from "@Events/Events.sol";
import { MultiSigStorage } from "@MultiSigStorage/MultiSigStorage.sol";

/**
 * @title MultiSigErrors
 * @author cboi@Salva
 * @notice Centralised custom-error definitions for the Salva MultiSig governance chain.
 * @dev All MultiSig logic contracts inherit from this base. Errors mirror the
 *      protocol-wide error set in `Errors.sol` but are self-contained to keep the
 *      MultiSig inheritance chain independent of the Singleton chain.
 */
abstract contract MultiSigErrors is Events, MultiSigStorage {
    // ─────────────────────────────────────────────────────────────────────────
    // ACCESS CONTROL
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Caller is not an active validator or recovery address.
    error Errors__NotAuthorized();

    // ─────────────────────────────────────────────────────────────────────────
    // PROPOSAL LIFECYCLE
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Validator has already cast a vote on this proposal.
    error Errors__AlreadyValidated();

    /// @dev Required timelock period has not yet elapsed, or proposal is not validated.
    error Errors__TimelockNotElapsedOrNotValidated();

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev An active or executed proposal already exists for this registry.
    error Errors__RegistryInitAlreadyProposed();

    /// @dev Action requested on a registry with no active proposal.
    error Errors__RegistryInitNotProposed();

    /// @dev Supplied namespace exceeds the maximum 31-byte limit.
    error Errors__MaxNamespaceLengthExceeded();

    /// @dev EIP-1167 clone deployment failed.
    error Errors__CloneDeploymentFailed();

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev An active or executed update already exists for this validator address.
    error Errors__ValidatorUpdateAlreadyProposed();

    /// @dev Action requested on a validator update with no active proposal.
    error Errors__ValidatorUpdateNotProposed();

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADES
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev An active or executed upgrade proposal already exists for this implementation.
    error Errors__UpgradeAlreadyProposed();

    /// @dev Action requested on an upgrade with no active proposal.
    error Errors__UpgradeNotProposed();

    /// @dev Low-level `upgradeToAndCall` call failed.
    error Errors__UpgradeFailed();

    // ─────────────────────────────────────────────────────────────────────────
    // SIGNER / IMPL UPDATES
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev A signer update proposal already exists for this address.
    error Errors__SignerUpdateAlreadyProposed();

    /// @dev Action requested on a signer update with no active proposal.
    error Errors__SignerUpdateNotProposed();

    /// @dev A BaseRegistry implementation update is already proposed for this address.
    error Errors__BaseRegistryImplUpdateAlreadyProposed();

    /// @dev Action requested on a BaseRegistry impl update with no active proposal.
    error Errors__BaseRegistryImplUpdateNotProposed();

    // ─────────────────────────────────────────────────────────────────────────
    // PAUSE
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Low-level external `pauseState()` call failed.
    error Errors__ExternalPauseFailed();

    /// @dev Low-level external `unpauseState()` call failed.
    error Errors__ExternalUnpauseFailed();
}
