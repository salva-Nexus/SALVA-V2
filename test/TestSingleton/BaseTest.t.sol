// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSig} from "@MultiSig/MultiSig.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {SalvaRegistry} from "@SalvaRegistry/Registry.sol";
import {Test} from "forge-std/Test.sol";

abstract contract BaseTest is Test {
    Singleton internal singleton;
    MultiSig internal multisig;
    SalvaRegistry internal registry;
    address internal owner;
    address internal registrar;
    address internal EOA;
    uint128 internal acctNumber;
    string internal name;

    modifier initialized() {
        // MultiSig Validation
        _changePrank(owner);
        multisig.proposeInitialization("@salva", address(registry));
        multisig.validateRegistry(address(registry));
        vm.warp(block.timestamp + 48 hours);
        multisig.executeInit(address(registry));
        _changePrank(registrar);
        _;
        _stopPrank();
    }

    modifier initializedRegistry2() {
        _changePrank(owner);
        SalvaRegistry reg = new SalvaRegistry(address(singleton), owner);
        multisig.proposeInitialization("@coinbase", address(reg));
        multisig.validateRegistry(address(reg));
        vm.warp(block.timestamp + 48 hours);
        multisig.executeInit(address(reg));
        _;
        _stopPrank();
    }

    modifier proposeInit() {
        _changePrank(owner);
        multisig.proposeInitialization("@coinbase", address(registry));
        _;
        _stopPrank();
    }

    modifier proposeValidatorUpdate() {
        _changePrank(owner);
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        _;
        _stopPrank();
    }

    modifier linkNumber() {
        registry.linkNumber(acctNumber, EOA);
        _;
    }

    modifier linkName() {
        registry.linkName(name, EOA);
        _;
    }

    modifier prank(address _prank) {
        _changePrank(_prank);
        _;
        _stopPrank();
    }

    function _changePrank(address _prank) internal {
        _stopPrank();
        vm.startPrank(_prank);
    }

    function _stopPrank() internal {
        vm.stopPrank();
    }
}
