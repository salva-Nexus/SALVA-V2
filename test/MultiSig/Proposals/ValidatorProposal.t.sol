// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { MultiSig } from "@MultiSig/MultiSig.sol";
import { MultiSigErrors } from "@MultiSigErrors/MultiSigErrors.sol";
import { Setup } from "@Setup/Setup.t.sol";

contract ValidatorProposal is Setup {
    function test_Quorum_Threshold_is_Correct() external {
        _changePrank(owner);
        // ====== Proposal ========
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        multisig.proposeValidatorUpdate(makeAddr("val1"), true);
        multisig.proposeValidatorUpdate(makeAddr("val2"), true);

        // ====== Validate =======
        multisig.validateValidatorUpdate(makeAddr("val"));
        assertEq(multisig.validatorUpdateVotesRemaining(makeAddr("val")), 0);

        multisig.validateValidatorUpdate(makeAddr("val1"));
        assertEq(multisig.validatorUpdateVotesRemaining(makeAddr("val1")), 0);

        multisig.validateValidatorUpdate(makeAddr("val2"));
        assertEq(multisig.validatorUpdateVotesRemaining(makeAddr("val2")), 0);

        // ====== Execute ========
        vm.warp(block.timestamp + 48 hours);
        multisig.executeValidatorUpdate(makeAddr("val"));

        _changePrank(makeAddr("val"));
        vm.warp(block.timestamp + 48 hours);
        multisig.executeValidatorUpdate(makeAddr("val1"));

        vm.warp(block.timestamp + 48 hours);
        multisig.executeValidatorUpdate(makeAddr("val2"));

        // new proposal to test threshold
        multisig.proposeValidatorUpdate(makeAddr("val3"), true);
        assertEq(multisig.validatorUpdateVotesRemaining(makeAddr("val3")), 2);
        multisig.validateValidatorUpdate(makeAddr("val3"));
        assertEq(multisig.validatorUpdateVotesRemaining(makeAddr("val3")), 1);

        // Threshold not met
        vm.expectRevert(
            abi.encodeWithSelector(MultiSigErrors.Errors__TimelockNotElapsedOrNotValidated.selector)
        );
        multisig.executeValidatorUpdate(makeAddr("val3"));

        _changePrank(makeAddr("val2"));
        // Now another validator validates
        multisig.validateValidatorUpdate(makeAddr("val3"));
        assertEq(multisig.validatorUpdateVotesRemaining(makeAddr("val3")), 0);
        // but enough time has not passed

        vm.expectRevert(
            abi.encodeWithSelector(MultiSigErrors.Errors__TimelockNotElapsedOrNotValidated.selector)
        );
        multisig.executeValidatorUpdate(makeAddr("val3"));
        // now enough time has passed
        vm.warp(block.timestamp + 48 hours);
        multisig.executeValidatorUpdate(makeAddr("val3"));
    }

    function test_Recovery_Can_Bypass_Quorum_And_Timelock() external {
        // owner is recovery
        // No warp, this should not revert
        _changePrank(owner);
        // ====== Proposal ========
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        multisig.validateValidatorUpdate(makeAddr("val"));
        multisig.executeValidatorUpdate(makeAddr("val"));

        assertEq(multisig.isValidator(makeAddr("val")), true);
    }

    function test_Validator_Can_Only_Validate_Once() external {
        _changePrank(owner);
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        multisig.validateValidatorUpdate(makeAddr("val"));

        vm.expectRevert(MultiSigErrors.Errors__AlreadyValidated.selector);
        multisig.validateValidatorUpdate(makeAddr("val"));
    }

    function test_Unproposed_Request_Cannot_Be_Validated(address _addr) external {
        _changePrank(owner);
        vm.expectRevert(MultiSigErrors.Errors__ValidatorUpdateNotProposed.selector);
        multisig.validateValidatorUpdate(_addr);
    }

    function test_Flow() external {
        _changePrank(owner);
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        multisig.validateValidatorUpdate(makeAddr("val"));
        multisig.executeValidatorUpdate(makeAddr("val"));

        MultiSig multisig2 = new MultiSig();
        multisig.proposeUpgrade(address(multisig), address(multisig2), true);
        multisig.validateUpgrade(address(multisig2));
        multisig.executeUpgrade(address(multisig2));
    }
}
