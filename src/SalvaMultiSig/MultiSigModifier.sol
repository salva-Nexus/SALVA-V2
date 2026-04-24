// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { MultiSigErrors } from "@MultiSigErrors/MultiSigErrors.sol";

/**
 * @title MultiSigModifier
 * @author cboi@Salva
 * @notice Access-control and pause modifiers for the Salva MultiSig governance chain.
 * @dev Provides:
 *        · `onlyValidators` — restricts to active validators and recovery addresses.
 *        · `onlyRecovery`   — restricts to recovery addresses only.
 *        · `whenNotPaused`  — gates on the MultiSig's own `_multisigPaused` flag.
 *
 *      Inherits `MultiSigErrors` (→ `Events` → `MultiSigStorage`).
 */
abstract contract MultiSigModifier is MultiSigErrors {
    // ─────────────────────────────────────────────────────────────────────────
    // MODIFIERS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Restricts the function to active validators and recovery addresses.
     * @dev Reverts with `Errors__NotAuthorized` if the caller is neither.
     */
    modifier onlyValidators() {
        _requireValidator();
        _;
    }

    /**
     * @notice Restricts the function to recovery addresses only.
     * @dev Reverts with `Errors__NotAuthorized` if the caller is not a recovery address.
     */
    modifier onlyRecovery() {
        _requireRecovery();
        _;
    }

    /**
     * @notice Reverts if the MultiSig is currently paused.
     * @dev Checks `_multisigPaused` from `MultiSigStorage`.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL CHECKS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Internal implementation for `onlyValidators`.
     *      Passes if caller is an active validator OR a recovery address.
     */
    function _requireValidator() internal view {
        address caller = msg.sender;
        if (!_isValidator[caller] && !_recovery[caller]) {
            revert Errors__NotAuthorized();
        }
    }

    /**
     * @dev Internal implementation for `onlyRecovery`.
     */
    function _requireRecovery() internal view {
        if (!_recovery[msg.sender]) {
            revert Errors__NotAuthorized();
        }
    }

    /**
     * @dev Internal implementation for `whenNotPaused`.
     */
    function _requireNotPaused() internal view {
        if (_multisigPaused) revert Errors__NotAuthorized();
    }
}
