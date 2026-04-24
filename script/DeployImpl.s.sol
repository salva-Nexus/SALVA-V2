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
        // Singleton singProxyTestnet = Singleton(0x5A8fce211f5C2e72fA78C0Cfd51C6B1d623e7e02);
        // MultiSig multsigproxyMainnet = MultiSig();
        // MultiSig multsigproxyTestnet = MultiSig(0x85D096203B9B31b20Bd3b8dd2DF8A1D3B6702A6F);
        // RegistryFactory factoryProxyMainnet = RegistryFactory();
        // RegistryFactory factoryProxyTestnet =
        // RegistryFactory(0xF7B6ef741217b94D1a1E3702936327548FAFbe48); MultiSig mulsig = new
        // MultiSig();
        // Singleton singleton = new Singleton();

        // multsigproxyMainnet.upgradeToAndCall(address(mulsig), "");
        // multsigproxyMainnet.upgradeSingleton(address(singleton), "");
    }
}
