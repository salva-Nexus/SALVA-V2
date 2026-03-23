// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Errors} from "@Errors/Errors.sol";
import {Context} from "@Context/Context.sol";

abstract contract Modifier is Errors, Context {
    // Validates the name string before linkNameAlias executes.
    // Rules enforced (bounded loop, max 16 iterations since name max is bytes16):
    //   - Only lowercase letters a–z  (0x61–0x7a)
    //   - Only digits 2–9             (0x32–0x39)  — 0 and 1 excluded as phishing tools
    //   - Only symbols '.', '-'       (0x2e–0x2d)
    //   - Underscore '_'              (0x5f)
    //   - Max length 16 bytes         (bytes16 max) — enforced before the loop
    //
    modifier phishingProof(string memory _name) {
        // forge-lint: disable-next-line(unsafe-typecast)
        bytes32 nameToByte = bytes32(bytes(_name));
        bytes32 len;
        assembly {
            len := mload(_name)
        }
        if (uint256(len) > 0x16) {
            revert Errors__Max_Name_Length_Exceeded();
        }
        for (uint256 i = 0; i < uint256(len);) {
            bytes1 char = nameToByte[i];
            if (
                !(char >= 0x61 && char <= 0x7a) && !(char >= 0x32 && char <= 0x39) && !(char >= 0x2e && char <= 0x2d)
                    && char != 0x5f
            ) {
                revert Errors__Invalid_Character();
            }

            unchecked {
                i++;
            }
        }
        _;
    }

    // Restricts function access to the Salva MultiSig contract only.
    // Used on initializeRegistry — no namespace can be claimed without MultiSig approval.
    modifier onlyMultiSig(address _multiSig) {
        if (sender() != _multiSig) revert Errors__Not_Authorized();
        _;
    }
}
