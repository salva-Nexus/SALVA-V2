// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "@Errors/Errors.sol";
import { MultiSig } from "@MultiSig/MultiSig.sol";
import { RegistryFactory } from "@RegistryFactory/RegistryFactory.sol";
import { Setup } from "@Setup/Setup.t.sol";
import { Singleton } from "@Singleton/Singleton.sol";

contract FactoryUpdates is Setup {
    function test_Update_Signer(address _random) external {
        vm.assume(_random != address(multisig));
        address newSigner = address(0x987);
        // Only MultiSig
        _changePrank(_random);
        vm.expectRevert(Errors.Errors__NotAuthorized.selector);
        factory.updateSigner(newSigner);

        _changePrank(owner);
        address proxy = address(factory);
        (address pSigner,) = factory.getSignerAndNGNs();

        multisig.proposeSignerUpdate(proxy, newSigner);
        multisig.validateSignerUpdate(newSigner);
        multisig.executeSignerUpdate(newSigner);

        (address nSigner,) = factory.getSignerAndNGNs();
        assertNotEq(nSigner, pSigner);
    }

    function test_Update_Impl(address _random) external {
        vm.assume(_random != address(multisig));
        address newImpl = address(0x987);
        // Only Multisig
        _changePrank(_random);
        vm.expectRevert(Errors.Errors__NotAuthorized.selector);
        factory.updateImplementation(newImpl);

        _changePrank(owner);
        address proxy = address(factory);
        address pImpl = factory.getBaseRegistryImplementation();

        multisig.proposeBaseRegistryImplUpdate(proxy, newImpl);
        multisig.validateBaseRegistryImplUpdate(newImpl);
        multisig.executeBaseRegistryImplUpdate(newImpl);

        address nImpl = factory.getBaseRegistryImplementation();
        assertNotEq(nImpl, pImpl);
    }

    function test_Update_Fee(address _random) external {
        vm.assume(_random != address(multisig));
        // Only Multisig
        _changePrank(_random);
        vm.expectRevert(Errors.Errors__NotAuthorized.selector);
        factory.updateFee(200e6);

        _changePrank(owner);
        address proxy = address(factory);
        uint256 pFee = factory.getFee();

        multisig.updateFactoryFee(proxy, 200e6);
        uint256 nFee = factory.getFee();

        assertNotEq(nFee, pFee);
    }
}
