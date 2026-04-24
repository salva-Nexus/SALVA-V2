// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "@BaseRegistry/BaseRegistry.sol";
import { Errors } from "@Errors/Errors.sol";
import { Setup } from "@Setup/Setup.t.sol";

contract BaseRegistryTest is Setup {
    function test_Cannot_Init_After_First_Init() external {
        _changePrank(address(multisig));
        address clone = _deployRegistry("@coinbase");

        vm.expectRevert(Errors.Errors__AlreadyInitialized.selector);
        BaseRegistry(clone).initialize(address(0x123), address(0x456), "@anothernspace");
    }

    function test_Resolve_Address() external {
        _changePrank(address(multisig));
        address clone = _deployRegistry("@coinbase");
        // forge-lint: disable-next-line(unsafe-typecast)
        singleton.initializeRegistry(clone, bytes31("@coinbase"), 0x09);

        _changePrank(owner);
        bytes memory name = bytes("cboi");
        bytes memory sig = _computeSignature(name, address(0x123), owner);
        _approve(clone, factory.getFee());
        _link(name, address(0x123), clone, sig, 0);

        address expectedAddr = BaseRegistry(clone).resolveAddress(bytes("cboi@coinbase"));
        assertEq(expectedAddr, address(0x123));
    }

    function test_Only_Registry_Can_Call_Singleton_Directly(address _clone) external {
        vm.assume(_clone != address(registry));
        bytes memory _name = bytes("okoronkwo_charles");
        vm.expectRevert(Errors.Errors__NotRegistered.selector);
        singleton.linkNameAlias(_name, EOA, EOA);
    }
}
