// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "@BaseRegistry/BaseRegistry.sol";
import { Errors } from "@Errors/Errors.sol";
import { Setup } from "@Setup/Setup.t.sol";

contract DeployRegistry is Setup {
    function test_Deploy_Success() external {
        _changePrank(address(multisig));
        address clone = factory.deployRegistry(address(singleton), address(factory), "@coinbase");
        assertEq(BaseRegistry(clone).namespace(), "@coinbase");
    }

    function test_Only_Multisig_Can_Deploy_Registry(address _random) external {
        vm.assume(_random != address(multisig));
        _changePrank(_random);
        vm.expectRevert(Errors.Errors__NotAuthorized.selector);
        factory.deployRegistry(address(singleton), address(factory), "@coinbase");
    }

    function test_Signer_Update() external {
        (address oldSigner,) = factory.getSignerAndNGNs();
        assertNotEq(oldSigner, address(0x123));
        _changePrank(address(multisig));
        factory.updateSigner(address(0x123));
        (address newSigner,) = factory.getSignerAndNGNs();
        assertEq(newSigner, address(0x123));
    }

    function test_Update_Fee() external {
        uint256 oldFee = factory.getFee();
        assertNotEq(oldFee, 200e6);
        _changePrank(address(multisig));
        factory.updateFee(200e6);
        uint256 newFee = factory.getFee();
        assertEq(newFee, 200e6);
    }
}
