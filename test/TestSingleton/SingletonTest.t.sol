// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseTest} from "@BaseTest/BaseTest.t.sol";
import {DeploySingleton} from "../../script/DeploySingleton.s.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {Test, console} from "forge-std/Test.sol";
import {TestMultiSig} from "@TestMultiSig/TestMultiSig.t.sol";
import {Errors} from "@Errors/Errors.sol";
import {MockV3Aggregator} from "@MockV3Aggregator/MockV3Aggregator.sol";

contract TestSingleton is Test, BaseTest, TestMultiSig {
    function setUp() external {
        DeploySingleton deploy = new DeploySingleton();
        (singleton, multisig, registry, owner, OWNERKEY, registrar, mockEth) = deploy.run();

        (EOA, EOAKEY) = makeAddrAndKey("EOA");
        address keyAddr = _rememberKey(EOAKEY);
        assertEq(keyAddr, EOA);
        number = 1246371524;
        name = bytes("charles");

        vm.deal(EOA, 5 ether);
        vm.deal(owner, 5 ether);
    }

    function test_Initialize() external initialized {
        (bytes32 s,) = singleton.namespace(address(registry));
        assertNotEq(s, bytes32(0));
    }

    function test_Only_MultiSig_Can_Initialize() external prank(address(registry)) {
        vm.expectRevert();
        singleton.initializeRegistry(address(registry), "@salva", bytes1(0x06));
    }

    function test_link_With_Signature() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        bytes memory sig = _computeSignature(_name, owner, owner);
        _changePrank(owner);
        _link(_name, owner, sig, false, 0);

        assertEq(address(singleton).balance, _getFee());
        assertEq(owner.balance, 5 ether - _getFee());
        assertEq(singleton.resolveAddress(bytes("okoronkwo_charles@salva")), owner);
        assertEq(singleton.resolveAddress(bytes("charles_okoronkwo@salva")), owner);
    }

    function test_link_From_External_Source() external initialized {
        // SHOULD REVERT
        bytes memory _name = bytes("okoronkwo_charles");
        bytes memory sig = _computeSignature(_name, EOA, EOA);
        bytes4 revertSelector = Errors.Errors__Invalid_Call_Source.selector;
        _changePrank(EOA);
        _link(_name, EOA, sig, true, revertSelector);
    }

    function test_Unlink_Name() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        bytes memory sig = _computeSignature(_name, EOA, owner);
        _changePrank(EOA);
        _link(_name, EOA, sig, false, 0);
        address linked = registry.resolveAddress(bytes("okoronkwo_charles@salva"));
        assertEq(linked, EOA);
        console.log(linked);

        registry.unlink(bytes("okoronkwo_charles"));

        address unlinked = registry.resolveAddress(bytes("okoronkwo_charles@salva"));
        assertNotEq(unlinked, linked);
        console.log(unlinked);
    }

    function test_Phishing_Resistance1() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        bytes memory sig = _computeSignature(_name, EOA, owner);
        _changePrank(EOA);
        _link(_name, EOA, sig, false, 0);

        _changePrank(makeAddr("EOA2"));
        vm.deal(makeAddr("EOA2"), 5 ether);
        bytes memory _name0 = bytes(unicode"okoronkwо_charles");
        bytes memory sig0 = _computeSignature(_name0, makeAddr("EOA2"), owner);
        bytes4 revertSelector = Errors.Errors__Invalid_Character.selector;
        _link(_name0, makeAddr("EOA2"), sig0, true, revertSelector);

        bytes memory _name1 = bytes("okoronkwo-charles");
        bytes memory sig1 = _computeSignature(_name1, makeAddr("EOA2"), owner);
        _link(_name1, makeAddr("EOA2"), sig1, true, revertSelector);
    }

    function test_Only_Registry_Can_Call_Singleton_Directly() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        vm.expectRevert(Errors.Errors__Not_Registered.selector);
        singleton.linkNameAlias(_name, EOA, EOA);
    }

    function test_Linked_Name_Cannot_Be_Reused() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        bytes memory sig = _computeSignature(_name, owner, owner);
        _changePrank(owner);
        _link(_name, owner, sig, false, 0);

        _changePrank(EOA);
        bytes memory _name1 = bytes("okoronkwo_charles");
        bytes memory sig1 = _computeSignature(_name1, EOA, owner);
        bytes4 expectedRevert = Errors.Errors__Taken.selector;
        _changePrank(EOA);
        _link(_name1, EOA, sig1, true, expectedRevert);
    }

    function test_Name_Not_Exceeding_32_Bytes() external initialized {
        bytes memory _name = bytes("my_name_is_long_and_cause_this_to_revert");
        bytes memory sig = _computeSignature(_name, owner, owner);
        bytes4 expectedRevert = Errors.Errors__Max_Name_Length_Exceeded.selector;
        _changePrank(owner);
        _link(_name, owner, sig, true, expectedRevert);
    }

    function test_Arbitrary() external initialized {
        // length manipulation, extra length
        // should revert, cus extra data is 0
        _changePrank(address(registry));
        vm.deal(address(registry), 5 ether);
        bytes memory data1 =
            hex"85b830a60000000000000000000000000000000000000000000000000000000000000060000000000000000000000000f2b2ade8117d3d777a679e73e60795a7e6771f19000000000000000000000000f2b2ade8117d3d777a679e73e60795a7e6771f190000000000000000000000000000000000000000000000000000000000000012636861726c65735f6f6b6f726f6e6b776f000000000000000000000000000000";

        (bool success,) = address(singleton).call(data1);
        assertEq(success, false);

        // Reduced length(not actual length)
        // Should revert
        bytes memory data2 =
            hex"85b830a60000000000000000000000000000000000000000000000000000000000000060000000000000000000000000f2b2ade8117d3d777a679e73e60795a7e6771f19000000000000000000000000f2b2ade8117d3d777a679e73e60795a7e6771f190000000000000000000000000000000000000000000000000000000000000010636861726c65735f6f6b6f726f6e6b776f000000000000000000000000000000";
        (bool success2,) = address(singleton).call(data2);
        assertEq(success2, false);
    }

    function test_arbitrary_User_Cannot_Unlink_Another_User() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        bytes memory sig = _computeSignature(_name, owner, owner);
        _changePrank(owner);
        _link(_name, owner, sig, false, 0);

        _changePrank(EOA);
        vm.expectRevert(Errors.Errors__Invalid_Sender.selector);
        registry.unlink(_name);
    }
}
