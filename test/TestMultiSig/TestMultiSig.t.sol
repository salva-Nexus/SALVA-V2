// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "@BaseTest/BaseTest.t.sol";
import {Errors} from "@Errors/Errors.sol";

abstract contract TestMultiSig is BaseTest {
    function test_Only_Active_Validator_Can_Propose() external {
        _changePrank(EOA);
        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Not_Authorized.selector));
        multisig.proposeInitialization("@salva", address(registry));

        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Not_Authorized.selector));
        multisig.proposeValidatorUpdate(owner, false);
    }

    function test_Reject_Reproposal_Or_Validator_Update() external initialized validatorUpdate {
        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Registry_Init_Proposed.selector));
        multisig.proposeInitialization("@salva", address(registry));

        vm.expectRevert(abi.encodeWithSelector(Errors.Errors__Validator_Update_Proposed.selector));
        multisig.proposeValidatorUpdate(owner, false);
    }

    function test_Quorum_Threshold_is_Correct() external {
        _changePrank(owner);
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        multisig.proposeValidatorUpdate(makeAddr("val1"), true);
        multisig.proposeValidatorUpdate(makeAddr("val2"), true);

        multisig.updateValidator(makeAddr("val"));
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val"));

        _changePrank(makeAddr("val"));
        multisig.updateValidator(makeAddr("val1"));
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val1"));

        multisig.updateValidator(makeAddr("val2"));
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val2"));

        // new proposal to test threshold
        multisig.proposeValidatorUpdate(makeAddr("val3"), true);
        multisig.updateValidator(makeAddr("val3"));

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
        multisig.updateValidator(makeAddr("val3"));

        // but enough time has not passed
        vm.expectRevert(abi.encodeWithSelector(Errors.Error__Invalid_Or_Not_Enough_Time.selector));
        multisig.executeUpdateValidator(makeAddr("val3"));

        // now enough time has paseed
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpdateValidator(makeAddr("val3"));
    }
}
