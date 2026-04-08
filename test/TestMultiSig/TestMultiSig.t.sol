// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseTest} from "@BaseTest/BaseTest.t.sol";
import {Errors} from "@Errors/Errors.sol";
import {console} from "forge-std/Test.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TestMultiSig is BaseTest {
    using SafeERC20 for IERC20;

    function test_Only_Active_Validator_Can_Propose() external {
        _changePrank(EOA);
        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Not_Authorized.selector));
        multisig.proposeInitialization("@salva", address(registry));
        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Not_Authorized.selector));
        multisig.proposeValidatorUpdate(owner, false);
    }

    function test_Reject_Reproposal_Or_Validator_Update() external initialized proposeValidatorUpdate {
        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Registry_Init_Proposed.selector));
        multisig.proposeInitialization("@salva", address(registry));
        //
        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Validator_Update_Proposed.selector));
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
    }

    function test_Quorum_Threshold_is_Correct() external {
        _changePrank(owner);
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        multisig.proposeValidatorUpdate(makeAddr("val1"), true);
        multisig.proposeValidatorUpdate(makeAddr("val2"), true);

        assertEq(multisig._validatorValidationCountRemains(makeAddr("val")), 1);
        multisig.validateValidator(makeAddr("val"));
        assertEq(multisig._validatorValidationCountRemains(makeAddr("val")), 0);
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val"));
        _changePrank(makeAddr("val"));
        multisig.validateValidator(makeAddr("val1"));
        assertEq(multisig._validatorValidationCountRemains(makeAddr("val1")), 0);
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val1"));
        multisig.validateValidator(makeAddr("val2"));
        assertEq(multisig._validatorValidationCountRemains(makeAddr("val2")), 0);
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val2"));

        // new proposal to test threshold
        multisig.proposeValidatorUpdate(makeAddr("val3"), true);
        assertEq(multisig._validatorValidationCountRemains(makeAddr("val3")), 2);
        multisig.validateValidator(makeAddr("val3"));
        assertEq(multisig._validatorValidationCountRemains(makeAddr("val3")), 1);
        vm.expectRevert(abi.encodeWithSelector(Errors.Error__Invalid_Or_Not_Enough_Time.selector));
        multisig.executeUpdateValidator(makeAddr("val3"));
        vm.expectRevert(abi.encodeWithSelector(Errors.Error__Invalid_Or_Not_Enough_Time.selector));
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val3"));
        _changePrank(makeAddr("val2"));
        vm.expectRevert(abi.encodeWithSelector(Errors.Error__Invalid_Or_Not_Enough_Time.selector));
        multisig.executeUpdateValidator(makeAddr("val3"));
        vm.expectRevert(abi.encodeWithSelector(Errors.Error__Invalid_Or_Not_Enough_Time.selector));
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val3"));
        // Now another validator validates
        multisig.validateValidator(makeAddr("val3"));
        assertEq(multisig._validatorValidationCountRemains(makeAddr("val3")), 0);
        // but enough time has not passed
        vm.expectRevert(abi.encodeWithSelector(Errors.Error__Invalid_Or_Not_Enough_Time.selector));
        multisig.executeUpdateValidator(makeAddr("val3"));
        // now enough time has paseed
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val3"));
    }

    function test_Stop_Execution() external proposeInit proposeValidatorUpdate {
        multisig.validateRegistry(address(registry));
        multisig.validateValidator(makeAddr("val"));
        // cancel before time passes
        multisig.cancelInit(address(registry));
        multisig.cancelValidatorUpdate(makeAddr("val"));
        // Execution reverts
        vm.warp(block.timestamp + 48 hours);
        vm.expectRevert(Errors.Error__Invalid_Or_Not_Enough_Time.selector);
        multisig.executeInit(address(registry));
        vm.expectRevert(Errors.Error__Invalid_Or_Not_Enough_Time.selector);
        multisig.executeUpdateValidator(makeAddr("val"));
    }

    function test_Only_Validator_Can_Update_Recovery_Singleton_And_Signer(address _random) external {
        vm.assume(_random != owner);
        _changePrank(_random);
        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Not_Authorized.selector));
        multisig.updateRecovery(EOA, true);

        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Not_Authorized.selector));
        multisig.upgradeSingleton(makeAddr("new impl"), "");

        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Not_Authorized.selector));
        multisig.updateSigner(makeAddr("new signer"));
    }

    function test_deploy_Clones() external {
        _changePrank(owner);
        address coinbaseReg = multisig.deployAndProposeInit("@coinbase");
        address metamaskReg = multisig.deployAndProposeInit("@metamask");

        multisig.validateRegistry(coinbaseReg);
        multisig.validateRegistry(metamaskReg);

        vm.warp(block.timestamp + 48 hours);
        multisig.executeInit(coinbaseReg);
        vm.warp(block.timestamp + 48 hours);
        multisig.executeInit(metamaskReg);

        (bytes16 expectCoinbase,) = singleton.namespace(coinbaseReg);
        (bytes16 expectMetamask,) = singleton.namespace(metamaskReg);
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(expectCoinbase, bytes16(bytes("@coinbase")));
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(expectMetamask, bytes16(bytes("@metamask")));

        console.log(coinbaseReg);
        console.log(metamaskReg);
    }

    function test_New_Clones() external {
        _changePrank(owner);
        address coinbaseReg = multisig.deployAndProposeInit("@coinbase");
        address metamaskReg = multisig.deployAndProposeInit("@metamask");

        multisig.validateRegistry(coinbaseReg);
        multisig.validateRegistry(metamaskReg);

        vm.warp(block.timestamp + 48 hours);
        multisig.executeInit(coinbaseReg);
        vm.warp(block.timestamp + 48 hours);
        multisig.executeInit(metamaskReg);

        address user1 = makeAddr("oc");
        address user2 = makeAddr("oj"); // 0xF023284F44A67F64c46E35d8bbdd5D9b39DCA4b2
        IERC20(usdc).safeTransfer(user1, 1e6);
        IERC20(usdc).safeTransfer(user2, 1e6);

        bytes memory signature1 = _computeSignature(bytes("okoronkwo_charles"), user1, owner);
        bytes memory signature2 = _computeSignature(bytes("okoronkwo_joe"), user2, owner);

        _changePrank(user1);
        IERC20(usdc).approve(coinbaseReg, 1e6);
        _link(bytes("okoronkwo_charles"), user1, signature1, coinbaseReg, false, 0);

        _changePrank(user2);
        IERC20(usdc).approve(metamaskReg, 1e6);
        _link(bytes("okoronkwo_joe"), user2, signature2, metamaskReg, false, 0);

        assertEq(BaseRegistry(coinbaseReg).resolveAddress("okoronkwo_charles@coinbase"), user1);
        assertEq(BaseRegistry(coinbaseReg).resolveAddress("charles_okoronkwo@coinbase"), user1);
        assertNotEq(BaseRegistry(coinbaseReg).resolveAddress("okoronkwo_charles@metamask"), user1);
        assertEq(BaseRegistry(metamaskReg).resolveAddress("okoronkwo_joe@metamask"), user2);
        assertEq(BaseRegistry(metamaskReg).resolveAddress("joe_okoronkwo@metamask"), user2);
        assertNotEq(BaseRegistry(coinbaseReg).resolveAddress("okoronkwo_joe@coinbase"), user2);
    }

    function test_Recovery_Can_Bypass_Quorum() external {
        _changePrank(owner);
        address rec = makeAddr("rec");
        multisig.updateRecovery(rec, true);
        address coinbaseReg = multisig.deployAndProposeInit("@coinbase");

        _changePrank(rec);
        multisig.validateRegistry(coinbaseReg);

        vm.warp(block.timestamp + 48 hours);
        multisig.executeInit(coinbaseReg);
    }
}
