// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseTest} from "@BaseTest/BaseTest.t.sol";
import {DeploySingleton} from "../../script/DeploySingleton.s.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {Test, console} from "forge-std/Test.sol";
import {TestMultiSig} from "@TestMultiSig/TestMultiSig.t.sol";
import {Errors} from "@Errors/Errors.sol";

contract TestSingleton is Test, BaseTest, TestMultiSig {
    function setUp() external {
        DeploySingleton deploy = new DeploySingleton();
        (singleton, multisig, registry, owner, registrar) = deploy.run();

        _changePrank(owner);
        multisig.setSingleton(address(singleton));

        EOA = makeAddr("EOA");
        number = 1246371524;
        name = bytes("charles");
    }

    function test_Initialize() external initialized {
        (bytes32 s,) = singleton.namespace(address(registry));
        assertNotEq(s, bytes32(0));
    }

    function test_Only_MultiSig_Can_Initialize() external prank(address(registry)) {
        vm.expectRevert();
        singleton.initializeRegistry(address(registry), "@salva", bytes1(0x06));
    }

    function test_linkName() external initialized {
        bytes memory _name = bytes("okoronkwo_"); // exactly 29 bytes
        registry.linkToWallet(_name, EOA);
        bytes memory name = bytes("okoronkwo_@salva");
        address addr = singleton.resolveAddress(name);
        console.log(addr);

        // bytes memory _name1 = bytes("okoronkwo_joe");
        // registry.linkToNumber(_name1, number);
        // bytes memory name1 = bytes("okoronkwo_joe@salva");
        // uint256 num = singleton.resolveNumber(name1);
        // console.log(num);
    }

    function test_Unlink_Name() external initialized linkName {
        address linked = registry.resolveAddress(bytes("charles@salva"));
        assertEq(linked, EOA);
        console.log(linked);

        registry.unlink(bytes("charles"));

        address unlinked = registry.resolveAddress(bytes("charles@salva"));
        assertNotEq(unlinked, linked);
        console.log(unlinked);
    }

    function test_Phishing_Resistance() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        registry.linkToWallet(_name, EOA);

        bytes memory _name0 = bytes(unicode"okoronkwо_charles");
        vm.expectRevert(Errors.Errors__Invalid_Character.selector);
        registry.linkToWallet(_name0, EOA);

        bytes memory _name1 = bytes("charles_okoronkwo"); // inverted
        vm.expectRevert(Errors.Errors__Taken.selector);
        registry.linkToNumber(_name1, number);

        bytes memory _name2 = bytes("okoronkwo-charles");
        vm.expectRevert(Errors.Errors__Invalid_Character.selector);
        registry.linkToWallet(_name2, EOA);
    }

    function test_Enforce_Prefix() external prank(owner) {
        string memory IDENTIFIER = ".coinbase";
        BaseRegistry reg = new BaseRegistry(address(singleton), owner);

        multisig.proposeInitialization(IDENTIFIER, address(reg));
        multisig.validateRegistry(address(reg));

        vm.warp(block.timestamp + 48 hours);
        vm.expectRevert();
        multisig.executeInit(address(reg));
    }

    function test_Only_Registry_Can_Link() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        vm.expectRevert(Errors.Errors__Not_Registered.selector);
        singleton.linkNameAlias(_name, EOA, 0);

        vm.expectRevert(Errors.Errors__Not_Registered.selector);
        singleton.linkNameAlias(_name, address(0), number);
    }

    function test_Linked_Name_Cannot_Be_Reused() external initialized linkName {
        vm.expectRevert(Errors.Errors__Taken.selector);
        registry.linkToWallet(name, address(0x123));
    }

    function test_Name_Not_Exceeding_32_Bytes() external initialized {
        bytes memory _name = bytes("my_name_is_long_and_cause_this_to_revert");
        vm.expectRevert(Errors.Errors__Max_Name_Length_Exceeded.selector);
        registry.linkToWallet(_name, EOA);
    }

    function test_Arbitrary() external initialized prank(address(registry)) {
        // length manipulation, extra length
        // should revert, cus extra data is 0
        bytes memory data1 =
            hex"b7151e5b0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000C958B338b1cE6ADd8f9CcfB102905a59c28e91Fc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000126f6b6f726f6e6b776f5f636861726c6573000000000000000000000000000000";
        (bool success,) = address(singleton).call(data1);
        assertEq(success, false);

        // Reduced length(not actual length)
        // Should revert
        bytes memory data2 =
            hex"b7151e5b0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000C958B338b1cE6ADd8f9CcfB102905a59c28e91Fc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000106f6b6f726f6e6b776f5f636861726c6573000000000000000000000000000000";
        (bool success2,) = address(singleton).call(data2);
        assertEq(success2, false);

        // bytes memory data3 =
        //     hex"b7151e5b0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000C958B338b1cE6ADd8f9CcfB102905a59c28e91Fc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000106f6b6f726f6e6b776f5f636861726c6573000000000000000000000000000000";
        // (bool success3,) = address(singleton).call(data3);
        // assertEq(success3, false);

        bytes memory name = bytes("cboi");
        console.logBytes(name);

        bytes memory name1 = bytes("salva_cboi@salva");
        console.logBytes(name1);

        bytes memory name2 = bytes("cboi_salva@salva");
        console.logBytes(name2);
    }
}
