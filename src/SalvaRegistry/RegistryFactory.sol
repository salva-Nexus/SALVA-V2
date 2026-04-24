// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Context } from "@Context/Context.sol";
import { IBaseRegistry } from "@IBaseRegistry/IBaseRegistry.sol";
import { IRegistryFactory } from "@IRegistryFactory/IRegistryFactory.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title RegistryFactory
 * @author cboi@Salva
 * @notice Factory for deploying and managing Salva BaseRegistry EIP-1167 minimal proxies.
 *         See {IRegistryFactory} for full interface documentation.
 *
 * @dev Serves as the global configuration layer for all registry clones.
 *      Clones fetch `signer` and `ngns` from this contract dynamically on every
 *      `link` call, enabling instant protocol-wide updates via a single state change
 *      without re-deploying any existing registries.
 *
 *      The `whenNotPaused` guard on `getSignerAndNGNs` and `getFee` provides an
 *      atomic kill-switch: pausing the Factory immediately halts linking across
 *      all registries.
 */
contract RegistryFactory is Initializable, UUPSUpgradeable, Context {
    using Clones for address;

    // ─────────────────────────────────────────────────────────────────────────
    // ERRORS
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Caller is not the authorised MultiSig, or the Factory is paused.
    error Errors__NotAuthorized();

    // ─────────────────────────────────────────────────────────────────────────
    // STATE
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev The BaseRegistry logic implementation used for EIP-1167 clone deployment.
    address internal _implementation;

    /// @dev The authorized Salva MultiSig address for all administrative operations.
    address internal _multiSig;

    /// @dev The backend EOA authorized to sign name link requests.
    address internal _signer;

    /// @dev The NGNs stablecoin contract address used for link fee collection.
    address internal _ngns;

    /// @dev Global pause flag. `false` = operational; `true` = paused.
    bool internal _paused;

    /// @dev The current protocol link fee in NGNs base units.
    uint256 internal _fee;

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADEABILITY PROTECTION
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Reserved gap for future state variables to prevent storage collisions.
    uint256[50] private __gap;

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTOR
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Disables initializers on the implementation contract.
    constructor() {
        _disableInitializers();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZER
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Initializes the RegistryFactory proxy.
     * @dev Called once during proxy deployment.
     *
     * @param impl      The BaseRegistry logic implementation address.
     * @param multiSig  The Salva MultiSig address for governance.
     * @param signer    The backend EOA authorized to sign link requests.
     * @param ngns      The NGNs stablecoin contract address.
     */
    function initialize(address impl, address multiSig, address signer, address ngns)
        public
        initializer
    {
        _implementation = impl;
        _multiSig = multiSig;
        _signer = signer;
        _ngns = ngns;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY DEPLOYMENT
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev See {IRegistryFactory} for full documentation.
    function deployRegistry(address singleton, address factory, string calldata namespace_)
        external
        onlyMultiSig
        returns (address clone)
    {
        clone = _implementation.clone();
        IBaseRegistry(clone).initialize(singleton, factory, namespace_);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ADMINISTRATIVE UPDATES
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev See {IRegistryFactory} for full documentation.
    function updateSigner(address newSigner) external onlyMultiSig returns (bool success) {
        _signer = newSigner;
        success = true;
    }

    /// @dev See {IRegistryFactory} for full documentation.
    function updateImplementation(address newImpl) external onlyMultiSig returns (bool success) {
        _implementation = newImpl;
        success = true;
    }

    /// @dev See {IRegistryFactory} for full documentation.
    function updateFee(uint256 newFee) external onlyMultiSig returns (bool success) {
        _fee = newFee;
        success = true;
    }

    /**
     * @notice Pauses the RegistryFactory, halting all registry link operations.
     * @dev Sets `_paused = true`. `getSignerAndNGNs` and `getFee` will revert
     *      while paused, atomically blocking all BaseRegistry `link` calls.
     */
    function pauseProtocol() external onlyMultiSig {
        _paused = true;
    }

    /**
     * @notice Resumes normal RegistryFactory operation after a pause.
     * @dev Sets `_paused = false`.
     */
    function unpauseProtocol() external onlyMultiSig {
        _paused = false;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev See {IRegistryFactory} for full documentation.
    function getSignerAndNGNs() external view whenNotPaused returns (address signer, address ngns) {
        signer = _signer;
        ngns = _ngns;
    }

    /// @dev See {IRegistryFactory} for full documentation.
    function getFee() external view whenNotPaused returns (uint256 fee) {
        fee = _fee;
    }

    /**
     * @notice Returns the current BaseRegistry logic implementation address.
     * @return The implementation address used for new clone deployments.
     */
    function getBaseRegistryImplementation() external view returns (address) {
        return _implementation;
    }

    /**
     * @notice Returns the current ERC-1967 implementation address of this proxy.
     * @return impl The active RegistryFactory implementation address.
     */
    function getImplementation() external view returns (address impl) {
        impl = ERC1967Utils.getImplementation();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MODIFIERS
    // ─────────────────────────────────────────────────────────────────────────

    modifier onlyMultiSig() {
        if (_msgSender() != _multiSig) revert Errors__NotAuthorized();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Errors__NotAuthorized();
        _;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UUPS UPGRADE AUTHORIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Authorizes a UUPS upgrade. Restricted to the MultiSig.
     * @param newImplementation The address of the proposed new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyMultiSig { }
}
