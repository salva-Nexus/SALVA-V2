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
        // Singleton singProxy = Singleton(0xaeb9fcC270F240FAA9A7f9d8b84eD6fE5c8f6b61);
        MultiSig multsigproxy = MultiSig(0xEe1195Ba5A9844a5b697A7a7070D7C2FBA0e45f0);
        // RegistryFactory factory = RegistryFactory(0x7c6F02D4A226D0fFd6e0d47b50D0336aDb5c9CD6)
        //MultiSig mulsig = new MultiSig();
        Singleton singleton = new Singleton();

        // multsigproxy.upgradeToAndCall(address(newImpl), "");
        multsigproxy.upgradeSingleton(address(singleton), "");
    }
}
