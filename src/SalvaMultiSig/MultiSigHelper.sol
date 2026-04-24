// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { MultiSigModifier } from "@MultiSigModifier/MultiSigModifier.sol";

/**
 * @title MultiSigHelper
 * @author cboi@Salva
 * @notice Internal view logic and encoding utilities for the Salva MultiSig.
 * @dev Provides read-only access to proposal state and recovery/validator status,
 *      plus ABI encoding helpers used by the execution modules.
 *
 *      Inherits `MultiSigModifier` (→ `MultiSigErrors` → `Events` → `MultiSigStorage`).
 */
abstract contract MultiSigHelper is MultiSigModifier {
    // ─────────────────────────────────────────────────────────────────────────
    // PROPOSAL STATE QUERIES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns the number of validator votes still required to reach quorum
     *         on a registry initialization proposal.
     * @param registry  The clone address of the registry under proposal.
     * @return remaining  Votes still needed.
     */
    function registryInitVotesRemaining(address registry)
        external
        view
        returns (uint256 remaining)
    {
        remaining = _initRegistryProposal[registry].remaining;
    }

    /**
     * @notice Returns the number of validator votes still required to reach quorum
     *         on a validator set update proposal.
     * @param target    The address of the validator under proposal.
     * @return remaining  Votes still needed.
     */
    function validatorUpdateVotesRemaining(address target)
        external
        view
        returns (uint256 remaining)
    {
        remaining = _validatorUpdateProposal[target].remaining;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // STATUS QUERIES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Returns whether a given address holds recovery privileges.
     * @param account  The address to check.
     * @return `true` if the address is a recognized recovery entity.
     */
    function isRecovery(address account) external view returns (bool) {
        return _recovery[account];
    }

    /**
     * @notice Returns whether a given address is currently an active validator.
     * @param account  The address to check.
     * @return `true` if the address is an active validator.
     */
    function isValidator(address account) external view returns (bool) {
        return _isValidator[account];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TYPE CONVERSION UTILITIES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Converts a string namespace to its packed `bytes31` representation.
     * @param namespace_  The string namespace (e.g. `"[at]salva"`).
     * @return packed     The resulting `bytes31` value.
     */
    function _toBytes31(string memory namespace_) internal pure returns (bytes31 packed) {
        // forge-lint: disable-next-line(unsafe-typecast)
        packed = bytes31(bytes(namespace_));
    }

    /**
     * @dev Converts a `uint256` length value to `bytes1`.
     * @param value  The integer to convert.
     * @return packed  The resulting `bytes1` value.
     */
    function _toBytes1(uint256 value) internal pure returns (bytes1 packed) {
        // forge-lint: disable-next-line(unsafe-typecast)
        packed = bytes1(uint8(value));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ABI ENCODING UTILITIES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Returns ABI-encoded calldata for `upgradeToAndCall(address,bytes)`.
     * @param newImpl  The new implementation address.
     * @return Encoded calldata bytes.
     */
    function _encodeUpgrade(address newImpl) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("upgradeToAndCall(address,bytes)", newImpl, "");
    }

    /**
     * @dev Returns ABI-encoded calldata for `pauseProtocol()`.
     * @return Encoded calldata bytes.
     */
    function _encodePause() internal pure returns (bytes memory) {
        return abi.encodeWithSignature("pauseProtocol()");
    }

    /**
     * @dev Returns ABI-encoded calldata for `unpauseProtocol()`.
     * @return Encoded calldata bytes.
     */
    function _encodeUnpause() internal pure returns (bytes memory) {
        return abi.encodeWithSignature("unpauseProtocol()");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CLONE DEPLOYMENT UTILITY
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Deploys a new BaseRegistry clone via `RegistryFactory.deployRegistry`.
     * @param singleton   The Singleton address to pass to the new registry.
     * @param factory     The RegistryFactory proxy address.
     * @param namespace_  The namespace string for the new registry.
     * @return clone      The address of the newly deployed registry clone.
     */
    function _deployClone(address singleton, address factory, string memory namespace_)
        internal
        returns (address clone)
    {
        bytes memory data = abi.encodeWithSignature(
            "deployRegistry(address,address,string)", singleton, factory, namespace_
        );
        (bool success, bytes memory returnData) = factory.call(data);
        if (!success) revert Errors__CloneDeploymentFailed();
        clone = abi.decode(returnData, (address));
    }
}
