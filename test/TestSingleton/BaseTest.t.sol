// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {MultiSig} from "@MultiSig/MultiSig.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {Test, console} from "forge-std/Test.sol";
// import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseTest is Test {
    using MessageHashUtils for bytes32;
    using SafeERC20 for IERC20;

    Singleton internal singleton;
    MultiSig internal multisig;
    BaseRegistry internal registry;
    address internal owner;
    uint256 internal OWNERKEY;
    address internal registrar;
    address internal EOA;
    uint256 internal EOAKEY;
    bytes internal name;
    address usdc; // base sepolia

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

    function _computeSignature(bytes memory _name, address _wallet, address _signer)
        internal
        pure
        returns (bytes memory _signature)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(_name, _wallet));
        bytes32 digest = messageHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = _sign(_signer, digest);
        console.log(v);
        console.logBytes32(r);
        console.logBytes32(s);
        _signature = abi.encodePacked(r, s, v);
    }

    function _link(
        bytes memory _name,
        address _wallet,
        bytes memory _signature,
        address _registry,
        bytes4 _revertSelector
    ) internal {
        bytes memory data = abi.encodeWithSelector(registry.link.selector, _name, _wallet, usdc, _signature);
        if (_revertSelector > 0) {
            vm.expectRevert(_revertSelector);
        }
        (bool success,) = _registry.call(data);
        console.log(success);
    }

    function _start(bytes memory _name, address _wallet, address _signer, address _prank, bytes4 _selector) internal {
        bytes memory sig = _computeSignature(_name, _wallet, _signer);
        _changePrank(_prank);
        _approve();
        _link(_name, _wallet, sig, address(registry), _selector);
    }

    function _transfer(address _newPrank) internal {
        IERC20(usdc).safeTransfer(_newPrank, 1e6);
    }

    function _approve() internal {
        IERC20(usdc).approve(address(registry), 1e6);
    }
}
