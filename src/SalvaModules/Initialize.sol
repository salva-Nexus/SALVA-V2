// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Resolve } from "@Resolve/Resolve.sol";

/**
 * @title Initialize
 * @author cboi@Salva
 * @notice MultiSig-gated logic for onboarding new registries into the Salva ecosystem.
 * @dev Enforces strict namespace uniqueness and MultiSig-only access.
 *      Inherits `Resolve` (→ `NameLib` → `Modifier` → `Errors` → `Storage` → `Context`).
 */
abstract contract Initialize is Resolve {
    // ─────────────────────────────────────────────────────────────────────────
    // REGISTRY ONBOARDING
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Permanently registers a namespace handle to a specific registry contract.
     *
     * @dev Access: MultiSig only (`onlyMultiSig(_multiSig)`).
     *
     *      STEP 1 — ACCESS CONTROL
     *        `onlyMultiSig` ensures no namespace can be claimed without high-level
     *        validator consensus.
     *
     *      STEP 2 — DATA INTEGRITY & PREFIX CHECK
     *        · `registry != address(0)`
     *        · `namespaceHandle[0] == 0x40` (`[at]`)
     *        Diagram:
     *          [ 0x40 ][ s ][ a ][ l ][ v ][ a ][ 0x00 … ]
     *            ^ byte 0 MUST be the `[at]` symbol
     *
     *      STEP 3 — COLLISION & DOUBLE-INIT CHECK
     *        · `_registryNamespace[registry]` must be unset (registry not yet bound).
     *        · `_isNamespaceClaimed[namespaceHandle]` must be `false` (handle not yet taken).
     *        Reverts with `Errors__DoubleInitialization` if either check fails.
     *
     *      STEP 4 — STORAGE COMMITMENT
     *        · `_registryNamespace[registry]` = `{ namespaceHandle, namespaceLength }`
     *        · `_isNamespaceClaimed[namespaceHandle]` = `true`
     *        Result: the registry is now authorized to link aliases via `linkNameAlias`.
     *
     * @param registry          The registry contract address to onboard.
     * @param namespaceHandle   The bytes31 namespace handle (e.g. `[at]salva\x00...`). Must start
     * with `0x40`.
     * @param namespaceLength   Byte length of the namespace handle.
     * @return success          `true` on successful registration.
     */
    function initializeRegistry(address registry, bytes31 namespaceHandle, bytes1 namespaceLength)
        external
        onlyMultiSig(_multiSig)
        returns (bool success)
    {
        if (registry == address(0) || namespaceHandle[0] != 0x40) {
            revert Errors__InvalidAddressOrNamespaceFormat();
        }

        (bytes31 existingHandle,) = namespace(registry);
        bool alreadyClaimed = _isNamespaceClaimed[namespaceHandle];

        if (existingHandle != bytes31(0) || alreadyClaimed) {
            revert Errors__DoubleInitialization();
        }

        _registryNamespace[registry].handle = namespaceHandle;
        _registryNamespace[registry].length = namespaceLength;
        _isNamespaceClaimed[namespaceHandle] = true;

        success = true;
    }
}
