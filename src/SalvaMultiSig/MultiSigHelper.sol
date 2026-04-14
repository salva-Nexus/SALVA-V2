// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSigModifier} from "@MultiSigModifier/MultiSigModifier.sol";

/**
 * @title MultiSigHelper
 * @author cboi@Salva
 * @notice Internal view logic for tracking MultiSig validation progress and state.
 * @dev Provides read-only access to validator update status, recovery permissions, and type conversions.
 */
abstract contract MultiSigHelper is MultiSigModifier {
    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATOR UPDATE TRACKING
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Retrieves the number of remaining signatures required for a validator update to reach quorum.
     * @dev Reads the 'remaining' field from the ValidatorUpdateRequest struct associated with the address.
     * @param _addr The address of the validator subject to the update.
     * @return The count of additional unique signatures needed.
     */
    function _validatorValidationCountRemains(address _addr) external view returns (uint256) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        return uint256(update.remaining);
    }

    /**
     * @notice Checks if the message sender has already cast a vote for a specific validator update.
     * @dev Queries the hasValidated mapping within the ValidatorUpdateRequest struct.
     * @param _addr The address of the validator subject to the update.
     * @return True if the sender has already validated the update, false otherwise.
     */
    function _hasValidatedValidatorUpdate(address _addr) external view returns (bool) {
        ValidatorUpdateRequest storage update = _updateValidator[_addr];
        return update.hasValidated[sender()];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RECOVERY STATUS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Verifies if a specific address has recovery privileges.
     * @dev Returns the boolean value stored in the _recovery mapping for the given address.
     * @param recovery The address to check for recovery permissions.
     * @return True if the address is a recognized recovery entity.
     */
    function isRecovery(address recovery) external view returns (bool) {
        return _recovery[recovery];
    }

    /**
     * @notice Verifies if a specific address is currently an active validator.
     * @dev Returns the boolean value stored in the _isValidator mapping.
     * @param validator The address to check for validator status.
     * @return True if the address is an active validator.
     */
    function isValidator(address validator) external view returns (bool) {
        return _isValidator[validator];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TYPE CONVERSION UTILITIES
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Converts a string namespace to a bytes16 format.
     * @param nspace The string representation of the namespace.
     * @return _nspace The resulting bytes16 value.
     */
    function _toBytes16(string memory nspace) internal pure returns (bytes16 _nspace) {
        _nspace = bytes16(bytes(nspace));
    }

    /**
     * @dev Converts a uint256 number to a bytes1 format.
     * @param num The number to be converted.
     * @return _num The resulting bytes1 value.
     */
    function _toBytes1(uint256 num) internal pure returns (bytes1 _num) {
        _num = bytes1(uint8(num));
    }
}
