// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "@BaseRegistry/BaseRegistry.sol";
import { MultiSig } from "@MultiSig/MultiSig.sol";
import { RegistryFactory } from "@RegistryFactory/RegistryFactory.sol";
import { Singleton } from "@Singleton/Singleton.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

contract DeployV2 is Script {
    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function run() external {
        deploy();
    }

    function deploy() public broadcast {
        address backend = 0xfD5A9828bac27495FAb7F6174b3de386E0554187;
        address ngns = 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C;

        //============ MULTISIG ============
        MultiSig multisig = new MultiSig();
        bytes memory mInit = abi.encodeWithSelector(multisig.initialize.selector);
        MultiSig wrappedMultiSig = MultiSig(address(new ERC1967Proxy(address(multisig), mInit)));

        //============ SINGLETON ============
        Singleton singleton = new Singleton();
        bytes memory sInit =
            abi.encodeWithSelector(singleton.initialize.selector, address(wrappedMultiSig));
        Singleton wrappedSingleton =
            Singleton(payable(address(new ERC1967Proxy(address(singleton), sInit))));

        //============ REGISTRY AND FACTORY ============
        RegistryFactory factory = new RegistryFactory();
        BaseRegistry bReg = new BaseRegistry();
        bytes memory fInit = abi.encodeWithSelector(
            factory.initialize.selector, address(bReg), address(wrappedMultiSig), backend, ngns
        );
        RegistryFactory wrappedFactory =
            RegistryFactory(address(new ERC1967Proxy(address(factory), fInit)));

        console.log("SINGLETON: ", address(wrappedSingleton));
        console.log("MULTISIG:  ", address(wrappedMultiSig));
        console.log("FACTORY:   ", address(wrappedFactory));
    }
}
