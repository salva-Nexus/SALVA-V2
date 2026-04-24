// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "@BaseRegistry/BaseRegistry.sol";
import { Errors } from "@Errors/Errors.sol";
import { Setup } from "@Setup/Setup.t.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Withdrawal is Setup {
    using SafeERC20 for IERC20;

    function test_Withdrawal() external validateAndEecuteRegistryInit {
        bytes memory _name = bytes("okoronkwo_charles");
        _start(_name, owner, owner, owner, 0);
        _transfer(EOA);

        bytes memory _name2 = bytes("okoronkwo_joe");
        _start(_name2, EOA, owner, EOA, 0);

        assertEq(IERC20(NGNs).balanceOf(address(singleton)), 200e6);

        vm.expectRevert(Errors.Errors__NotAuthorized.selector);
        multisig.withdrawFromSingleton(address(singleton), address(NGNs), makeAddr("reciever"));

        _changePrank(owner);
        multisig.withdrawFromSingleton(address(singleton), address(NGNs), makeAddr("reciever"));

        assertEq(IERC20(NGNs).balanceOf(makeAddr("reciever")), 200e6);
        assertEq(IERC20(NGNs).balanceOf(address(singleton)), 0);
    }
}
