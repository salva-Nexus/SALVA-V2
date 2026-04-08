// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
// import {Singleton} from "@Singleton/Singleton.sol";
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

    function run() external broadcastLive returns (address) {
        // NGN -> 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C
        // Singleton singProxy = Singleton(0x1E77312B4aF261F411F96aeb2eA20e13934b0D02);
        MultiSig mulsigproxy = MultiSig(0x62f2EEb91A32E4BBEafC74ce8e274bE3c1e336E0);
        // RegistryFactory factory = RegistryFactory(0x7f635559a6A7DbA645be62243279E586D0c66C88)
        MultiSig newImpl = new MultiSig();

        mulsigproxy.upgradeToAndCall(address(newImpl), "");
        console.log(address(newImpl));
        return address(newImpl);
    }
}
