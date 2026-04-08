// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Singleton} from "../../src/SalvaSingleton/Singleton.sol";
import {MultiSig} from "../../src/SalvaMultiSig/MultiSig.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {RegistryFactory} from "@RegistryFactory/RegistryFactory.sol";

contract NameLengthManipulationPOC is Test {
    Singleton public singleton;
    BaseRegistry internal registry;
    address public constant USER = address(0x123);
    address public constant WALLET = address(0x456);

    bytes public testName = bytes("sandra_eber"); // exactly 11 bytes

    function setUp() public {
        MultiSig multiSigImpl = new MultiSig();
        bytes memory initData = abi.encodeWithSelector(multiSigImpl.initialize.selector);
        MultiSig multiSig = MultiSig(address(new ERC1967Proxy(address(multiSigImpl), initData)));

        Singleton impl = new Singleton();
        bytes memory sInit = abi.encodeWithSelector(impl.initialize.selector, address(multiSig));
        singleton = Singleton(address(new ERC1967Proxy(address(impl), sInit)));

        RegistryFactory factory = new RegistryFactory(address(new BaseRegistry()), address(multiSig), WALLET);
        multiSig.setSingletonAndFactory(address(singleton), address(factory));
        registry = BaseRegistry(multiSig.deployAndProposeInit("@salva"));

        multiSig.validateRegistry(address(registry));
        vm.warp(block.timestamp + 48 hours);
        multiSig.executeInit(address(registry));
    }

    function test_NameLengthManipulation() public {
        uint256[] memory lengthsToTest = new uint256[](6);
        lengthsToTest[0] = 11; // correct length → should pass
        lengthsToTest[1] = 10; // shorter
        lengthsToTest[2] = 8;
        lengthsToTest[3] = 5;
        lengthsToTest[4] = 4;
        lengthsToTest[5] = 15; // longer than actual data

        for (uint256 i = 0; i < lengthsToTest.length; i++) {
            uint256 forcedLength = lengthsToTest[i];

            bytes memory maliciousCalldata = abi.encodeWithSelector(
                singleton.linkNameAlias.selector,
                testName, // always the full 11-byte data
                WALLET,
                USER
            );

            // Manipulate only the length field
            assembly {
                let nameOffset := mload(add(maliciousCalldata, 0x24))
                let nameDataPtr := add(maliciousCalldata, add(0x24, nameOffset))
                mstore(nameDataPtr, forcedLength)
            }

            vm.prank(address(registry));
            (bool success, bytes memory ret) = address(singleton).call(maliciousCalldata);

            console.log("--- Testing declared length:", forcedLength);
            console.log("    Success:", success);

            if (!success) {
                console.log("    Revert selector:");
                console.logBytes(ret);
            }
        }

        vm.stopPrank();
    }
}
