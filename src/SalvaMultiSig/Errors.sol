// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract Errors {
    // Thrown when a non-validator attempts to call a validator-only function.
    error Errors__Not_Authorized();

    // Thrown when a validator attempts to validate a proposal they have
    // already signed. One validator = one vote per proposal.
    error Errors__Has_Validated();

    // Thrown when attempting to set the Singleton address after it has
    // already been set. The Singleton reference is write-once.
    error Errors__Singleton_Already_Set();

    // Thrown when attempting to propose a registry initialization that
    // has already been proposed. Each registry address can only have one
    // active proposal at a time.
    error Errors__Registry_Init_Proposed();

    // Thrown when attempting to validate or execute a registry initialization
    // that has not yet been proposed.
    error Errors__Registry_Init_Not_Proposed();

    // Thrown when attempting to validate a proposal that has already
    // been executed. Prevents double-execution.
    error Errors__Proposal_Executed();

    // Thrown when attempting to propose a validator update for an address
    // that already has an active pending update proposal.
    error Errors__Validator_Update_Proposed();

    // Thrown when attempting to validate or execute a validator update
    // that has not yet been proposed.
    error Errors__Validator_Update_Not_Proposed();
}
