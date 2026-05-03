// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IRegistryFactory } from "@IRegistryFactory/IRegistryFactory.sol";
import { ISalvaSingleton } from "@ISalvaSingleton/ISalvaSingleton.sol";
import { Upgrades } from "@Upgrades/Upgrades.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title MultiSig
 * @author cboi@Salva
 * @notice Central governance contract for the Salva protocol.
 * @dev Manages the validator set, registry initialization, protocol upgrades,
 *      signer updates, and pause/unpause operations via a majority-based
 *      voting system with a 24-hour timelock on all sensitive actions.
 *
 *      Inheritance chain (linear):
 *        MultiSigStorage → Events → MultiSigErrors → MultiSigModifier
 *          → MultiSigHelper → StateUpdates → FactoryUpdates
 *          → Upgrades → MultiSig
 *
 *      Quorum formula for all proposals: `floor((N-1)/2) + 1`
 *      This ensures >50% agreement among existing validators.
 *
 *      Recovery addresses can bypass quorum to trigger the timelock immediately —
 *      grant recovery status sparingly and only to trusted emergency actors.
 */
contract MultiSig is Initializable, Upgrades {
    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTOR
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Disables initializers on the implementation contract to prevent
     *      unauthorized direct initialization.
     */
    constructor() {
        _disableInitializers();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZER
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Initializes the MultiSig proxy with the deployer as the first validator.
     * @dev Sets `_isValidator[deployer] = true`, `_recovery[deployer] = true`,
     *      and `_numOfValidators = 1`. Cannot be called again after initialization.
     */
    function initialize() external initializer {
        _isValidator[msg.sender] = true;
        _recovery[msg.sender] = true;
        _numOfValidators = 1;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Deploys a new BaseRegistry clone and creates an initialization proposal.
     * @dev Deploys via `_deployClone` (calls `RegistryFactory.deployRegistry`), then
     *      stores the proposal. Quorum = `floor((N-1)/2) + 1`.
     *
     * @param namespace_  The namespace string for the new registry (e.g. `"@salva"`).
     *                    Must be ≤ 31 bytes.
     * @param singleton   The Salva Singleton address.
     * @param factory     The RegistryFactory proxy address.
     * @return clone       The address of the newly deployed registry clone.
     * @return packed      The packed bytes31 namespace handle.
     * @return required    Number of validator votes required.
     */
    function proposeInitRegistry(string memory namespace_, address singleton, address factory)
        external
        returns (address clone, bytes31 packed, uint256 required)
    {
        clone = _deployClone(singleton, factory, namespace_);

        InitRegistryProposal storage r = _initRegistryProposal[clone];
        if (r.isProposed || r.isExecuted) revert Errors__RegistryInitAlreadyProposed();
        if (bytes(namespace_).length > 31) revert Errors__MaxNamespaceLengthExceeded();

        required = (_numOfValidators - 1) / 2 + 1;
        packed = _toBytes31(namespace_);

        r.clone = clone;
        r.namespace_ = packed;
        r.namespaceLen = _toBytes1(bytes(namespace_).length);
        r.singleton = singleton;
        r.remaining = required;
        r.isProposed = true;

        emit RegistryInitProposed(clone, namespace_, required);
    }

    /**
     * @notice Records a validator's vote for a pending registry initialization proposal.
     * @dev Triggers the timelock if quorum is reached or the caller has recovery privileges.
     *
     * @param registry   The clone address of the registry under proposal.
     * @return voter     The address of the validator that voted.
     * @return voted     `true` — confirms the vote was cast.
     * @return remaining  Votes still needed to reach quorum.
     */
    function validateRegistryInit(address registry)
        external
        onlyValidators
        returns (address voter, bool voted, uint256 remaining)
    {
        InitRegistryProposal storage r = _initRegistryProposal[registry];
        address caller = _msgSender();

        if (!r.isProposed) revert Errors__RegistryInitNotProposed();
        if (r.hasValidated[caller]) revert Errors__AlreadyValidated();

        uint256 rem = r.remaining - 1;
        r.hasValidated[caller] = true;
        r.remaining = rem;

        if (rem == 0 || _recovery[caller]) {
            r.timeLock = block.timestamp + _TIME_INTERVAL;
            r.isValidated = true;
        }

        emit RegistryInitValidated(caller, true, rem);
        return (caller, true, rem);
    }

    /**
     * @notice Executes a validated registry initialization proposal after the timelock.
     * @dev Calls `ISalvaSingleton.initializeRegistry` to bind the registry to its namespace.
     *      Recovery addresses may bypass the timelock check.
     *
     * @param registry  The clone address of the registry to initialize.
     * @return success  `true` on successful execution.
     */
    function executeInitRegistry(address registry)
        external
        onlyValidators
        whenNotPaused
        returns (bool success)
    {
        InitRegistryProposal storage r = _initRegistryProposal[registry];

        if (!_recovery[_msgSender()]) {
            if (!r.isValidated || block.timestamp < r.timeLock) {
                revert Errors__TimelockNotElapsedOrNotValidated();
            }
        }

        r.isExecuted = true;
        emit RegistryInitialized(r.clone);

        success = _executeInitRegistry(r.singleton, r.clone, r.namespace_, r.namespaceLen);
    }

    /**
     * @notice Cancels a pending registry initialization proposal.
     * @param registry  The clone address whose proposal to cancel.
     * @return success  `true` on successful cancellation.
     */
    function cancelRegistryInit(address registry) external onlyValidators returns (bool success) {
        InitRegistryProposal storage r = _initRegistryProposal[registry];
        r.hasValidated[_msgSender()] = false;
        delete _initRegistryProposal[registry];
        emit RegistryInitCancelled(registry);
        success = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR SET MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Creates a proposal to add or remove a validator.
     * @dev Quorum = `floor((N-1)/2) + 1`. Restricted to active validators.
     *
     * @param target   The address of the target validator.
     * @param action   `true` = add; `false` = remove.
     * @return required  Number of validator votes required.
     */
    function proposeValidatorUpdate(address target, bool action)
        external
        onlyValidators
        returns (address, bool, uint256)
    {
        ValidatorUpdateProposal storage v = _validatorUpdateProposal[target];
        if (v.isProposed || v.isExecuted) revert Errors__ValidatorUpdateAlreadyProposed();

        uint256 required = (_numOfValidators - 1) / 2 + 1;
        v.addr = target;
        v.action = action;
        v.remaining = required;
        v.isProposed = true;

        emit ValidatorUpdateProposed(target, action);
        return (target, action, required);
    }

    /**
     * @notice Records a validator's vote for a pending validator update proposal.
     * @dev Triggers the timelock if quorum is reached or the caller has recovery privileges.
     *
     * @param target     The address subject to the validator update proposal.
     * @return voter     The address of the validator that voted.
     * @return voted     `true` — confirms the vote was cast.
     * @return remaining  Votes still needed to reach quorum.
     */
    function validateValidatorUpdate(address target)
        external
        onlyValidators
        returns (address voter, bool voted, uint256 remaining)
    {
        ValidatorUpdateProposal storage v = _validatorUpdateProposal[target];
        address caller = _msgSender();

        if (!v.isProposed) revert Errors__ValidatorUpdateNotProposed();
        if (v.hasValidated[caller]) revert Errors__AlreadyValidated();

        uint256 rem = v.remaining - 1;
        v.hasValidated[caller] = true;
        v.remaining = rem;

        if (rem == 0 || _recovery[caller]) {
            v.timeLock = block.timestamp + _TIME_INTERVAL;
            v.isValidated = true;
        }

        emit ValidatorUpdateValidated(caller, true, v.action, rem);
        return (caller, true, rem);
    }

    /**
     * @notice Executes a validated validator update after the timelock has elapsed.
     * @dev Updates `_isValidator` and adjusts `_numOfValidators` accordingly.
     *      Recovery addresses may bypass the timelock check.
     *
     * @param target    The address of the validator being updated.
     * @return success  `true` on successful execution.
     */
    function executeValidatorUpdate(address target)
        external
        onlyValidators
        whenNotPaused
        returns (bool success)
    {
        ValidatorUpdateProposal storage v = _validatorUpdateProposal[target];

        if (!_recovery[_msgSender()]) {
            if (!v.isValidated || block.timestamp < v.timeLock) {
                revert Errors__TimelockNotElapsedOrNotValidated();
            }
        }

        v.isExecuted = true;
        emit ValidatorUpdated(target, v.action);
        success = _applyValidatorUpdate(target, v.action);
    }

    /**
     * @notice Cancels a pending validator update proposal.
     * @param target    The address of the validator whose proposal to cancel.
     * @return success  `true` on successful cancellation.
     */
    function cancelValidatorUpdate(address target) external onlyValidators returns (bool success) {
        ValidatorUpdateProposal storage v = _validatorUpdateProposal[target];
        v.hasValidated[_msgSender()] = false;
        delete _validatorUpdateProposal[target];
        emit ValidatorUpdateCancelled(target);
        success = true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GOVERNANCE UTILITIES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Withdraws an ERC-20 token balance from the Singleton contract.
     * @dev Delegates to `ISalvaSingleton.withdraw`. Restricted to validators.
     *
     * @param singleton  The Singleton proxy address.
     * @param token      The ERC-20 token contract address.
     * @param receiver   The destination address for the withdrawn tokens.
     */
    function withdrawFromSingleton(address singleton, address token, address receiver)
        external
        onlyValidators
    {
        ISalvaSingleton(singleton).withdraw(token, receiver);
    }

    /**
     * @notice Updates the recovery status for a specified address.
     * @dev Recovery addresses can bypass standard quorum checks. Grant sparingly.
     *      Restricted to existing recovery addresses.
     *
     * @param account  The target address to modify.
     * @param action   `true` = grant recovery; `false` = revoke recovery.
     * @return success `true` on success.
     */
    function updateRecovery(address account, bool action)
        external
        onlyRecovery
        returns (bool success)
    {
        _recovery[account] = action;
        success = true;
    }

    /**
     * @notice Returns the current ERC-1967 implementation address of the MultiSig proxy.
     * @return impl The active implementation contract address.
     */
    function getImplementation() external view returns (address impl) {
        impl = ERC1967Utils.getImplementation();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Calls `ISalvaSingleton.initializeRegistry` to finalize a registry binding.
     */
    function _executeInitRegistry(
        address singleton,
        address registry,
        bytes31 namespaceHandle,
        bytes1 namespaceLength
    ) internal returns (bool) {
        return ISalvaSingleton(singleton)
            .initializeRegistry(registry, namespaceHandle, namespaceLength);
    }

    /**
     * @dev Applies a validator addition or removal and updates `_numOfValidators`.
     */
    function _applyValidatorUpdate(address target, bool action) internal returns (bool) {
        if (action) {
            _isValidator[target] = true;
            _numOfValidators++;
        } else {
            _isValidator[target] = false;
            _numOfValidators--;
        }
        return true;
    }
}
