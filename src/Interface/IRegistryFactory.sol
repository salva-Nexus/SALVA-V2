// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IRegistryFactory
 * @author cboi@Salva
 * @notice Interface for the Salva RegistryFactory.
 * @dev BaseRegistry clones consume this interface to fetch global protocol
 *      configuration (active signer, NGNs address, and fee amount) dynamically,
 *      enabling protocol-wide updates via a single storage change on the Factory
 *      without re-deploying any registry clones.
 */
interface IRegistryFactory {
    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY DEPLOYMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Deploys a new EIP-1167 minimal proxy registry for a specific namespace.
     * @dev Clones `IMPLEMENTATION`, calls `BaseRegistry.initialize` on the clone,
     *      and returns the new clone address. Callable only by the MultiSig.
     *
     * @param singleton    The address of the Salva Singleton.
     * @param factory      The proxy address of the RegistryFactory (this contract).
     * @param namespace_   The string namespace identifier for the new registry.
     * @return clone       The address of the deployed and initialized BaseRegistry proxy.
     */
    function deployRegistry(address singleton, address factory, string memory namespace_)
        external
        returns (address clone);

    // ─────────────────────────────────────────────────────────────────────────
    // ADMINISTRATIVE UPDATES (MultiSig-only)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Updates the protocol-wide backend signer address.
     * @dev Affects all existing and future registries that query this factory.
     *      Callable only by the MultiSig.
     *
     * @param newSigner The address of the new authorized backend signer.
     * @return success  `true` upon successful update.
     */
    function updateSigner(address newSigner) external returns (bool success);

    /**
     * @notice Updates the BaseRegistry logic implementation address used for future clones.
     * @dev Existing clones are unaffected; only new clones will use the new implementation.
     *      Callable only by the MultiSig.
     *
     * @param newImpl  The address of the new BaseRegistry implementation.
     * @return success `true` upon successful update.
     */
    function updateImplementation(address newImpl) external returns (bool success);

    /**
     * @notice Updates the protocol-wide link fee amount.
     * @dev Fee is denominated in NGNs (6 decimals). Callable only by the MultiSig.
     *
     * @param newFee   The new fee amount in NGNs base units.
     * @return success `true` upon successful update.
     */
    function updateFee(uint256 newFee) external returns (bool success);

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Retrieves the current global signer and NGNs token addresses.
     * @dev Optimized as a single call for consumption by registries during `link` execution.
     *      Reverts if the RegistryFactory is paused.
     *
     * @return signer  The active authorized backend signer address.
     * @return ngns    The current NGNs stablecoin contract address.
     */
    function getSignerAndNGNs() external view returns (address signer, address ngns);

    /**
     * @notice Returns the current protocol link fee.
     * @dev Reverts if the RegistryFactory is paused.
     *
     * @return fee  The current fee in NGNs base units.
     */
    function getFee() external view returns (uint256 fee);
}
