// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Context } from "@Context/Context.sol";

/**
 * @title Storage
 * @author cboi@Salva
 * @notice Canonical storage layout for the Salva Singleton.
 * @dev Separated from logic to guarantee safe UUPS upgrades. All state variables
 *      used by the Singleton and its inherited modules are declared here.
 *
 *      Storage hygiene:
 *        · A 50-slot gap is reserved at the end to allow new variables to be
 *          appended in future upgrades without corrupting the existing layout.
 *        · The `_nameToWallet` mapping is public so off-chain indexers can read
 *          it directly, but all protocol writes go through `NameLib` assembly paths.
 */
abstract contract Storage is Context {
    // ─────────────────────────────────────────────────────────────────────────
    // ACCESS CONTROL
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice The Salva MultiSig contract address.
     * @dev The only address permitted to call `initializeRegistry` and other
     *      `onlyMultiSig`-gated functions on the Singleton.
     */
    address internal _multiSig;

    /**
     * @notice Global pause flag for the Singleton.
     * @dev `false` = operational; `true` = paused. Checked by `whenNotPaused`.
     */
    bool internal _paused;

    // ─────────────────────────────────────────────────────────────────────────
    // NAMESPACE REGISTRY
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Tracks which namespace handles have been claimed protocol-wide.
     * @dev Prevents two registries from registering the same handle (e.g. `[at]salva`).
     *      Key:   bytes31 namespace handle
     *      Value: bool    true once claimed
     */
    mapping(bytes31 namespaceHandle => bool isClaimed) internal _isNamespaceClaimed;

    /**
     * @notice Maps each registry contract address to its assigned namespace metadata.
     * @dev Populated once during `initializeRegistry`; immutable after that.
     *      Key:   address  registry contract
     *      Value: Namespace { handle, length }
     */
    mapping(address registry => Namespace namespaceData) internal _registryNamespace;

    /**
     * @notice Packed namespace descriptor stored per registry.
     * @param handle  The raw bytes31 namespace handle (e.g. `[at]salva\x00...`).
     * @param length  Byte length of the namespace string including the `[at]` prefix.
     */
    struct Namespace {
        bytes31 handle;
        bytes1 length;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // NAME-TO-WALLET MAPPINGS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Ownership index used to authorise unlink operations.
     * @dev Slot = keccak256(nameHash ++ ownerAddress) → nameHash.
     *      Written by `_performLinkToWallet`; read by `_checkCaller`.
     */
    mapping(bytes32 ownershipKey => bytes32 nameHash) internal _ownershipIndex;

    /**
     * @notice Primary alias-to-wallet resolution mapping.
     * @dev Although `Resolve.sol` reads this via inline-assembly `sload(nameHash)`,
     *      the explicit declaration ensures the Solidity compiler reserves the
     *      correct storage context and prevents future variable collisions.
     *      Key:   bytes32  welded keccak256 name hash (see `NameLib._computeNameHash`)
     *      Value: address  destination Safe wallet or EOA
     */
    mapping(bytes32 nameHash => address wallet) public _nameToWallet;

    // ─────────────────────────────────────────────────────────────────────────
    // UPGRADEABILITY PROTECTION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Reserved gap for future state variables.
     *      Decrement the array size by 1 for each new variable added above.
     */
    uint256[50] private __gap;
}
