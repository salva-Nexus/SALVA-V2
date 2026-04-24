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
        // Singleton singProxyTestnet = Singleton(0x383418ec4170ed4f93FE18C11BF8437E667Bcb61);
        // MultiSig multsigproxyMainnet = MultiSig();
        MultiSig multsigProxyTestnet = MultiSig(0x9D22b9B449D59bA32435d2155fF184b922205DB1);
        // RegistryFactory factoryProxyMainnet = RegistryFactory();
        // RegistryFactory factoryProxyTestnet =
        // RegistryFactory(0xE777e4038697C0Db37273DA0D50f3022c14e153E);
        // MultiSig mulsig = new MultiSig();
        // Singleton singleton = new Singleton()
        // 0xb298626ec29fcecd98d54ba542c6d391d3123cb7
        multsigProxyTestnet.proposeUpgrade(address(multsigProxyTestnet), address(mulsig), true);
        multsigProxyTestnet.validateUpgrade(address(mulsig));
        multsigProxyTestnet.executeUpgrade(address(mulsig));

        // multsigProxyTestnet.proposeValidatorUpdate(
        //     address(0xF7cB5cd65D10A435A13DC264BaDcc4bd01ef0C43), false
        // );
        // multsigProxyTestnet.validateValidatorUpdate(
        //     address(0xF7cB5cd65D10A435A13DC264BaDcc4bd01ef0C43)
        // );
        // multsigProxyTestnet.executeValidatorUpdate(
        //     address(0xF7cB5cd65D10A435A13DC264BaDcc4bd01ef0C43)
        // );
    }
}
