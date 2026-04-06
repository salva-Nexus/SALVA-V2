// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Context} from "@Context/Context.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {Errors} from "@Errors/Errors.sol";

/**
 * @title RegistryFactory
 * @author cboi@Salva
 * @notice Deploys and manages all BaseRegistry clone instances for the Salva protocol.
 * @dev Uses EIP-1167 minimal proxy clones for gas-efficient registry deployment.
 *      Acts as the single source of truth for the backend signer and Chainlink
 *      data feed — all clones read these values from the factory rather than
 *      storing them locally, allowing a single MultiSig transaction to propagate
 *      a signer rotation across every deployed registry instantly.
 *
 *      Access control: only the immutable MultiSig address may deploy registries
 *      or rotate the signer.
 */
contract RegistryFactory is Context, Errors {
    using Clones for address;

    /// @notice Address of the BaseRegistry implementation all clones delegate to.
    address internal immutable IMPLEMENTATION;

    /// @notice The Salva MultiSig contract — sole authority over factory operations.
    address internal immutable MULTISIG;

    /// @notice Chainlink ETH/USD price feed used to compute the live $1 registration fee.
    /// @dev Immutable — set once at construction and shared across all clones.
    address internal immutable DATA_FEED;

    /// @notice Salva backend EOA whose signature must accompany every registry link call.
    /// @dev Mutable — can be rotated by the MultiSig via `_updateSigner` if compromised.
    address internal signer;

    /**
     * @param _impl      Address of the deployed BaseRegistry implementation contract.
     * @param _multisig  Address of the Salva MultiSig — only caller authorised to deploy
     *                   registries and rotate the signer.
     * @param _dataFeed  Chainlink ETH/USD price feed address.
     * @param _signer    Initial Salva backend signer EOA.
     */
    constructor(address _impl, address _multisig, address _dataFeed, address _signer) {
        IMPLEMENTATION = _impl;
        MULTISIG = _multisig;
        DATA_FEED = _dataFeed;
        signer = _signer;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ACCESS CONTROL
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Reverts if the caller is not the Salva MultiSig.
    modifier onlyMultiSig() {
        _onlyMultiSig();
        _;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY DEPLOYMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Deploys a new BaseRegistry clone and initializes it for a given namespace.
     * @dev Clones the implementation via EIP-1167 and calls `initialize` on the
     *      resulting instance. The factory address is passed so the clone can read
     *      `signer` and `DATA_FEED` from a single source rather than storing them locally.
     * @param _singleton  Address of the Salva singleton all registries route calls through.
     * @param _namespace  Human-readable namespace string for this registry (e.g. "@coinbase").
     * @return clone      Address of the newly deployed registry clone.
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
     * @notice Rotates the Salva backend signer across all deployed registries atomically.
     * @dev Because all clones read `signer` from this factory, a single call here
     *      propagates the change to every registry with no per-clone updates required.
     *      Callable only by the MultiSig — intended for use after a key compromise.
     * @param _newSigner  Replacement backend signer EOA.
     * @return `true` on success.
     */
    function _updateSigner(address _newSigner) external onlyMultiSig returns (bool) {
        signer = _newSigner;
        return true;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the current backend signer and Chainlink data feed in one call.
     * @dev Called by every BaseRegistry clone inside `link` to avoid storing these
     *      values per-clone and to ensure signer rotations take effect immediately.
     * @return _signer   The active Salva backend signer EOA.
     * @return _dataFeed The Chainlink ETH/USD price feed address.
     */
    function getSignerAndDataFeed() external view returns (address _signer, address _dataFeed) {
        return (signer, DATA_FEED);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────────────────────────────────

    /// @dev Internal access control check — reverts if caller is not the MultiSig.
    function _onlyMultiSig() internal view {
        if (sender() != MULTISIG) {
            revert Errors__Not_Authorized();
        }
    }
}
