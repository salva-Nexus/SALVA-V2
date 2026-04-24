// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "@Errors/Errors.sol";
import { MultiSig } from "@MultiSig/MultiSig.sol";
import { RegistryFactory } from "@RegistryFactory/RegistryFactory.sol";
import { Setup } from "@Setup/Setup.t.sol";
import { Singleton } from "@Singleton/Singleton.sol";

contract PauseAndUnpause is Setup {
    function test_Update_States_Across_Contracts() external initialized {
        _changePrank(owner);
        address sProxy = address(singleton);
        address mProxy = address(multisig);
        address fProxy = address(factory);

        address[3] memory proxies = [sProxy, mProxy, fProxy];
        for (uint256 i = 0; i < proxies.length;) {
            if (proxies[i] == address(multisig)) {
                multisig.pauseState(proxies[i], 0);
            } else {
                multisig.pauseState(proxies[i], 1);
            }
            unchecked {
                i++;
            }
        }

        // multisig
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        multisig.validateValidatorUpdate(makeAddr("val"));
        vm.expectRevert(Errors.Errors__NotAuthorized.selector);
        multisig.executeValidatorUpdate(makeAddr("val"));

        // Factory
        _changePrank(address(multisig));
        vm.expectRevert(Errors.Errors__NotAuthorized.selector);
        factory.getSignerAndNGNs();

        // Singleton
        _changePrank(address(registry));
        vm.expectRevert(Errors.Errors__NotAuthorized.selector);
        singleton.linkNameAlias(bytes("cboi"), address(0x123), address(0x987));

        _changePrank(owner);
        for (uint256 j = 0; j < proxies.length;) {
            if (proxies[j] == address(multisig)) {
                multisig.proposeUnpause(proxies[j], 0);
                multisig.validateUnpause(proxies[j]);
                multisig.executeUnpause(proxies[j]);
            } else {
                multisig.proposeUnpause(proxies[j], 1);
                multisig.validateUnpause(proxies[j]);
                multisig.executeUnpause(proxies[j]);
            }
            unchecked {
                j++;
            }
        }

        // ============= Should Pass ===================
        // multisig
        _changePrank(owner);
        multisig.executeValidatorUpdate(makeAddr("val"));

        // Factory
        _changePrank(address(multisig));
        factory.getSignerAndNGNs();

        // Singleton
        _changePrank(address(registry));
        singleton.linkNameAlias(bytes("cboi"), address(0x123), address(0x987));
    }
}
