// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Storage } from "@Storage/Storage.sol";

/**
 * @title Errors
 * @author cboi@Salva
 * @notice Centralised custom-error definitions for the entire Salva protocol.
 * @dev All contracts — Singleton modules, MultiSig modules, and registries —
 *      inherit from this base so that error selectors are consistent and
 *      de-duplicated across the protocol.
 *
 *      Inherits `Storage` to sit correctly at the base of the Singleton chain
 *      while remaining the single source of truth for error types.
 */
abstract contract Errors is Storage {
    // ─────────────────────────────────────────────────────────────────────────
    // GENERAL / ACCESS CONTROL
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Caller is not authorised to perform this action.
    error Errors__NotAuthorized();

    /// @dev Supplied address is the zero address.
    error Errors__InvalidAddress();

    /// @dev Input value must not be zero or empty.
    error Errors__InvalidValues();

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY / NAMESPACE
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Caller is not a registered registry contract.
    error Errors__NotRegistered();

    /// @dev An active or completed proposal already exists for this registry.
    error Errors__RegistryInitAlreadyProposed();

    /// @dev Action requested on a registry with no active proposal.
    error Errors__RegistryInitNotProposed();

    /// @dev Attempted to re-initialize a previously finalized registry or namespace.
    error Errors__DoubleInitialization();

    /// @dev Supplied namespace or address is invalid, too long, or missing the `@` prefix.
    error Errors__InvalidAddressOrNamespaceFormat();

    /// @dev Registry clone has already been initialized — duplicate initialize call rejected.
    error Errors__AlreadyInitialized();

    /// @dev EIP-1167 clone deployment failed.
    error Errors__CloneDeploymentFailed();

    // ─────────────────────────────────────────────────────────────────────────
    // NAME VALIDATION
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Alias exceeds the maximum allowed length of 32 bytes.
    error Errors__MaxNameLengthExceeded();

    /// @dev Character is not in the permitted set (a–z, 2–9, `_`).
    error Errors__InvalidCharacter();

    /// @dev An alias may contain at most one underscore.
    error Errors__MaxOneUnderscoreAllowed();

    /// @dev Calldata length field does not match actual payload — possible manipulation.
    error Errors__InvalidLength();

    /// @dev A sub-name segment on either side of `_` must not be empty.
    error Errors__InvalidSubNameFormat();

    // ─────────────────────────────────────────────────────────────────────────
    // ALIAS STORAGE
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev This alias is already registered in the namespace.
    error Errors__NameTaken();

    /// @dev The caller does not own the alias they are attempting to modify.
    error Errors__InvalidSender();

    /// @dev An alias must resolve to exactly one data type.
    error Errors__OnlyOneLinkToData();

    /// @dev Only one value may be supplied.
    error Errors__OnlyOneValue();

    // ─────────────────────────────────────────────────────────────────────────
    // FEES
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Attached fee is below the required minimum.
    error Errors__NotEnoughFee();

    // ─────────────────────────────────────────────────────────────────────────
    // SIGNATURE VERIFICATION
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Signature recovery did not match the authorised Salva backend signer.
    error Errors__InvalidCallSource();

    // ─────────────────────────────────────────────────────────────────────────
    // MULTISIG — VALIDATOR GOVERNANCE
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Validator has already cast a vote on this proposal.
    error Errors__AlreadyValidated();

    /// @dev An active or completed update already exists for this validator address.
    error Errors__ValidatorUpdateAlreadyProposed();

    /// @dev Action requested on a validator update with no active proposal.
    error Errors__ValidatorUpdateNotProposed();

    // ─────────────────────────────────────────────────────────────────────────
    // MULTISIG — UPGRADES
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev An active or executed upgrade proposal already exists for this implementation.
    error Errors__UpgradeAlreadyProposed();

    /// @dev Action requested on an upgrade with no active proposal.
    error Errors__UpgradeNotProposed();

    /// @dev Low-level `upgradeToAndCall` call failed.
    error Errors__UpgradeFailed();

    // ─────────────────────────────────────────────────────────────────────────
    // MULTISIG — SIGNER / IMPL UPDATES
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
    // MULTISIG — TIMELOCK / PAUSE
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Required timelock period has not yet elapsed, or proposal is not validated.
    error Errors__TimelockNotElapsedOrNotValidated();

    /// @dev Low-level external `pauseState()` call failed.
    error Errors__ExternalPauseFailed();

    /// @dev Low-level external `unpauseState()` call failed.
    error Errors__ExternalUnpauseFailed();

    /// @dev The singleton reference is immutable once set.
    error Errors__AlreadySet();

    /// @dev Low-level singleton call failed.
    error Errors__CallFailed();
}
