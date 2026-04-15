// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ISalvaSingleton
 * @author cboi@Salva
 * @notice Interface for the Salva singleton — the shared resolution and storage
 *         layer that all registry clones route their calls through.
 * @dev The singleton owns all namespace-to-registry bindings and all
 *      alias-to-wallet mappings. Registries are the only authorized callers
 *      for write operations — authorization is enforced by checking the caller's
 *      namespace assignment in singleton storage.
 */
interface ISalvaSingleton {
    // ─────────────────────────────────────────────────────────────────────────
    // GOVERNANCE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Permanently binds a namespace handle to a registry contract address.
     * @dev Called by the MultiSig via `executeInit` after quorum and timelock are met.
     *      Once set, the binding is immutable — the same namespace cannot be
     *      re-initialized to a different registry.
     * @param registry         The registry contract address to bind.
     * @param namespaceHandle  The bytes16 namespace handle (e.g. `0x4073616c766100…`).
     * @param namespaceLength  Byte length of the namespace string.
     * @return `true` on successful binding.
     */
    function initializeRegistry(address registry, bytes16 namespaceHandle, bytes1 namespaceLength)
        external
        returns (bool);

    // ─────────────────────────────────────────────────────────────────────────
    // ALIAS WRITE OPERATIONS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Welds a name alias and the calling registry's namespace into a storage
     *         key and binds it to a wallet address.
     * @dev The namespace is read from singleton storage based on `msg.sender` (the registry) —
     *      it is never supplied by the user. Name normalization and the anti-phishing
     *      alphabetical flip are applied before the storage write.
     * @param name     Raw alias bytes (e.g. `"charles"`).
     * @param wallet   Wallet address to bind to the alias.
     * @param _sender  The originating user EOA, captured by the registry as `msg.sender`.
     * @return isLinked `true` on successful storage write.
     */
    function linkNameAlias(bytes calldata name, address wallet, address _sender)
        external
        payable
        returns (bool isLinked);

    /**
     * @notice Removes the alias-to-wallet binding for a given name in the calling
     *         registry's namespace.
     * @dev Reconstructs the canonical storage key from the name and namespace,
     *      verifies the caller owns the alias via the ownership index, then zeros
     *      both the alias slot and the ownership index slot.
     * @param name     Raw alias bytes to unlink.
     * @param _sender  The originating user EOA — must match the original registrant.
     * @return isUnlinked `true` on successful storage zeroing.
     */
    function unlink(bytes calldata name, address _sender) external returns (bool isUnlinked);

    function withdraw(address token, address receiver) external;

    // ─────────────────────────────────────────────────────────────────────────
    // RESOLUTION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Resolves a full namespaced alias to its linked wallet address.
     * @dev Normalizes the input, welds the name and namespace into the canonical
     *      storage key, and returns the stored wallet address via a single `sload`.
     * @param aliasName  Full alias including namespace suffix (e.g. `"charles@salva"`).
     * @return wallet    The wallet address bound to the alias, or `address(0)` if unregistered.
     */
    function resolveAddress(bytes calldata aliasName) external view returns (address wallet);

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the namespace handle and its byte length for a given registry address.
     * @param registry          The registry contract to query.
     * @return namespaceHandle  The bytes16 namespace handle assigned to this registry.
     * @return namespaceLength  Byte length of the namespace string.
     */
    function namespace(address registry)
        external
        view
        returns (bytes16 namespaceHandle, bytes1 namespaceLength);

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Triggers a UUPS upgrade on the singleton implementation.
     * @dev Called by the MultiSig via `upgradeSingleton`. Authorization is enforced
     *      inside the singleton's `_authorizeUpgrade` which restricts callers to the MultiSig.
     * @param newImplementation  Address of the new singleton implementation.
     * @param data               Optional calldata forwarded to the new implementation.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}
