// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Storage } from "@Storage/Storage.sol";

/**
 * @title Errors
 * @author cboi@Salva
 * @notice Centralised custom-error definitions for the Salva Singleton and Registry contracts.
 * @dev All Singleton-chain contracts — modules, registries, and the Singleton itself —
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

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY / NAMESPACE
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Caller is not a registered registry contract.
    error Errors__NotRegistered();

    /// @dev Attempted to re-initialize a previously finalized registry or namespace.
    error Errors__DoubleInitialization();

    /// @dev Supplied namespace or address is invalid, too long, or missing the `@` prefix.
    error Errors__InvalidAddressOrNamespaceFormat();

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
}
