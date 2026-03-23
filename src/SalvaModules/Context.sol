// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract Context {
    function sender() internal view returns (address) {
        return msg.sender;
    }
}
