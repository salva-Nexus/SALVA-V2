// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {MultiSig} from "@MultiSig/MultiSig.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {console} from "forge-std/Test.sol";
//import {RegistryFactory} from "@RegistryFactory/RegistryFactory.sol";

contract DeployImpl is Script {
    modifier broadcastLive() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function run() external broadcastLive {
        // NGN -> 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C
        // Singleton singProxy = Singleton(0xEBEbB3b90048c56067ADaD46ff6Bb1030FEC7764);
        MultiSig multsigproxy = MultiSig(0x2D1277e1Aa451aAA78B8c837aFe8F8fD93F34E3E);
        // RegistryFactory factory = RegistryFactory(0x97F0BCA29304E39936dbf4C58b887DEAE5D9A75B)
        //MultiSig mulsig = new MultiSig();
        Singleton singleton = new Singleton();

        // multsigproxy.upgradeToAndCall(address(newImpl), "");
        multsigproxy.upgradeSingleton(address(singleton), "");
    }
}
