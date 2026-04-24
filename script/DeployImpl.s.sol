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
        // NGN Testnet -> 0xae7597fa3414Bc94254fA7777663882355ED6Cb7
        // Singleton singProxyMainnet = Singleton();
        // Singleton singProxyTestnet = Singleton(0x6d40bf25Ffc5eeB200bb19b7D44c8e2A761f87ab);
        // MultiSig multsigproxyMainnet = MultiSig();
        // MultiSig multsigproxyTestnet = MultiSig(0x02cB7053Bcfc485439F2E2ca10a5AEFF309454B3);
        // RegistryFactory factoryProxyMainnet = RegistryFactory();
        // RegistryFactory factoryProxyTestnet =
        // RegistryFactory(0xD082979428a6E93d7a350a7D04dd021e37c1528B); MultiSig mulsig = new
        // MultiSig();
        // Singleton singleton = new Singleton();

        // multsigproxyMainnet.upgradeToAndCall(address(mulsig), "");
        // multsigproxyMainnet.upgradeSingleton(address(singleton), "");
    }
}
