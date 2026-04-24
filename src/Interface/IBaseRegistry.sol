// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IBaseRegistry
 * @author cboi@Salva
 * @notice Interface for Salva BaseRegistry clones.
 * @dev Each BaseRegistry is an EIP-1167 minimal proxy deployed by the `RegistryFactory`.
 *      It manages name-to-wallet linking within a specific namespace, delegating all
 *      storage writes to the shared Singleton.
 *
 *      Lifecycle:
 *        1. `RegistryFactory.deployRegistry(...)` → deploys a clone and calls `initialize`.
 *        2. `MultiSig.executeInitRegistry(...)` → calls `Singleton.initializeRegistry(...)`,
 *           binding this registry's address to its namespace in Singleton storage.
 *        3. Users call `link(...)` / `unlink(...)` through this contract.
 */
interface IBaseRegistry {
    // ─────────────────────────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Emitted when a name alias is successfully linked to a wallet address.
     * @param name    The raw alias bytes that were linked.
     * @param wallet  The destination wallet address that was bound.
     */
    event LinkSuccess(bytes name, address indexed wallet);

    /**
     * @notice Emitted when a name alias binding is successfully removed.
     * @param name  The raw alias bytes that were unlinked.
     */
    event UnlinkSuccess(bytes name);

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Configures the proxy's initial state. Replaces constructor logic for
     *         EIP-1167 minimal proxy clones.
     * @dev Can only be called once. Subsequent calls revert with `Errors__AlreadyInitialized`.
     *
     * @param singleton   Address of the Salva Singleton (global storage layer).
     * @param factory     Address of the RegistryFactory (provides signer + NGNs config).
     * @param namespace_  The string namespace identifier for this registry (e.g. `"@salva"`).
     */
    function initialize(address singleton, address factory, string memory namespace_) external;

    // ─────────────────────────────────────────────────────────────────────────
    // CORE OPERATIONS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Links a name alias to a destination wallet address.
     * @dev Verifies the backend ECDSA signature and collects the protocol fee before
     *      delegating the storage write to the Singleton via `linkNameAlias`.
     *
     *      Fee logic:
     *        · Fee amount is fetched dynamically from `RegistryFactory.getFee()`.
     *        · If fee > 0, `fee` units of NGNs are transferred from the caller to
     *          the Singleton before the link is executed.
     *
     *      Signature scheme:
     *        `messageHash = keccak256(abi.encodePacked(_name, _wallet))`
     *        `digest      = toEthSignedMessageHash(messageHash)`
     *        The recovered signer must match the active signer from `RegistryFactory`.
     *
     * @param name       The alias bytes to register (e.g. `"charles"`).
     * @param wallet     The destination wallet address to link to the alias.
     * @param signature  Backend ECDSA signature authorizing this specific link.
     * @return isLinked  `true` on successful link.
     */
    function link(bytes calldata name, address wallet, bytes calldata signature)
        external
        returns (bool isLinked);

    /**
     * @notice Removes a name alias mapping from the Singleton.
     * @dev Ownership verification (caller must be original registrant) is enforced
     *      inside the Singleton's `unlink` implementation.
     *
     * @param name       The alias bytes to unlink.
     * @return isSuccess `true` on successful removal.
     */
    function unlink(bytes calldata name) external returns (bool isSuccess);

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Resolves a local name alias to its associated wallet address.
     * @dev Proxies the call to `Singleton.resolveAddress`. The name should be the
     *      local form (e.g. `"charles"`) — the Singleton prepends the namespace.
     *
     * @param name   The local alias handle to resolve.
     * @return addr  The linked wallet address, or `address(0)` if unmapped.
     */
    function resolveAddress(bytes calldata name) external view returns (address addr);

    /**
     * @notice Returns the namespace identifier string for this registry.
     * @return The namespace string (e.g. `"@salva"`).
     */
    function namespace() external view returns (string memory);
}
