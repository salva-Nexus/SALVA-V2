// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSigHelper} from "@MultiSigHelper/MultiSigHelper.sol";
import {Events} from "@Events/Events.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";
import {RegistryFactory} from "@RegistryFactory/RegistryFactory.sol";

/**
 * @title Salva Administrative MultiSig
 * @author cboi@Salva
 * @notice Governs all protocol-level administrative actions including namespace
 *         registration, validator set management, and backend signer rotation.
 * @dev Implements majority-based quorum consensus with a mandatory 48-hour
 *      security timelock on all proposals before execution.
 *
 *      Upgradeable via UUPS — upgrade authorization is gated behind the same
 *      validator quorum as all other administrative actions.
 *
 *      Deployment flow:
 *        1. Deploy implementation → call `initialize` through proxy.
 *        2. Call `setSingletonAndFactory` to wire up the singleton and factory.
 *        3. All subsequent governance flows through proposal → validate → execute.
 */
contract MultiSig is Initializable, UUPSUpgradeable, Events, MultiSigHelper {
    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Disables direct initialization of the implementation contract.
    ///      Initialization must go through the UUPS proxy.
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Bootstraps the MultiSig with the proxy deployer as the first validator.
     * @dev Called once through the proxy immediately after deployment.
     *      Sets the deployer as an active validator and seeds the validator count.
     *
     *      Bootstrap sequence:
     *        1. `_isValidator[sender()]` = true
     *        2. `_numOfValidators`       = 1
     */
    function initialize() external initializer {
        _isValidator[sender()] = true;
        _numOfValidators = 1;
    }

    /**
     * @notice Wires the MultiSig to the Salva singleton and registry factory.
     * @dev Write-once guard — reverts if either address has already been set.
     *      Must be called after deployment before any registry proposals can be made.
     * @param singleton  Address of the deployed Salva singleton proxy.
     * @param factory    Address of the deployed RegistryFactory.
     */
    function setSingletonAndFactory(address singleton, address factory) external onlyValidators {
        if (_salvaSingleton != address(0) && _registryFactory != address(0)) revert Errors__Already_Set();
        _salvaSingleton = singleton;
        _registryFactory = factory;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY PROPOSALS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Opens a proposal to register a new namespace and initialize its registry.
     * @dev Computes the required quorum as `floor((validators - 1) / 2) + 1` (simple majority).
     *      The namespace string is converted to `bytes16` and stored alongside the registry address.
     *
     *      Proposal state transitions:
     *        unproposed → proposed → validated (timelock) → executed
     *
     * @param _nspace   Namespace string to register (e.g. `"@coinbase"`). Max 16 bytes.
     * @param registry  Address of the registry clone to initialize under this namespace.
     * @return          Registry address, namespace string, bytes16 handle, and required quorum.
     */
    function proposeInitialization(string memory _nspace, address registry)
        public
        onlyValidators
        enforceBytes16(_nspace)
        returns (address, string memory, bytes16, uint32)
    {
        Registry storage reg = _registry[registry];
        if (reg.isProposed || reg.isExecuted) revert Errors__Registry_Init_Proposed();

        // forge-lint: disable-next-line(unsafe-typecast)
        bytes16 toBytes = bytes16(bytes(_nspace));
        uint32 required = uint32((_numOfValidators - 1) / 2) + 1;

        reg.registryAddress = registry;
        reg.nspace = toBytes;
        reg.len = bytes1(uint8(bytes(_nspace).length));
        reg.requiredValidationCount = required;
        reg.remaining = required;
        reg.isProposed = true;

        emit RegistryInitializationProposed(registry, _nspace, toBytes);
        return (registry, _nspace, toBytes, required);
    }

    /**
     * @notice Casts a validator vote to approve a pending registry proposal.
     * @dev Once the vote count reaches quorum — or if the caller is a recovery address —
     *      the 48-hour timelock is started and the proposal is marked validated.
     *      Each validator may vote only once per proposal.
     *
     * @param registry  Address of the registry whose proposal is being voted on.
     * @return          Registry address, namespace bytes16 handle, and remaining votes needed.
     */
    function validateRegistry(address registry) external onlyValidators returns (address, bytes16, uint32) {
        Registry storage reg = _registry[registry];
        address _sender = sender();
        if (!reg.isProposed) revert Errors__Registry_Init_Not_Proposed();
        if (reg.hasValidated[_sender]) revert Errors__Has_Validated();

        reg.hasValidated[_sender] = true;
        reg.validationCount++;

        if (reg.validationCount >= reg.requiredValidationCount || _recovery[_sender]) {
            reg.timeLock = block.timestamp + _TIME_INTERVAL;
            reg.isValidated = true;
        }

        uint32 remainingValidation = reg.requiredValidationCount - reg.validationCount;
        reg.remaining = remainingValidation;
        emit RegistryValidated(registry, reg.nspace, remainingValidation);
        return (registry, reg.nspace, remainingValidation);
    }

    /**
     * @notice Executes a validated registry proposal after the 48-hour timelock has elapsed.
     * @dev Calls `initializeRegistry` on the singleton, permanently binding the namespace
     *      to the registry address in singleton storage.
     *
     *      Execution diagram:
     *        [ Quorum Met ] ──(48h timelock)──► [ executeInit ] ──► [ Singleton.initializeRegistry ]
     *
     * @param registry  Address of the registry to finalize.
     * @return `true` on successful initialization.
     */
    function executeInit(address registry) external onlyValidators returns (bool) {
        Registry storage reg = _registry[registry];
        if (!reg.isValidated || block.timestamp < reg.timeLock) {
            revert Error__Invalid_Or_Not_Enough_Time();
        }
        reg.isValidated = false;
        reg.isExecuted = true;

        emit InitializationSuccess(registry, reg.nspace);
        return _executeInit(registry, reg.nspace, reg.len);
    }

    /**
     * @notice Cancels a pending registry proposal and wipes its storage.
     * @dev Circuit breaker — deletes the entire Registry struct from the mapping.
     *      The registry address can be re-proposed after cancellation.
     * @param registry  Address of the registry proposal to cancel.
     * @return `true` on successful cancellation.
     */
    function cancelInit(address registry) external onlyValidators returns (bool) {
        Registry storage reg = _registry[registry];
        reg.hasValidated[sender()] = false;
        delete _registry[registry];
        emit RegistryInitializationCancelled(registry);
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR SET MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Opens a proposal to add or remove a validator from the active set.
     * @dev Quorum is computed at proposal time from the current validator count.
     *      `action = true` adds the address; `action = false` removes it.
     * @param _addr    Target address to add or remove.
     * @param _action  `true` to add, `false` to remove.
     * @return         Target address, action flag, and required quorum.
     */
    function proposeValidatorUpdate(address _addr, bool _action)
        external
        onlyValidators
        returns (address, bool, uint32)
    {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        if (update.isProposed || update.isExecuted) revert Errors__Validator_Update_Proposed();

        uint32 required = uint32((_numOfValidators - 1) / 2) + 1;
        update.addr = _addr;
        update.action = _action;
        update.requiredValidationCount = required;
        update.remaining = required;
        update.isProposed = true;

        emit ValidatorUpdateProposed(_addr, _action);
        return (_addr, _action, required);
    }

    /**
     * @notice Casts a validator vote to approve a pending validator update proposal.
     * @dev Mirrors the registry validation flow — quorum or recovery address triggers
     *      the 48-hour timelock. Each validator may vote only once per proposal.
     * @param _addr  Target address of the validator update being voted on.
     * @return       Target address, action flag, and remaining votes needed.
     */
    function validateValidator(address _addr) external onlyValidators returns (address, bool, uint32) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        address _sender = sender();
        if (!update.isProposed) revert Errors__Validator_Update_Not_Proposed();
        if (update.hasValidated[_sender]) revert Errors__Has_Validated();

        update.hasValidated[_sender] = true;
        update.validationCount++;

        if (update.validationCount >= update.requiredValidationCount || _recovery[_sender]) {
            update.timeLock = block.timestamp + _TIME_INTERVAL;
            update.isValidated = true;
        }

        uint32 remainingValidation = update.requiredValidationCount - update.validationCount;
        update.remaining = remainingValidation;
        emit ValidatorValidated(_addr, update.action, remainingValidation);
        return (_addr, update.action, remainingValidation);
    }

    /**
     * @notice Executes a validated validator update after the 48-hour timelock has elapsed.
     * @dev Adds or removes the target address from the validator set and adjusts
     *      `_numOfValidators` accordingly, which affects future quorum calculations.
     * @param _addr  Target address of the validator update to finalize.
     * @return `true` on successful execution.
     */
    function executeUpdateValidator(address _addr) external onlyValidators returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        if (!update.isValidated || block.timestamp < update.timeLock) {
            revert Error__Invalid_Or_Not_Enough_Time();
        }
        update.isValidated = false;
        update.isExecuted = true;

        emit ValidatorUpdated(_addr, update.action);
        return _executeUpdateValidator(_addr, update.action);
    }

    /**
     * @notice Cancels a pending validator update proposal and wipes its storage.
     * @param _addr  Target address of the validator update to cancel.
     * @return `true` on successful cancellation.
     */
    function cancelValidatorUpdate(address _addr) external onlyValidators returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        update.hasValidated[sender()] = false;
        delete _updateValidator[_addr];
        emit ValidatorUpdateCancelled(_addr);
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RECOVERY & EMERGENCY CONTROLS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Grants or revokes recovery privileges for an address.
     * @dev Recovery addresses can bypass quorum and trigger the timelock immediately
     *      on any proposal. Intended for emergency response scenarios.
     * @param recovery  Address to grant or revoke recovery privileges.
     * @param _action   `true` to grant, `false` to revoke.
     * @return `true` on success.
     */
    function updateRecovery(address recovery, bool _action) external onlyValidators returns (bool) {
        _recovery[recovery] = _action;
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PROTOCOL UPGRADES & SIGNER ROTATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Triggers a UUPS upgrade on the Salva singleton implementation.
     * @dev Bypasses the standard proposal flow — validators call this directly
     *      for critical hotfixes. The singleton's own `_authorizeUpgrade` enforces
     *      that only the MultiSig can initiate this call.
     * @param newImpl  Address of the new singleton implementation.
     * @param data     Optional calldata forwarded to the new implementation post-upgrade.
     */
    function upgradeSingleton(address newImpl, bytes memory data) external onlyValidators {
        ISalvaSingleton(_salvaSingleton).upgradeToAndCall(newImpl, data);
    }

    /**
     * @notice Rotates the Salva backend signer on the RegistryFactory.
     * @dev A single call here propagates the new signer to every deployed registry
     *      clone instantly — no per-registry updates required.
     *      Use immediately if the backend signer key is suspected compromised.
     * @param newSigner  Replacement backend signer EOA.
     * @return `true` on success.
     */
    function updateSigner(address newSigner) external onlyValidators returns (bool) {
        return RegistryFactory(_registryFactory)._updateSigner(newSigner);
    }

    /**
     * @notice Deploys a new registry clone and immediately opens an initialization proposal.
     * @dev Combines `RegistryFactory.deployRegistry` and `proposeInitialization` into a
     *      single atomic transaction to reduce governance overhead when onboarding new namespaces.
     * @param namespace  Namespace string for the new registry (e.g. `"@coinbase"`).
     * @return _clone    Address of the newly deployed registry clone.
     */
    function deployAndProposeInit(string memory namespace) external onlyValidators returns (address _clone) {
        address clone = RegistryFactory(_registryFactory).deployRegistry(address(_salvaSingleton), namespace);
        if (clone != address(0)) {
            (_clone,,,) = proposeInitialization(namespace, clone);
        } else {
            _clone = clone;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Calls `initializeRegistry` on the singleton to finalize a namespace binding.
    function _executeInit(address registry, bytes16 _nspace, bytes1 _len) internal returns (bool) {
        ISalvaSingleton(_salvaSingleton).initializeRegistry(registry, _nspace, _len);
        return true;
    }

    /// @dev Adds or removes a validator and adjusts the total validator count.
    function _executeUpdateValidator(address _addr, bool _action) internal returns (bool) {
        if (_action) {
            _isValidator[_addr] = true;
            _numOfValidators++;
        } else {
            _isValidator[_addr] = false;
            _numOfValidators--;
        }
        return true;
    }

    function withdrawEth(address _receiver) external onlyValidators {
        ISalvaSingleton(_salvaSingleton).withdraw(_receiver);
    }

    /// @dev UUPS upgrade authorization — restricted to active validators.
    function _authorizeUpgrade(address newImplementation) internal override onlyValidators {}
}
