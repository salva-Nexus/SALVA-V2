// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Context} from "@Context/Context.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {Errors} from "@Errors/Errors.sol";

/**
 * @title RegistryFactory
 * @author cboi@Salva
 * @notice Factory for deploying and managing Salva BaseRegistry EIP-1167 minimal proxies.
 * @dev This contract acts as the Global Configuration Layer for all deployed registries.
 * By centralizing the `signer` and `NGNs` address here, we enable "Instant Global Rotation."
 * Registries do not store these values; they perform a staticcall to this factory during
 * execution. This allows the MultiSig to update the entire ecosystem's security
 * parameters in a single transaction.
 *
 * Inherits:
 * - Context: For EIP-2771 / Meta-transaction compatibility.
 * - Errors: Standardized protocol error codes.
 */
contract RegistryFactory is Context, Errors {
    using Clones for address;

    /**
     * @notice The logic contract address that all clones delegate their logic to.
     * @dev Set once at deployment to ensure all registries follow the same byte-code logic.
     */
    address internal immutable IMPLEMENTATION;

    /**
     * @notice The protocol's administrative MultiSig address.
     * @dev The only address authorized to deploy new registries or update global parameters.
     */
    address internal immutable MULTISIG;

    /**
     * @notice The active backend EOA used to sign off-chain name link requests.
     * @dev Mutable. Stored here to allow atomic rotation across all proxies if the key is rotated.
     */
    address internal signer;

    /**
     * @notice The address of the NGN-denominated stablecoin used for protocol fees.
     * @dev Stored globally so registries can resolve the correct fee token dynamically.
     */
    address internal NGNs;

    /**
     * @dev Initializes the factory with core protocol addresses.
     * @param _impl The BaseRegistry implementation (logic) contract.
     * @param _multisig The Salva MultiSig that will govern this factory.
     * @param _signer The initial backend EOA for signature verification.
     * @param _ngns The initial NGNs token address.
     */
    constructor(address _impl, address _multisig, address _signer, address _ngns) {
        IMPLEMENTATION = _impl;
        MULTISIG = _multisig;
        signer = _signer;
        NGNs = _ngns;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ACCESS CONTROL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Throws if called by any account other than the MultiSig.
     */
    modifier onlyMultiSig() {
        _onlyMultiSig();
        _;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY DEPLOYMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Deploys a gas-efficient minimal proxy (clone) for a specific namespace.
     * @dev Deploys via EIP-1167 and triggers the `initialize` function on the clone.
     * The clone is linked to this factory instance to fetch global variables.
     * @param _singleton The Salva Singleton contract address to be used by the clone.
     * @param _namespace The string identifier for the registry.
     * @return clone The address of the newly created BaseRegistry proxy.
     */
    function deployRegistry(address _singleton, string memory _namespace)
        external
        onlyMultiSig
        returns (address clone)
    {
        clone = IMPLEMENTATION.clone();
        BaseRegistry(clone).initialize(_singleton, address(this), _namespace);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SIGNER MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Rotates the backend signer address for the entire protocol.
     * @dev Changing this value updates every registry instantly, as they read this
     * state via `getSignerAndNGNs` during every `link` operation.
     * @param _newSigner The address of the new backend EOA.
     * @return bool Returns true if the rotation was successful.
     */
    function _updateSigner(address _newSigner) external onlyMultiSig returns (bool) {
        signer = _newSigner;
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice External view for registries to fetch critical operational parameters.
     * @dev Combined into a single call to save gas during cross-contract staticcalls.
     * @return _signer The current authorized backend signer.
     * @return _ngns The current NGNs stablecoin address.
     */
    function getSignerAndNGNs() external view returns (address, address) {
        return (signer, NGNs);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Helper to enforce MultiSig-only access.
     */
    function _onlyMultiSig() internal view {
        if (sender() != MULTISIG) {
            revert Errors__Not_Authorized();
        }
    }
}
