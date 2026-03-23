// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseTest} from "@BaseTest/BaseTest.t.sol";
import {DeploySingleton} from "../../script/DeploySingleton.s.sol";
import {SalvaRegistry} from "@SalvaRegistry/Registry.sol";
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
        acctNumber = 1246371524;
        name = "charles";
    }

    function test_Initialize() external initialized {
        (bytes32 s,) = singleton.namespace(address(registry));
        assertNotEq(s, bytes32(0));
    }

    function test_Only_MultiSig_Can_Initialize() external prank(address(registry)) {
        vm.expectRevert();
        singleton.initializeRegistry(address(registry), "@salva");
    }

    function test_linkNumber() external initialized {
        uint256 gasStart = gasleft();
        registry.linkNumber(acctNumber, EOA);
        uint256 gasStop = gasleft();

        console.log("Low Leve Link Number Call: ", gasStart - gasStop);
        address _wallet = registry.resolveViaNumber(acctNumber);
        console.log(_wallet);
        assertEq(_wallet, EOA);
    }

    function test_Unlink_number() external initialized linkNumber {
        address linked = registry.resolveViaNumber(acctNumber);
        assertEq(linked, EOA);

        registry.unlinkNumber(acctNumber);

        assertNotEq(registry.resolveViaNumber(acctNumber), linked);
    }

    function test_linkName() external initialized {
        uint256 gasStart = gasleft();
        registry.linkName(name, EOA);
        uint256 gasStop = gasleft();

        console.log("Low Leve Link Name Call: ", gasStart - gasStop);
        address _wallet = registry.resolveViaName("charles@salva");
        console.log(_wallet);
        assertEq(_wallet, EOA);
    }

    function test_Unlink_Name() external initialized linkName {
        address linked = registry.resolveViaName("charles@salva");
        assertEq(linked, EOA);

        registry.unlinkName("charles");

        address unlinked = registry.resolveViaName("charles@salva");
        assertNotEq(unlinked, linked);
    }

    function test_Phishing_Resistance() external initialized {
        string memory _name = "cb0i";
        vm.expectRevert();
        registry.linkName(_name, EOA);
    }

    function test_Enforce_Prefix() external prank(owner) {
        string memory IDENTIFIER = ".coinbase";
        SalvaRegistry reg = new SalvaRegistry(address(singleton), owner);

        multisig.proposeInitialization(IDENTIFIER, address(reg));
        multisig.validateRegistry(address(reg));

        vm.warp(block.timestamp + 48 hours);
        vm.expectRevert();
        multisig.executeInit(address(reg));
    }

    function test_Only_Registry_Can_Link() external initialized {
        vm.expectRevert();
        singleton.linkNumberAlias(acctNumber, EOA);

        vm.expectRevert();
        singleton.linkNameAlias(name, EOA);
    }

    function test_Linked_Number_Cannot_Be_Reused() external initialized linkNumber {
        vm.expectRevert();
        registry.linkNumber(acctNumber, address(0x123));
    }

    function test_Linked_Wallet_Cannot_Be_Reused() external initialized linkNumber linkName {
        vm.expectRevert();
        registry.linkNumber(9876543210, EOA);

        vm.expectRevert();
        registry.linkName("alice", EOA);
    }

    function test_Revert_Unregistred_Registry() external initialized {
        vm.expectRevert();
        singleton.linkNameAlias(name, EOA);

        vm.expectRevert();
        singleton.linkNumberAlias(acctNumber, EOA);
    }

    function test_Name_Not_Exceeding_16_Bytes() external initialized {
        vm.expectRevert(Errors.Errors__Max_Name_Length_Exceeded.selector);
        registry.linkName("my_name_ns_long_and_cause_this_to_revert", EOA);
    }
}
