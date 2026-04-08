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
        // Singleton singProxy = Singleton(0xa77eF18F47DE0AcA77faBF329FE0f8820D7F98a6);
        MultiSig mulsigproxy = MultiSig(0x94046D6Dd0c24a7Cec86C4cFa79E2e57CeA0B8b0);
        // RegistryFactory factory = RegistryFactory(0xc7FaE1130caE1cB57B58316b8154f761369185b2)
        MultiSig newImpl = new MultiSig();

        mulsigproxy.upgradeToAndCall(address(newImpl), "");
        console.log(address(newImpl));
        return address(newImpl);
    }
}
