// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "@BaseRegistry/BaseRegistry.sol";
import { MultiSig } from "@MultiSig/MultiSig.sol";
import { RegistryFactory } from "@RegistryFactory/RegistryFactory.sol";
import { Singleton } from "@Singleton/Singleton.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Test, console } from "forge-std/Test.sol";

abstract contract BaseTest is Test {
    using MessageHashUtils for bytes32;
    using SafeERC20 for IERC20;

    Singleton internal singleton;
    MultiSig internal multisig;
    RegistryFactory internal factory;
    BaseRegistry internal registry;
    address internal owner;
    uint256 internal OWNERKEY;
    address internal EOA;
    uint256 internal EOAKEY;
    bytes internal name;
    address NGNs;

    // ─────────────────────────────────────────────────────────────────────────
    // MODIFIERS
    // ─────────────────────────────────────────────────────────────────────────

    modifier initialized() {
        _changePrank(owner);
        multisig.validateRegistryInit(address(registry));
        vm.warp(block.timestamp + 1 days);
        multisig.executeInitRegistry(address(registry));
        _;
    }

    modifier proposeAndExecuteValidator() {
        _changePrank(owner);
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        multisig.validateValidatorUpdate(makeAddr("val"));
        multisig.executeValidatorUpdate(makeAddr("val"));
        _;
        _stopPrank();
    }

    modifier validateAndEecuteRegistryInit() {
        _changePrank(owner);
        multisig.validateRegistryInit(address(registry));
        multisig.executeInitRegistry(address(registry));
        _;
        _stopPrank();
    }

    modifier broadcast() {
        vm.startBroadcast(OWNERKEY);
        _;
        vm.stopBroadcast();
    }

    modifier prank(address _prank) {
        _changePrank(_prank);
        _;
        _stopPrank();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────────────────

    function _changePrank(address _prank) internal {
        _stopPrank();
        vm.startPrank(_prank);
    }

    function _stopPrank() internal {
        vm.stopPrank();
    }

    function _sign(address _signer, bytes32 _digest)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        return vm.sign(_signer, _digest);
    }

    function _rememberKey(uint256 _key) internal returns (address keyAddr) {
        return vm.rememberKey(_key);
    }

    function _computeSignature(bytes memory _name, address _wallet, address _signer)
        internal
        pure
        returns (bytes memory _signature)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(_name, _wallet));
        bytes32 digest = messageHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = _sign(_signer, digest);
        _signature = abi.encodePacked(r, s, v);
    }

    function _link(
        bytes memory _name,
        address _wallet,
        address _registry,
        bytes memory _signature,
        bytes4 _revertSelector
    ) internal {
        if (_revertSelector != bytes4(0)) {
            vm.expectRevert(_revertSelector);
            BaseRegistry(_registry).link(_name, _wallet, _signature);
            console.log("Call Reverted As Expected");
        } else {
            BaseRegistry(_registry).link(_name, _wallet, _signature);
            console.log("Call Succeeded");
        }
    }

    function _start(
        bytes memory _name,
        address _wallet,
        address _signer,
        address _prank,
        bytes4 _selector
    ) internal {
        bytes memory sig = _computeSignature(_name, _wallet, _signer);
        _changePrank(_prank);
        _approve(address(registry), factory.getFee());
        _link(_name, _wallet, address(registry), sig, _selector);
    }

    function _deployRegistry(string memory _nspace) internal returns (address) {
        return factory.deployRegistry(address(singleton), address(factory), _nspace);
    }

    function _transfer(address _newPrank) internal {
        IERC20(NGNs).safeTransfer(_newPrank, factory.getFee());
    }

    function _approve(address _addr, uint256 _amount) internal {
        IERC20(NGNs).approve(_addr, _amount);
    }

    function _startBroadcast() internal {
        vm.startBroadcast(OWNERKEY);
    }

    function _stopBroadcast() internal {
        vm.stopBroadcast();
    }
}
