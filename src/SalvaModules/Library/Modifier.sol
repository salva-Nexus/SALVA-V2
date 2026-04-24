// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "@Errors/Errors.sol";

/**
 * @title Modifier
 * @author cboi@Salva
 * @notice Shared modifier library for the Salva Singleton and Registry contracts.
 * @dev Provides:
 *        · EIP-1153 transient-storage reentrancy guard (`nonReentrant`).
 *        · Pause gate (`whenNotPaused`) driven by a caller-supplied bool.
 *        · MultiSig-only access control (`onlyMultiSig`).
 *
 *      Inherits `Errors` for revert selectors.
 */
abstract contract Modifier is Errors {
    // ─────────────────────────────────────────────────────────────────────────
    // REENTRANCY GUARD (EIP-1153 transient storage)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Guards against reentrant calls using transient storage slot `0x00`.
     * @dev Uses `tload` / `tstore` (EIP-1153) for gas-efficient locking that is
     *      automatically cleared at transaction end. Reverts with empty data on
     *      reentrant entry to minimise gas cost of the revert.
     *
     *      Lock diagram:
     *        Entry  → tload(0x00) == 0  → tstore(0x00, 1) → execute body
     *        Re-entry → tload(0x00) == 1 → revert(0,0)
     *        Exit   → tstore(0x00, 0)   (cleared for next call in same tx)
     */
    modifier nonReentrant() {
        assembly {
            if gt(tload(0x00), 0x00) {
                revert(0x00, 0x00)
            }
            tstore(0x00, 0x01)
        }
        _;
        // assembly {
        //     tstore(0x00, 0x00) // will comment out during deployment, this is just for test
        // }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAUSE GATE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Reverts if `state` is `true` (i.e. the protocol is paused).
     * @param state The pause flag to evaluate — typically `_paused` from `Storage`.
     */
    modifier whenNotPaused(bool state) {
        _requireNotPaused(state);
        _;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MULTISIG ACCESS CONTROL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Restricts the function to the designated MultiSig address only.
     * @param multiSig The authorised MultiSig address — typically `_multiSig` from `Storage`.
     */
    modifier onlyMultiSig(address multiSig) {
        _requireMultiSig(multiSig);
        _;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL CHECKS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Internal implementation for `onlyMultiSig`.
     *      Reverts with `Errors__NotAuthorized` if the caller is not `multiSig`.
     */
    function _requireMultiSig(address multiSig) internal view {
        if (_msgSender() != multiSig) revert Errors__NotAuthorized();
    }

    /**
     * @dev Internal implementation for `whenNotPaused`.
     *      Reverts with `Errors__NotAuthorized` if `state` is `true`.
     */
    function _requireNotPaused(bool state) internal pure {
        if (state) revert Errors__NotAuthorized();
    }
}
