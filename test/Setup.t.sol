// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "@BaseRegistry/BaseRegistry.sol";
import { BaseTest } from "@BaseTest/BaseTest.t.sol";
import { MockNGNs } from "@MockNGNs/MockNGNs.sol";
import { MultiSig } from "@MultiSig/MultiSig.sol";
import { RegistryFactory } from "@RegistryFactory/RegistryFactory.sol";
import { Singleton } from "@Singleton/Singleton.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Test, console } from "forge-std/Test.sol";

abstract contract Setup is Test, BaseTest {
    function setUp() external {
        (owner, OWNERKEY) = makeAddrAndKey("OWNER");

        _startBroadcast();
        (EOA, EOAKEY) = makeAddrAndKey("EOA");
        address keyAddr = _rememberKey(EOAKEY);
        assertEq(keyAddr, EOA);
        name = bytes("charles");

        NGNs = address(new MockNGNs());

        //============ MULTISIG ============
        MultiSig msig = new MultiSig();
        bytes memory mInit = abi.encodeWithSelector(multisig.initialize.selector);
        multisig = MultiSig(address(new ERC1967Proxy(address(msig), mInit)));

        //============ SINGLETON ============
        Singleton sn = new Singleton();
        bytes memory sInit =
            abi.encodeWithSelector(singleton.initialize.selector, address(multisig));
        singleton = Singleton(address(new ERC1967Proxy(address(sn), sInit)));

        //============ REGISTRY AND FACTORY ============
        RegistryFactory ft = new RegistryFactory();
        BaseRegistry bRegistry = new BaseRegistry();
        bytes memory fInit = abi.encodeWithSelector(
            factory.initialize.selector, address(bRegistry), address(multisig), owner, NGNs
        );
        factory = RegistryFactory(address(new ERC1967Proxy(address(ft), fInit)));

        (address salvaRegistry,,) =
            multisig.proposeInitRegistry("@salva", address(singleton), address(factory));
        registry = BaseRegistry(salvaRegistry);

        multisig.updateFactoryFee(address(factory), 100e6);

        _stopBroadcast();
    }

    function test_ToBytes() external view {
        string memory _name = "cboi";
        singleton.nameToByte(_name);
    }
}
