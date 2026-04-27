// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { UnlinkName } from "@UnlinkName/UnlinkName.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Singleton
 * @author cboi@Salva
 * @notice The primary entry point for Salva's name-to-wallet infrastructure.
 * @dev Combines registry initialization, alias resolution, linking, and unlinking
 *      into a single upgradeable contract.
 *
 *      Inheritance chain (linear):
 *        Context → Storage → Errors → Modifier → NameLib → Resolve
 *          → Initialize → LinkName → UnlinkName → Singleton
 *
 *      All write operations (`linkNameAlias`, `unlink`) are callable only by
 *      registered registry contracts. All governance operations (`initializeRegistry`,
 *      `withdraw`, `pause`, `upgrade`) are callable only by the MultiSig.
 *
 * @custom:version 2
 */
contract Singleton is Initializable, UUPSUpgradeable, UnlinkName {
    using SafeERC20 for IERC20;

    // ─────────────────────────────────────────────────────────────────────────
    // PROTOCOL CONSTANTS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Protocol version baked into bytecode.
     * @dev Stored as a constant to eliminate SLOAD (2100 gas) replacing it with
     *      a cheap PUSH (3 gas).
     *      [ PUSH1 0x02 ] → baked into contract bytecode at compile time.
     */
    uint8 private constant VERSION = 2;

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTOR
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Disables initializers on the implementation contract to prevent
     *      unauthorized direct initialization.
     */
    constructor() {
        _disableInitializers();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZER
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Initializes the Singleton proxy with the administrative MultiSig address.
     * @dev Called once during proxy deployment. Sets `_multiSig` — the only address
     *      permitted to call `initializeRegistry` and other governance functions.
     *      Cannot be called again after initialization.
     *
     * @param multiSig The MultiSig contract address to set as the protocol governor.
     */
    function initialize(address multiSig) external initializer {
        _multiSig = multiSig;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GOVERNANCE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Withdraws any ERC-20 token balance held by this contract.
     * @dev Restricted to the MultiSig. Uses `SafeERC20.safeTransfer` to handle
     *      non-standard token implementations safely.
     *
     * @param token    The ERC-20 token contract address to withdraw.
     * @param receiver The destination address for the withdrawn tokens.
     */
    function withdraw(address token, address receiver) external onlyMultiSig(_multiSig) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(receiver, balance);
        }
    }

    /**
     * @notice Pauses all alias link operations protocol-wide.
     * @dev Sets `_paused = true`. Restricted to the MultiSig.
     *      All calls to `linkNameAlias` will revert while paused.
     */
    function pauseProtocol() external onlyMultiSig(_multiSig) {
        _paused = true;
    }

    /**
     * @notice Resumes alias link operations after a pause.
     * @dev Sets `_paused = false`. Restricted to the MultiSig.
     */
    function unpauseProtocol() external onlyMultiSig(_multiSig) {
        _paused = false;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEW
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the current ERC-1967 implementation address.
     * @return impl The address of the active implementation contract.
     */
    function getImplementation() external view returns (address impl) {
        impl = ERC1967Utils.getImplementation();
    }

    function nameToByte(string memory _name) external pure returns (bytes memory _nb) {
        _nb = bytes(_name);
    }

    /**
     * @notice Returns the protocol version identifier.
     * @dev Pure function — value is baked into bytecode, no SLOAD required.
     * @return The protocol version number (`2`).
     */
    function version() public pure returns (uint8) {
        return VERSION;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UUPS UPGRADE AUTHORIZATION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Authorizes a UUPS upgrade. Restricted to the MultiSig.
     *      Called internally by `upgradeToAndCall` before executing the upgrade.
     *
     * @param newImplementation The address of the proposed new implementation.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyMultiSig(_multiSig)
    { }
}
