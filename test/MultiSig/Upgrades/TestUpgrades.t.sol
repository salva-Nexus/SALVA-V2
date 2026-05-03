// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "@Errors/Errors.sol";
import { MultiSig } from "@MultiSig/MultiSig.sol";
import { MultiSigErrors } from "@MultiSigErrors/MultiSigErrors.sol";
import { RegistryFactory } from "@RegistryFactory/RegistryFactory.sol";
import { Setup } from "@Setup/Setup.t.sol";
import { Singleton } from "@Singleton/Singleton.sol";

contract TestUpgrades is Setup {
    function test_Upgrade_Singleton() external {
        _changePrank(owner);
        address proxy = address(singleton);
        address pImpl = singleton.getImplementation();
        Singleton sn = new Singleton();

        (, uint256 req) = multisig.proposeUpgrade(proxy, address(sn), false);
        assertEq(req, 1);
        (, uint256 req2) = multisig.validateUpgrade(address(sn));
        assertEq(req2, 0);
        multisig.executeUpgrade(address(sn));

        address nImpl = singleton.getImplementation();
        assertNotEq(nImpl, pImpl);
    }

    function test_Upgrade_Factory() external {
        _changePrank(owner);
        address proxy = address(factory);
        address pImpl = factory.getImplementation();
        RegistryFactory ft = new RegistryFactory();

        (, uint256 req) = multisig.proposeUpgrade(proxy, address(ft), false);
        assertEq(req, 1);
        (, uint256 req2) = multisig.validateUpgrade(address(ft));
        assertEq(req2, 0);
        multisig.executeUpgrade(address(ft));

        address nImpl = factory.getImplementation();
        assertNotEq(nImpl, pImpl);
    }

    function test_Upgrade_Multisig() external {
        _changePrank(owner);
        address proxy = address(multisig);
        address pImpl = multisig.getImplementation();
        MultiSig msig = new MultiSig();

        (, uint256 req) = multisig.proposeUpgrade(proxy, address(msig), true);
        assertEq(req, 1);
        (, uint256 req2) = multisig.validateUpgrade(address(msig));
        assertEq(req2, 0);
        multisig.executeUpgrade(address(msig));

        address nImpl = multisig.getImplementation();
        assertNotEq(nImpl, pImpl);
    }

    function test_Only_Recovery_Can_ByPass() external proposeAndExecuteValidator {
        address validator = makeAddr("val");
        _changePrank(validator);
        address proxy = address(multisig);
        MultiSig msig = new MultiSig();

        multisig.proposeUpgrade(proxy, address(msig), true);
        multisig.validateUpgrade(address(msig));
        // time hasn't passed
        vm.expectRevert(MultiSigErrors.Errors__TimelockNotElapsedOrNotValidated.selector);
        multisig.executeUpgrade(address(msig));

        // time has passed
        vm.warp(block.timestamp + 48 hours);
        multisig.executeUpgrade(address(msig));
    }
}
