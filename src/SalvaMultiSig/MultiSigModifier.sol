// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "@Errors/Errors.sol";

abstract contract MultiSigModifier is Errors {
    // Restricts function access to active validators only.
    // Pass _is_Validator[msg.sender] as the argument.
    modifier onlyValidators(bool _isValidator) {
        if (!_isValidator) {
            revert Errors__Not_Authorized();
        }
        _;
    }
}
