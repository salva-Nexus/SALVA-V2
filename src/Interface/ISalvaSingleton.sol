// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ISalvaSingleton
 * @author cboi@Salva
 * @notice Interface for the Salva Singleton — the shared resolution and storage layer
 *         that all registry clones route their calls through.
 *
 * @dev The Singleton owns all namespace-to-registry bindings and all alias-to-wallet
 *      mappings. Registry contracts are the only authorized callers for write operations;
 *      authorization is enforced by checking the caller's namespace assignment in
 *      Singleton storage.
 *
 *      Architecture diagram:
 *        User → BaseRegistry → Singleton (link / unlink / resolve)
 *        MultiSig            → Singleton (initializeRegistry / withdraw / upgrade)
 */
interface ISalvaSingleton {
    // ─────────────────────────────────────────────────────────────────────────
    // GOVERNANCE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Permanently binds a namespace handle to a registry contract address.
     * @dev Called by the MultiSig via `executeInitRegistry` after quorum and timelock
     *      are satisfied. Once set, the binding is immutable — the same namespace
     *      cannot be re-initialized to a different registry.
     *
     * @param registry          The registry contract address to bind.
     * @param namespaceHandle   The bytes31 namespace handle (e.g. `[at]salva\x00...`).
     *                          Must begin with `0x40` (`[at]`).
     * @param namespaceLength   Byte length of the namespace string.
     * @return success          `true` on successful binding.
     */
    function initializeRegistry(address registry, bytes31 namespaceHandle, bytes1 namespaceLength)
        external
        returns (bool success);

    // ─────────────────────────────────────────────────────────────────────────
    // ALIAS WRITE OPERATIONS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Welds a name alias and the calling registry's namespace into a storage
     *         key and binds it to a wallet address.
     * @dev The namespace is read from Singleton storage based on `msg.sender` (the
     *      registry) — it is never supplied by the user. Name normalization and the
     *      anti-phishing alphabetical flip are applied before the storage write.
     *
     * @param name    Raw alias bytes (e.g. `"charles"`).
     *                Must be ≤ 32 bytes, lowercase a–z, digits 2–9, max one `_`.
     * @param wallet  Wallet address to bind to the alias.
     * @param caller  The originating user EOA, captured by the registry as `msg.sender`.
     * @return isLinked `true` on successful storage write.
     */
    function linkNameAlias(bytes calldata name, address wallet, address caller)
        external
        payable
        returns (bool isLinked);

    /**
     * @notice Removes the alias-to-wallet binding for a given name in the calling
     *         registry's namespace.
     * @dev Reconstructs the canonical storage key from the name and namespace,
     *      verifies the caller owns the alias via the ownership index, then zeros
     *      both the alias slot and the ownership-index slot.
     *
     * @param name    Raw alias bytes to unlink.
     * @param caller  The originating user EOA — must match the original registrant.
     * @return isUnlinked `true` on successful storage zeroing.
     */
    function unlink(bytes calldata name, address caller) external returns (bool isUnlinked);

    /**
     * @notice Withdraws any ERC-20 token balance held by the Singleton.
     * @dev Called by the MultiSig. Uses `SafeERC20.safeTransfer` internally.
     *
     * @param token    The ERC-20 token contract address.
     * @param receiver The destination address for the withdrawn tokens.
     */
    function withdraw(address token, address receiver) external;

    // ─────────────────────────────────────────────────────────────────────────
    // RESOLUTION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Resolves a fully qualified namespaced alias to its linked wallet address.
     * @dev Normalizes the input, welds the name and namespace into the canonical
     *      storage key, and returns the stored wallet address via a single `sload`.
     *
     * @param aliasName  Full alias including namespace suffix (e.g. `"charles[at]salva"`).
     * @return wallet    The wallet address bound to the alias, or `address(0)` if unregistered.
     */
    function resolveAddress(bytes calldata aliasName) external view returns (address wallet);

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the namespace handle and its byte length for a given registry address.
     *
     * @param registry          The registry contract to query.
     * @return namespaceHandle  The bytes31 namespace handle assigned to this registry.
     * @return namespaceLength  Byte length of the namespace string.
     */
    function namespace(address registry)
        external
        view
        returns (bytes31 namespaceHandle, bytes1 namespaceLength);

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Triggers a UUPS upgrade on the Singleton implementation.
     * @dev Called by the MultiSig via `executeUpgrade`. Authorization is enforced
     *      inside `_authorizeUpgrade` which restricts callers to the MultiSig address.
     *
     * @param newImplementation  Address of the new Singleton implementation contract.
     * @param data               Optional calldata forwarded to the new implementation.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}
