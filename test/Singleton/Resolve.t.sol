// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "@Errors/Errors.sol";
import { Setup } from "@Setup/Setup.t.sol";

contract Resolve is Setup {
    function test_Cannot_Resolve_When_Paused() external initialized {
        bytes memory _name = bytes("cboi");
        _start(_name, EOA, owner, owner, 0);

        multisig.pauseState(address(singleton), 1);

        bytes4 revertSelector = Errors.Errors__NotAuthorized.selector;
        vm.expectRevert(revertSelector);
        registry.resolveAddress(_name);

        _test_Successfull_Resolve_When_Not_Paused();
    }

    function _test_Successfull_Resolve_When_Not_Paused() internal {
        multisig.proposeUnpause(address(singleton), 1);
        multisig.validateUnpause(address(singleton));
        multisig.executeUnpause(address(singleton));

        address expectedAddress = registry.resolveAddress(bytes("cboi@salva"));
        assertEq(expectedAddress, EOA);
    }
}
