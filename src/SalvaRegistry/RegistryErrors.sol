// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title RegistryErrors
 * @author cboi@Salva
 * @notice Custom error definitions scoped to the BaseRegistry contract.
 * @dev Intentionally isolated from the Singleton error chain. BaseRegistry
 *      has no dependency on Singleton storage layout — inheriting the full
 *      Singleton chain just to access error selectors would drag in
 *      `Storage`, `Context`, and all their state variables unnecessarily.
 */
abstract contract RegistryErrors {
    /// @dev Reverts when `initialize` is called on an already-initialized clone.
    error Errors__AlreadyInitialized();

    /// @dev Reverts when the recovered signer does not match the active protocol signer.
    error Errors__InvalidCallSource();
}
