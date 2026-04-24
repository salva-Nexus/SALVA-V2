// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "@Errors/Errors.sol";
import { Setup } from "@Setup/Setup.t.sol";

contract InitializeRegistry is Setup {
    function test_Initialize() external {
        _changePrank(owner);
        multisig.validateRegistryInit(address(registry));
        vm.warp(block.timestamp + 1 days);
        multisig.executeInitRegistry(address(registry));
        (bytes31 s,) = singleton.namespace(address(registry));
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(s, bytes31("@salva"));
    }

    function test_enforce_0x40_prefix_For_Namespace() external {
        _changePrank(owner);
        (address newReg,,) =
            multisig.proposeInitRegistry(".salva", address(singleton), address(factory));
        multisig.validateRegistryInit(newReg);
        vm.warp(block.timestamp + 1 days);
        vm.expectRevert(Errors.Errors__InvalidAddressOrNamespaceFormat.selector);
        multisig.executeInitRegistry(newReg);
    }

    function test_Namespace_Is_Initialized_Once() external initialized {
        _changePrank(owner);
        (address newReg,,) =
            multisig.proposeInitRegistry("@salva", address(singleton), address(factory));
        multisig.validateRegistryInit(newReg);
        vm.warp(block.timestamp + 1 days);
        vm.expectRevert(Errors.Errors__DoubleInitialization.selector);
        multisig.executeInitRegistry(newReg);
    }
}
