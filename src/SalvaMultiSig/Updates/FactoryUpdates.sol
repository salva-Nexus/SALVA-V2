// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IRegistryFactory } from "@IRegistryFactory/IRegistryFactory.sol";
import { StateUpdates } from "@StateUpdates/StateUpdates.sol";

/**
 * @title FactoryUpdates
 * @author cboi@Salva
 * @notice Proposal logic for updating the RegistryFactory's backend signer and
 *         BaseRegistry logic implementation address.
 * @dev Inherits `StateUpdates` (→ `MultiSigHelper` → `MultiSigModifier`
 *      → `MultiSigErrors` → `Events` → `MultiSigStorage`).
 *
 *      Both update types follow the standard propose → validate → execute lifecycle
 *      with a `_TIME_INTERVAL` timelock. The immediate `updateFactoryFee` bypasses
 *      this as fee changes are considered lower-risk.
 */
abstract contract FactoryUpdates is StateUpdates {
    // ─────────────────────────────────────────────────────────────────────────
    // SIGNER UPDATE — PROPOSE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Creates a proposal to update the authorized backend signer on a RegistryFactory.
     * @dev Quorum = `floor((N-1)/2) + 1`.
     *
     * @param proxy      The RegistryFactory proxy address to update.
     * @param newSigner  The proposed new signer address.
     * @return required  Number of validator votes required to reach quorum.
     */
    function proposeSignerUpdate(address proxy, address newSigner)
        external
        onlyValidators
        returns (address, uint256 required)
    {
        SignerUpdateProposal storage s = _signerUpdateProposal[newSigner];
        if (s.isProposed || s.isExecuted) revert Errors__SignerUpdateAlreadyProposed();

        required = (_numOfValidators - 1) / 2 + 1;
        s.newSigner = newSigner;
        s.proxy = proxy;
        s.remaining = required;
        s.isProposed = true;

        emit SignerUpdateProposed(newSigner, required);
        return (newSigner, required);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SIGNER UPDATE — VALIDATE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Records a validator's vote for a pending signer update proposal.
     * @dev Triggers the timelock if quorum is reached or the caller has recovery privileges.
     *
     * @param newSigner  The proposed new signer address identifying the proposal.
     * @return voted     `true` — confirms the vote was cast.
     * @return remaining  Votes still needed to reach quorum.
     */
    function validateSignerUpdate(address newSigner)
        external
        onlyValidators
        returns (bool voted, uint256 remaining)
    {
        SignerUpdateProposal storage s = _signerUpdateProposal[newSigner];
        if (!s.isProposed || s.isExecuted) revert Errors__SignerUpdateNotProposed();

        address caller = _msgSender();
        if (s.hasValidated[caller]) revert Errors__AlreadyValidated();

        uint256 rem = s.remaining - 1;
        s.hasValidated[caller] = true;
        s.remaining = rem;

        if (rem == 0 || _recovery[caller]) {
            s.timeLock = block.timestamp + _TIME_INTERVAL;
            s.isValidated = true;
        }

        emit SignerUpdateValidated(caller, true, rem);
        return (true, rem);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SIGNER UPDATE — CANCEL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Cancels a pending signer update proposal.
     * @param newSigner  The proposed signer address identifying the proposal to cancel.
     * @return success   `true` on successful cancellation.
     */
    function cancelSignerUpdate(address newSigner) external onlyValidators returns (bool success) {
        SignerUpdateProposal storage s = _signerUpdateProposal[newSigner];
        s.hasValidated[_msgSender()] = false;
        delete _signerUpdateProposal[newSigner];
        emit SignerUpdateCancelled(newSigner);
        success = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SIGNER UPDATE — EXECUTE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Executes a validated signer update on the RegistryFactory after timelock.
     * @dev Calls `IRegistryFactory.updateSigner(newSigner)` on the stored proxy.
     *      Recovery addresses may bypass the timelock check.
     *
     * @param newSigner  The proposed new signer address identifying the proposal.
     * @return success   `true` on successful execution.
     */
    function executeSignerUpdate(address newSigner)
        external
        onlyValidators
        whenNotPaused
        returns (bool success)
    {
        SignerUpdateProposal storage s = _signerUpdateProposal[newSigner];

        if (!_recovery[_msgSender()]) {
            if (!s.isValidated || block.timestamp < s.timeLock) {
                revert Errors__TimelockNotElapsedOrNotValidated();
            }
        }

        s.isExecuted = true;
        emit SignerUpdateExecuted(newSigner);
        success = IRegistryFactory(s.proxy).updateSigner(newSigner);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // BASEREGISTRY IMPL UPDATE — PROPOSE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Creates a proposal to update the BaseRegistry logic implementation on a
     * RegistryFactory.
     * @dev Quorum = `floor((N-1)/2) + 1`.
     *
     * @param proxy    The RegistryFactory proxy address to update.
     * @param newImpl  The proposed new BaseRegistry implementation address.
     * @return required  Number of validator votes required to reach quorum.
     */
    function proposeBaseRegistryImplUpdate(address proxy, address newImpl)
        external
        onlyValidators
        returns (address, uint256 required)
    {
        BaseRegistryImplUpdateProposal storage b = _baseRegistryImplUpdateProposal[newImpl];
        if (b.isProposed || b.isExecuted) revert Errors__BaseRegistryImplUpdateAlreadyProposed();

        required = (_numOfValidators - 1) / 2 + 1;
        b.newImpl = newImpl;
        b.proxy = proxy;
        b.remaining = required;
        b.isProposed = true;

        emit BaseRegistryImplUpdateProposed(newImpl, required);
        return (newImpl, required);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // BASEREGISTRY IMPL UPDATE — VALIDATE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Records a validator's vote for a pending BaseRegistry impl update proposal.
     *
     * @param newImpl    The proposed implementation address identifying the proposal.
     * @return voted     `true` — confirms the vote was cast.
     * @return remaining  Votes still needed to reach quorum.
     */
    function validateBaseRegistryImplUpdate(address newImpl)
        external
        onlyValidators
        returns (bool voted, uint256 remaining)
    {
        BaseRegistryImplUpdateProposal storage b = _baseRegistryImplUpdateProposal[newImpl];
        if (!b.isProposed || b.isExecuted) revert Errors__BaseRegistryImplUpdateNotProposed();

        address caller = _msgSender();
        if (b.hasValidated[caller]) revert Errors__AlreadyValidated();

        uint256 rem = b.remaining - 1;
        b.hasValidated[caller] = true;
        b.remaining = rem;

        if (rem == 0 || _recovery[caller]) {
            b.timeLock = block.timestamp + _TIME_INTERVAL;
            b.isValidated = true;
        }

        emit BaseRegistryImplUpdateValidated(caller, true, rem);
        return (true, rem);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // BASEREGISTRY IMPL UPDATE — CANCEL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Cancels a pending BaseRegistry implementation update proposal.
     * @param newImpl   The proposed implementation address identifying the proposal.
     * @return success  `true` on successful cancellation.
     */
    function cancelBaseRegistryImplUpdate(address newImpl)
        external
        onlyValidators
        returns (bool success)
    {
        BaseRegistryImplUpdateProposal storage b = _baseRegistryImplUpdateProposal[newImpl];
        b.hasValidated[_msgSender()] = false;
        delete _baseRegistryImplUpdateProposal[newImpl];
        emit BaseRegistryImplUpdateCancelled(newImpl);
        success = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // BASEREGISTRY IMPL UPDATE — EXECUTE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Executes a validated BaseRegistry impl update on the RegistryFactory after timelock.
     * @dev Calls `IRegistryFactory.updateImplementation(newImpl)` on the stored proxy.
     *
     * @param newImpl   The proposed implementation address identifying the proposal.
     * @return success  `true` on successful execution.
     */
    function executeBaseRegistryImplUpdate(address newImpl)
        external
        onlyValidators
        whenNotPaused
        returns (bool success)
    {
        BaseRegistryImplUpdateProposal storage b = _baseRegistryImplUpdateProposal[newImpl];

        if (!_recovery[_msgSender()]) {
            if (!b.isValidated || block.timestamp < b.timeLock) {
                revert Errors__TimelockNotElapsedOrNotValidated();
            }
        }

        b.isExecuted = true;
        emit BaseRegistryImplUpdateExecuted(newImpl);
        success = IRegistryFactory(b.proxy).updateImplementation(newImpl);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // FACTORY FEE — IMMEDIATE UPDATE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Immediately updates the protocol link fee on a RegistryFactory.
     * @dev No proposal or timelock required for fee changes.
     *      Restricted to validators. Requires the MultiSig to not be paused.
     *
     * @param proxy   The RegistryFactory proxy address to update.
     * @param newFee  The new fee amount in NGNs base units.
     * @return success `true` on successful update.
     */
    function updateFactoryFee(address proxy, uint256 newFee)
        external
        onlyValidators
        whenNotPaused
        returns (bool success)
    {
        success = IRegistryFactory(proxy).updateFee(newFee);
    }
}
