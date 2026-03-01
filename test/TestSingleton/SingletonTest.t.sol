// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {SalvaRegistry} from "../../src/SalvaRegistry/Registry.sol";
import {DeploySingleton} from "../../script/DeploySingleton.s.sol";

contract TestSingleton is Test {
    Singleton private singleton;
    SalvaRegistry private registry;
    address private owner;
    address private registrar;
    address private EOA = makeAddr("EOA");
    uint128 private acctNumber = 1246371524;

    function setUp() external {
        DeploySingleton deploy = new DeploySingleton();
        (singleton, registry, owner, registrar) = deploy.run();
    }

    modifier initialized() {
        vm.prank(owner);
        registry.initialize();
        _;
    }

    function test_Initialize() external {
        vm.prank(owner);
        uint256 prevGas = gasleft();
        registry.initialize();

        uint256 currentGasLeft = gasleft();
        uint256 totalGasSpent = prevGas - currentGasLeft;

        console.log("PREV GAS: ", prevGas);
        console.log("CURRENT GAS: ", currentGasLeft);
        console.log("TOTAL GAS SPENT: ", totalGasSpent);

        assertEq(registry.namespace(address(registry)), 1);
    }

    function test_linkNumber() external initialized {
        vm.prank(registrar);
        uint256 prevGas = gasleft();
        registry.linkNumber(acctNumber, EOA);

        uint256 currentGasLeft = gasleft();
        uint256 totalGasSpent = prevGas - currentGasLeft;

        console.log("PREV GAS: ", prevGas);
        console.log("CURRENT GAS: ", currentGasLeft);
        console.log("TOTAL GAS SPENT: ", totalGasSpent);

        assertEq(registry.resolveAddress(acctNumber, address(registry)), EOA);
    }
}
