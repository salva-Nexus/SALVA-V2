// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "@Errors/Errors.sol";
import { Setup } from "@Setup/Setup.t.sol";

contract UnlinkName is Setup {
    function test_Unlink_Name() external initialized {
        _changePrank(owner);
        _transfer(EOA);

        bytes memory _name = bytes("cboi");
        _start(_name, EOA, owner, EOA, 0);

        address linked = registry.resolveAddress(bytes("cboi@salva"));
        assertEq(linked, EOA);

        registry.unlink(bytes("cboi"));

        address unlinked = registry.resolveAddress(bytes("cboi@salva"));
        assertNotEq(unlinked, linked);
    }

    function test_arbitrary_User_Cannot_Unlink_Another_User() external initialized {
        bytes memory _name = bytes("cboi");
        _start(_name, owner, owner, owner, 0);

        _changePrank(EOA);
        vm.expectRevert(Errors.Errors__InvalidSender.selector);
        registry.unlink(_name);
    }
}
