// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { MultiSigHelper } from "@MultiSigHelper/MultiSigHelper.sol";

/**
 * @title StateUpdates
 * @author cboi@Salva
 * @notice Proposal logic for pausing and unpausing protocol contracts.
 * @dev Inherits `MultiSigHelper` (→ `MultiSigModifier` → `MultiSigErrors`
 *      → `Events` → `MultiSigStorage`).
 *
 *      Pause is immediate and requires no proposal — only validator access.
 *      Unpause follows the standard propose → validate → execute lifecycle
 *      with a `_TIME_INTERVAL` timelock after quorum is reached.
 */
abstract contract StateUpdates is MultiSigHelper {
    // ─────────────────────────────────────────────────────────────────────────
    // PAUSE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Immediately pauses the MultiSig itself or an external protocol contract.
     * @dev No proposal required — pause is an emergency action available to any validator.
     *      `mark == 0` → sets `_multisigPaused = true`.
     *      `mark == 1` → calls `pauseProtocol()` on the `proxy` address.
     *
     * @param proxy  The external contract to pause (ignored when `mark == 0`).
     * @param mark   `0` = pause MultiSig; `1` = pause external contract.
     * @return success `true` on success.
     */
    function pauseState(address proxy, uint128 mark)
        external
        onlyValidators
        returns (bool success)
    {
        if (mark == 0) {
            _multisigPaused = true;
            emit StatePaused(proxy);
        } else {
            _pauseExternalState(proxy);
        }
        success = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UNPAUSE — PROPOSE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Creates an unpause proposal for the MultiSig or an external contract.
     * @dev Quorum = `floor((N-1)/2) + 1`.
     *      `mark == 0` → unpause targets the MultiSig itself.
     *      `mark == 1` → unpause targets the external contract at `proxy`.
     *
     * @param proxy    The contract to unpause (pass `address(this)` for the MultiSig).
     * @param mark     `0` = MultiSig unpause; `1` = external contract unpause.
     * @return required  Number of validator votes required to reach quorum.
     */
    function proposeUnpause(address proxy, uint128 mark)
        external
        onlyValidators
        returns (uint256 required)
    {
        UnpauseProposal storage u = _unpauseProposal[proxy];
        required = (_numOfValidators - 1) / 2 + 1;
        u.mark = mark;
        // forge-lint: disable-next-line(unsafe-typecast)
        u.remaining = uint128(required);

        emit UnpauseProposed(required);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UNPAUSE — VALIDATE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Records a validator's vote for a pending unpause proposal.
     * @dev Triggers the timelock if quorum is reached or the caller has recovery privileges.
     *
     * @param proxy    The contract address whose unpause proposal is being voted on.
     * @return voted     `true` — confirms the vote was cast.
     * @return remaining  Votes still needed to reach quorum.
     */
    function validateUnpause(address proxy)
        external
        onlyValidators
        returns (bool voted, uint256 remaining)
    {
        UnpauseProposal storage u = _unpauseProposal[proxy];
        address caller = _msgSender();

        if (u.hasValidated[caller]) revert Errors__AlreadyValidated();

        uint128 rem = u.remaining - 1;
        u.hasValidated[caller] = true;
        u.remaining = rem;

        if (rem == 0 || _recovery[caller]) {
            u.timeLock = block.timestamp + _TIME_INTERVAL;
            u.isValidated = true;
        }

        emit UnpauseValidated(caller, true, uint256(rem));
        return (true, uint256(rem));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UNPAUSE — CANCEL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Cancels a pending unpause proposal and clears all stored state.
     * @param proxy    The contract address whose unpause proposal to cancel.
     * @return success `true` on successful cancellation.
     */
    function cancelUnpause(address proxy) external onlyValidators returns (bool success) {
        UnpauseProposal storage u = _unpauseProposal[proxy];
        u.hasValidated[_msgSender()] = false;
        delete _unpauseProposal[proxy];
        emit UnpauseCancelled(proxy);
        success = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UNPAUSE — EXECUTE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Executes a validated unpause proposal after the timelock has elapsed.
     * @dev Recovery addresses may bypass the timelock check.
     *
     * @param proxy    The contract to unpause.
     * @return success `true` on successful execution.
     */
    function executeUnpause(address proxy) external onlyValidators returns (bool success) {
        UnpauseProposal storage u = _unpauseProposal[proxy];

        if (!_recovery[_msgSender()]) {
            if (!u.isValidated || block.timestamp < u.timeLock) {
                revert Errors__TimelockNotElapsedOrNotValidated();
            }
        }

        u.isExecuted = true;
        emit UnpauseExecuted(proxy);

        if (u.mark == 0) {
            _multisigPaused = false;
        } else {
            _unpauseExternalState(proxy);
        }

        success = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Calls `pauseProtocol()` on an external contract.
     *      Reverts with `Errors__ExternalPauseFailed` if the call fails.
     */
    function _pauseExternalState(address proxy) internal {
        (bool success,) = proxy.call(_encodePause());
        if (!success) revert Errors__ExternalPauseFailed();
    }

    /**
     * @dev Calls `unpauseProtocol()` on an external contract.
     *      Reverts with `Errors__ExternalUnpauseFailed` if the call fails.
     */
    function _unpauseExternalState(address proxy) internal {
        (bool success,) = proxy.call(_encodeUnpause());
        if (!success) revert Errors__ExternalUnpauseFailed();
    }
}
