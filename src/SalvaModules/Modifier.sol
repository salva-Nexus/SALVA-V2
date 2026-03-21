// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract Modifier {
    // protect against case mimickry (No UpperCase)
    modifier phishingProof(string memory _name) {
        assembly {
            let len := mload(_name)
            let name := mload(add(_name, 0x20))
            let mask := 0x2020202020202020202020202020202020202020202020202020202020202020
            let cleaned := and(name, not(0xffffffffffffffffffffffffffffffff))

            switch eq(cleaned, name)

            case 0x00 {
                revert(0x00, 0x00)
            }
            default {
                let nameWithMask := or(name, shr(mul(len, 0x08), mask))
                let final := and(nameWithMask, mask)
                if iszero(eq(final, mask)) {
                    revert(0x00, 0x00)
                }
            }
        }
        _;
    }

    modifier onlyMultiSig(address _multiSig) {
        if (msg.sender != _multiSig) revert();
        _;
    }
}
