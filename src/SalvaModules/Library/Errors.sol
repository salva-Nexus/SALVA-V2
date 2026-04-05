// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Salva MultiSig Errors
 * @notice Centralized error definitions for the MultiSig administrative layer.
 */
abstract contract Errors {
    /// @dev Caller is not a registered validator.
    error Errors__Not_Authorized();

    /// @dev Validator has already cast a vote on this specific proposal.
    error Errors__Has_Validated();

    /// @dev The Singleton reference is immutable once established.
    error Errors__Singleton_Already_Set();

    /// @dev An active or completed proposal already exists for this registry.
    error Errors__Registry_Init_Proposed();

    /// @dev Action requested on a registry that has no active proposal.
    error Errors__Registry_Init_Not_Proposed();

    /// @dev An active or completed update already exists for this address.
    error Errors__Validator_Update_Proposed();

    /// @dev Action requested on a validator update that has no active proposal.
    error Errors__Validator_Update_Not_Proposed();

    /// @dev Provided data violates Salva identifier length or character constraints.
    error Errors__Invalid_Address_Or_Identifier_Too_Long_Or_Invalid_Prefix();

    /// @dev Attempted to re-initialize a previously finalized registry.
    error Errors__Double_Initialization();

    /// @dev Enough time should have passed before the final call.
    error Error__Invalid_Or_Not_Enough_Time();

    /// @dev Name Length cannot exceed 16 characters
    error Errors__Max_Name_Length_Exceeded();

    /// @dev No upperCase or numbers allowed
    error Errors__Invalid_Character();

    /// @dev Caller not registered registry
    error Errors__Not_Registered();

    /// @dev Name is already taken
    error Errors__Taken();

    /// @dev Can only can this function with on data to link
    error Error__Only_One_Link_To_Data();

    /// @dev Must input a value
    error Errors__Invalid_Values();

    /// @dev Must input only one value
    error Errors__Only_One_Value();

    /// @dev Max Underscore is one
    error Errors__Max_One_Underscore_Allowed();

    /// @dev Calldata length can't be manipulated
    error Errors__Invalid_Length();

    /// @dev Sender Must be the owner of the hash
    error Errors__Invalid_Sender();

    /// @dev if fee is not enough
    error Errors__Not_Enough_Fee();
}
