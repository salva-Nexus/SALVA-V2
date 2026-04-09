// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseTest} from "@BaseTest/BaseTest.t.sol";
import {DeploySingleton} from "../../script/DeploySingleton.s.sol";
import {Singleton} from "@Singleton/Singleton.sol";
// import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {Test, console} from "forge-std/Test.sol";
import {TestMultiSig} from "@TestMultiSig/TestMultiSig.t.sol";
import {Errors} from "@Errors/Errors.sol";
import {MockUSDC} from "@MockUSDC/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestSingleton is Test, BaseTest, TestMultiSig {
    using SafeERC20 for IERC20;

    function setUp() external {
        DeploySingleton deploy = new DeploySingleton();
        (singleton, multisig, registry, owner, OWNERKEY) = deploy.run();

        (EOA, EOAKEY) = makeAddrAndKey("EOA");
        address keyAddr = _rememberKey(EOAKEY);
        assertEq(keyAddr, EOA);
        name = bytes("charles");

        _changePrank(owner);
        usdc = address(new MockUSDC());
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
        _start(_name, owner, owner, owner, 0);

        assertEq(singleton.resolveAddress(bytes("okoronkwo_charles@salva")), owner);
        assertEq(singleton.resolveAddress(bytes("charles_okoronkwo@salva")), owner);
    }

    function test_link_From_External_Source() external initialized {
        // SHOULD REVERT
        bytes memory _name = bytes("okoronkwo_charles");
        bytes4 revertSelector = Errors.Errors__Invalid_Call_Source.selector;
        _start(_name, EOA, EOA, EOA, revertSelector);
    }

    function test_Unlink_Name() external initialized {
        _changePrank(owner);
        _transfer(EOA);

         bytes memory _name = bytes("okoronkwo_charles");
        _start(_name, EOA, owner, EOA, 0);


        address linked = registry.resolveAddress(bytes("okoronkwo_charles@salva"));
        assertEq(linked, EOA);
        console.log(linked);

        registry.unlink(bytes("okoronkwo_charles"));

        address unlinked = registry.resolveAddress(bytes("okoronkwo_charles@salva"));
        assertNotEq(unlinked, linked);
        console.log(unlinked);
    }

    function test_Phishing_Resistance() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        _start(_name, EOA, owner, EOA, 0);
        // stopped

        _changePrank(owner);
        _transfer(EOA);
        _transfer(makeAddr("EOA2"));
        
        _changePrank(makeAddr("EOA2"));
        bytes memory _name0 = bytes(unicode"okoronkwо_charles");
        bytes4 revertSelector = Errors.Errors__Invalid_Character.selector;
        _start(_name0, makeAddr("EOA2"), owner, makeAddr("EOA2"), revertSelector);

        bytes memory _name1 = bytes("okoronkwo-charles");
        _start(_name1, makeAddr("EOA2"), owner, makeAddr("EOA2"), revertSelector);
    }

    function test_Only_Registry_Can_Call_Singleton_Directly() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        vm.expectRevert(Errors.Errors__Not_Registered.selector);
        singleton.linkNameAlias(_name, EOA, EOA);
    }

    function test_Linked_Name_Cannot_Be_Reused() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        _start(_name, owner, owner, owner, 0);
        _transfer(EOA);

        bytes4 expectedRevert = Errors.Errors__Taken.selector;
        _start(_name, EOA, owner, EOA, expectedRevert);
    }

    function test_Name_Not_Exceeding_32_Bytes() external initialized {
        bytes memory _name = bytes("my_name_is_long_and_cause_this_to_revert");
        bytes4 expectedRevert = Errors.Errors__Max_Name_Length_Exceeded.selector;
        _start(_name, owner, owner, owner, expectedRevert);
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
        _start(_name, owner, owner, owner, 0);

        _changePrank(EOA);
        vm.expectRevert(Errors.Errors__Invalid_Sender.selector);
        registry.unlink(_name);
    }

    function test_Upgrade() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        _start(_name, owner, owner, owner, 0);

        multisig.upgradeSingleton(payable(address(new Singleton())), "");
        _transfer(EOA);

        bytes memory _name1 = bytes("okoronkwo_buchi");
        _start(_name1, EOA, owner, EOA, 0);

        assertEq(registry.resolveAddress(bytes("okoronkwo_charles@salva")), owner);
        assertEq(registry.resolveAddress(bytes("okoronkwo_buchi@salva")), EOA);
    }

    function test_Upgrade2() external initialized {
        // Only Multi-Sig
        Singleton singleton2 = new Singleton();
        _changePrank(EOA);
        vm.expectRevert(Errors.Errors__Not_Authorized.selector);
        multisig.upgradeSingleton(payable(address(singleton2)), "");
    }

    function test_updateSigner() external initialized {
       bytes memory _name = bytes("okoronkwo_charles");
        _start(_name, owner, owner, owner, 0);

        multisig.updateSigner(EOA);
        _transfer(EOA);

        bytes memory _name2 = bytes("okoronkwo_joe");
        bytes4 revertSelector = Errors.Errors__Invalid_Call_Source.selector;
        _start(_name2, EOA, owner, EOA, revertSelector);
        

        bytes memory _name3 = bytes("okoronkwo_ben");
        _start(_name3, EOA, EOA, EOA, 0);
    }
 
    function test_Withdrawal() external initialized { 
        bytes memory _name = bytes("okoronkwo_charles");
        _start(_name, owner, owner, owner, 0);
        _transfer(EOA);

        bytes memory _name2 = bytes("okoronkwo_joe");
        _start(_name2, EOA, owner, EOA, 0);

        assertEq(IERC20(usdc).balanceOf(address(singleton)), 2e6);

        vm.expectRevert(Errors.Errors__Not_Authorized.selector);
        multisig.withdraw(address(usdc), makeAddr("reciever"));

        _changePrank(owner);
        multisig.withdraw(address(usdc), makeAddr("reciever"));

        assertEq(IERC20(usdc).balanceOf(makeAddr("reciever")), 2e6);
        assertEq(IERC20(usdc).balanceOf(address(singleton)), 0);
    }

    function test_Replay() external initialized {
        bytes memory _name = bytes("okoronkwo_charles");
        _start(_name, owner, owner, owner, 0);

        address replayer = makeAddr("replayer");
        _transfer(replayer);


        _changePrank(replayer);
        // replayer manages to get the previous signature
        // even though it doesn't make sense for a replayer to use the same addres of the original owner
        // we still have to test, to prove:
        // 1. One gateway through
        // 2. phishing resistance even if gateway is bypassed
        bytes4 selector = Errors.Errors__Taken.selector;
         // should revert from singleton, not registry
        _start(_name, owner, owner, replayer, selector);
    }

    function test_ToBytes() external pure {
        console.log(string(bytes("0x4073616c766100000000000000000000")));
        console.logBytes(bytes("cboi@salva"));

        assertEq(bytes("@salva"), hex"4073616c7661");
    }
}
