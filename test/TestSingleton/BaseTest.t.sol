// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSig} from "@MultiSig/MultiSig.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {Test, console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@MockV3Aggregator/MockV3Aggregator.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

abstract contract BaseTest is Test {
    using MessageHashUtils for bytes32;

    Singleton internal singleton;
    MultiSig internal multisig;
    BaseRegistry internal registry;
    address internal owner;
    uint256 internal OWNERKEY;
    address internal registrar;
    address internal EOA;
    uint256 internal EOAKEY;
    uint256 internal number;
    bytes internal name;
    MockV3Aggregator internal mockEth;

    modifier initialized() {
        // MultiSig Validation
        _changePrank(owner);
        multisig.validateRegistry(address(registry));
        vm.warp(block.timestamp + 48 hours);
        multisig.executeInit(address(registry));
        _;
        _stopPrank();
    }

    modifier proposeInit() {
        _changePrank(owner);
        multisig.deployAndProposeInit("@coinbase");
        _;
        _stopPrank();
    }

    modifier proposeValidatorUpdate() {
        _changePrank(owner);
        multisig.proposeValidatorUpdate(makeAddr("val"), true);
        _;
        _stopPrank();
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

    function _sign(address _signer, bytes32 _digest) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        return vm.sign(_signer, _digest);
    }

    function _rememberKey(uint256 _key) internal returns (address keyAddr) {
        return vm.rememberKey(_key);
    }

    function _getFee() internal view returns (uint256 _fee) {
        _fee = singleton.getFeeInEth(address(mockEth));
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
        bytes memory _signature,
        address _registry,
        bool _eRevert,
        bytes4 _revertSelector
    ) internal {
        bytes memory data = abi.encodeWithSelector(registry.link.selector, _name, _wallet, _signature);
        uint256 fee = _getFee();
        if (_eRevert) {
            vm.expectRevert(_revertSelector);
        }
        (bool success,) = _registry.call{value: fee}(data);
        console.log(success);
    }
}
