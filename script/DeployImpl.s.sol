// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { BaseRegistry } from "@BaseRegistry/BaseRegistry.sol";
import { MultiSig } from "@MultiSig/MultiSig.sol";
import { Singleton } from "@Singleton/Singleton.sol";
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";
//import {RegistryFactory} from "@RegistryFactory/RegistryFactory.sol";

contract DeployImpl is Script {
    modifier broadcastLive() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function run() external broadcastLive {
        // NGN Mainnet -> 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C
        // NGN Testnet -> 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C
        // Singleton singProxyMainnet = Singleton();
        // Singleton singProxyTestnet = Singleton(0x95ef0B638899ad4ADCb86D9491D8A3fFf97161C2);
        // MultiSig multsigproxyMainnet = MultiSig();
        // MultiSig multsigproxyTestnet = MultiSig(0x554531E22ec6F851c2BF3C54e7C96EEcd180D274);
        // RegistryFactory factoryProxyMainnet = RegistryFactory();
        // RegistryFactory factoryProxyTestnet =
        // RegistryFactory(0x5713E35498Ec25e5b50ACcb74D55C0AA2b24Ae79); MultiSig mulsig = new
        // MultiSig();
        //Singleton singleton = new Singleton();

        // multsigproxyMainnet.upgradeToAndCall(address(mulsig), "");
        // multsigproxyMainnet.upgradeSingleton(address(singleton), "");
    }
}
