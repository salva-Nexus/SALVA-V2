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
 * @dev Serves as the global configuration layer. Proxies fetch the `signer` and `NGNs` address from this
 * contract dynamically, enabling instant protocol-wide updates via a single state change.
 */
contract RegistryFactory is Context, Errors {
    using Clones for address;

    /**
     * @notice The logic implementation address for all registry clones.
     */
    address internal immutable IMPLEMENTATION;

    /**
     * @notice The authorized Salva MultiSig address for administrative control.
     */
    address internal immutable MULTISIG;

    /**
     * @notice The current backend EOA authorized to sign name link requests.
     */
    address internal signer;

    /**
     * @notice The contract address of the NGN-denominated stablecoin for fees.
     */
    address internal NGNs;

    /**
     * @notice Initializes the factory with implementation and governance addresses.
     * @param _impl The address of the BaseRegistry logic contract.
     * @param _multisig The protocol MultiSig address.
     * @param _signer The initial backend signer address.
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
     * @dev Reverts if the caller is not the MultiSig.
     */
    modifier onlyMultiSig() {
        _onlyMultiSig();
        _;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY DEPLOYMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Deploys a new minimal proxy registry for a specific namespace.
     * @dev Uses EIP-1167 for gas-efficient cloning and initializes the new proxy.
     * @param _singleton The address of the Salva Singleton.
     * @param _namespace The string name for the new registry's namespace.
     * @return clone The address of the deployed and initialized BaseRegistry proxy.
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
     * @notice Updates the protocol-wide backend signer address.
     * @dev Affects all existing and future registries that query this factory.
     * @param _newSigner The address of the new authorized backend signer.
     * @return bool True upon successful update.
     */
    function _updateSigner(address _newSigner) external onlyMultiSig returns (bool) {
        signer = _newSigner;
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Retrieves the current global signer and NGNs token addresses.
     * @dev Optimized as a single call for consumption by registries during execution.
     * @return _signer The active authorized signer address.
     * @return _ngns The current NGNs stablecoin address.
     */
    function getSignerAndNGNs() external view returns (address, address) {
        return (signer, NGNs);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Internal helper for enforcing MultiSig-only access control.
     */
    function _onlyMultiSig() internal view {
        if (sender() != MULTISIG) {
            revert Errors__Not_Authorized();
        }
    }
}
