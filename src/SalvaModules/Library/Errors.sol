// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Errors
 * @notice Centralised custom-error definitions for the Salva protocol.
 * @dev All contracts in the protocol inherit from this base so that error
 *      selectors are consistent across the singleton, registries, and MultiSig.
 */
abstract contract Errors {
    /// @dev Caller is not a registered validator.
    error Errors__Not_Authorized();

    /// @dev Validator has already cast a vote on this proposal.
    error Errors__Has_Validated();

    /// @dev The singleton reference is immutable once set.
    error Errors__Singleton_Already_Set();

    /// @dev An active or completed proposal already exists for this registry.
    error Errors__Registry_Init_Proposed();

    /// @dev Action requested on a registry with no active proposal.
    error Errors__Registry_Init_Not_Proposed();

    /// @dev An active or completed update already exists for this validator address.
    error Errors__Validator_Update_Proposed();

    /// @dev Action requested on a validator update with no active proposal.
    error Errors__Validator_Update_Not_Proposed();

    /// @dev Supplied data violates Salva identifier length or character constraints.
    error Errors__Invalid_Address_Or_Identifier_Too_Long_Or_Invalid_Prefix();

    /// @dev Attempted to re-initialize a previously finalized registry.
    error Errors__Double_Initialization();

    /// @dev The required timelock period has not yet elapsed.
    error Error__Invalid_Or_Not_Enough_Time();

    /// @dev Alias exceeds the maximum allowed length of 32 bytes.
    error Errors__Max_Name_Length_Exceeded();

    /// @dev Character is not in the permitted set (a–z, 2–9, `_`).
    error Errors__Invalid_Character();

    /// @dev Caller is not a registered registry contract.
    error Errors__Not_Registered();

    /// @dev This alias is already registered in the namespace.
    error Errors__Taken();

    /// @dev An alias must resolve to exactly one data type.
    error Error__Only_One_Link_To_Data();

    /// @dev Input value must not be zero or empty.
    error Errors__Invalid_Values();

    /// @dev Only one value may be supplied.
    error Errors__Only_One_Value();

    /// @dev An alias may contain at most one underscore.
    error Errors__Max_One_Underscore_Allowed();

    /// @dev Calldata length field does not match actual payload — possible manipulation attempt.
    error Errors__Invalid_Length();

    /// @dev The caller does not own the alias they are attempting to modify.
    error Errors__Invalid_Sender();

    /// @dev Attached ETH value is below the required registration fee.
    error Errors__Not_Enough_Fee();

    /// @dev Price feed returned a stale or invalid answer.
    error Errors__Invalid_price();

    /// @dev Low-level singleton call failed.
    error Errors_Failed();

    /// @dev Signature recovery did not match the authorised Salva backend signer.
    error Errors__Invalid_Call_Source();

    /// @dev Supplied address is the zero address.
    error Errors__Invalid_Address();
}
