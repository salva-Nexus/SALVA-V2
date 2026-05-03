// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { FactoryUpdates } from "@FactoryUpdates/FactoryUpdates.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Upgrades
 * @author cboi@Salva
 * @notice Proposal logic for UUPS upgrades of protocol contracts (Singleton, Factory, MultiSig).
 * @dev Inherits `FactoryUpdates` (→ `StateUpdates` → `MultiSigHelper` → `MultiSigModifier`
 *      → `MultiSigErrors` → `Events` → `MultiSigStorage`).
 *
 *      Upgrade proposals follow the standard propose → validate → execute lifecycle
 *      with a `_TIME_INTERVAL` timelock. When `isMultisig = true` the upgrade targets
 *      the MultiSig proxy itself via `upgradeToAndCall`; otherwise it targets an
 *      external proxy via a low-level call.
 */
abstract contract Upgrades is FactoryUpdates, UUPSUpgradeable {
    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADE — PROPOSE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Creates an upgrade proposal for a protocol contract.
     * @dev Quorum = `floor((N-1)/2) + 1`.
     *      If `isMultisig = true`, `proxy` is ignored — the MultiSig upgrades itself.
     *
     * @param proxy       The proxy contract to upgrade (ignored when `isMultisig = true`).
     * @param newImpl     The proposed new implementation address.
     * @param isMultisig  `true` if this upgrade targets the MultiSig proxy itself.
     * @return required   Number of validator votes required to reach quorum.
     */
    function proposeUpgrade(address proxy, address newImpl, bool isMultisig)
        external
        onlyValidators
        returns (address, uint256 required)
    {
        UpgradeProposal storage p = _upgradeProposal[newImpl];
        if (p.isProposed || p.isExecuted) revert Errors__UpgradeAlreadyProposed();

        required = (_numOfValidators - 1) / 2 + 1;
        p.newImpl = newImpl;
        p.remaining = required;
        p.isMultisig = isMultisig;
        p.isProposed = true;

        if (!p.isMultisig) {
            p.proxy = proxy;
        }

        emit UpgradeProposed(newImpl, required);
        return (newImpl, required);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADE — VALIDATE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Records a validator's vote for a pending upgrade proposal.
     * @dev Triggers the timelock if quorum is reached or the caller has recovery privileges.
     *
     * @param newImpl    The proposed implementation address identifying the proposal.
     * @return voted     `true` — confirms the vote was cast.
     * @return remaining  Votes still needed to reach quorum.
     */
    function validateUpgrade(address newImpl)
        external
        onlyValidators
        returns (bool voted, uint256 remaining)
    {
        UpgradeProposal storage p = _upgradeProposal[newImpl];
        if (!p.isProposed || p.isExecuted) revert Errors__UpgradeNotProposed();

        address caller = _msgSender();
        if (p.hasValidated[caller]) revert Errors__AlreadyValidated();

        uint256 rem = p.remaining - 1;
        p.hasValidated[caller] = true;
        p.remaining = rem;

        if (rem == 0 || _recovery[caller]) {
            p.timeLock = block.timestamp + _TIME_INTERVAL;
            p.isValidated = true;
        }

        emit UpgradeValidated(newImpl, true, rem);
        return (true, rem);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADE — CANCEL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Cancels a pending upgrade proposal.
     * @param newImpl   The proposed implementation address identifying the proposal.
     * @return success  `true` on successful cancellation.
     */
    function cancelUpgrade(address newImpl) external onlyValidators returns (bool success) {
        UpgradeProposal storage p = _upgradeProposal[newImpl];
        p.hasValidated[_msgSender()] = false;
        delete _upgradeProposal[newImpl];
        emit UpgradeCancelled(newImpl);
        success = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADE — EXECUTE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Executes a validated upgrade proposal after the timelock has elapsed.
     * @dev Recovery addresses may bypass the timelock check.
     *      Routes to `_executeMultisigUpgrade` or `_executeExternalUpgrade` based on
     *      the `isMultisig` flag stored in the proposal.
     *
     * @param newImpl   The proposed implementation address identifying the proposal.
     * @return success  `true` on successful execution.
     */
    function executeUpgrade(address newImpl)
        external
        onlyValidators
        whenNotPaused
        returns (bool success)
    {
        UpgradeProposal storage p = _upgradeProposal[newImpl];

        if (!_recovery[_msgSender()]) {
            if (!p.isValidated || block.timestamp < p.timeLock) {
                revert Errors__TimelockNotElapsedOrNotValidated();
            }
        }

        p.isExecuted = true;
        emit UpgradeExecuted(newImpl);

        if (p.isMultisig) {
            success = _executeMultisigUpgrade(newImpl);
        } else {
            success = _executeExternalUpgrade(p.proxy, newImpl);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Upgrades the MultiSig proxy itself via UUPS `upgradeToAndCall`.
     * @param newImpl  The new implementation address.
     * @return `true` on success.
     */
    function _executeMultisigUpgrade(address newImpl) internal returns (bool) {
        upgradeToAndCall(newImpl, "");
        return true;
    }

    /**
     * @dev Upgrades an external proxy by calling `upgradeToAndCall(newImpl, "")` on it.
     * @param proxy    The external proxy contract to upgrade.
     * @param newImpl  The new implementation address.
     * @return success `true` on success.
     */
    function _executeExternalUpgrade(address proxy, address newImpl)
        internal
        returns (bool success)
    {
        (success,) = proxy.call(_encodeUpgrade(newImpl));
        if (!success) revert Errors__UpgradeFailed();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UUPS UPGRADE AUTHORIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Authorizes a UUPS upgrade of the MultiSig itself.
     *      Restricted to active validators. Called internally by `upgradeToAndCall`.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyValidators { }
}
