// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { BaseRegistry } from "@BaseRegistry/BaseRegistry.sol";
import { MultiSig } from "@MultiSig/MultiSig.sol";
import { RegistryFactory } from "@RegistryFactory/RegistryFactory.sol";
import { Singleton } from "@Singleton/Singleton.sol";
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

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
        // Singleton singProxyTestnet = Singleton(0x75e36Bb8F36A6aE1799E34E3161719964fECC22C);
        // MultiSig multsigproxyMainnet = MultiSig();
        MultiSig multsigProxyTestnet = MultiSig(0x361A059ae5ef356f70DD535dc3f5A7db59350Ec6);
        // RegistryFactory factoryProxyMainnet = RegistryFactory();
        RegistryFactory factoryProxyTestnet =
            RegistryFactory(0x7B56bc1e4eFCAED94882F69003087Eef93aC4c41);
        //MultiSig multisig = new MultiSig();
        // Singleton singleton = new Singleton();
        RegistryFactory factory = new RegistryFactory();

        multsigProxyTestnet.cancelUpgrade(address(0x7B56bc1e4eFCAED94882F69003087Eef93aC4c41));

        multsigProxyTestnet.proposeUpgrade(address(factoryProxyTestnet), address(factory), false);
        multsigProxyTestnet.validateUpgrade(address(factory));
        multsigProxyTestnet.executeUpgrade(address(factory));

        // PROPOSAL
        // multsigProxyTestnet.cancelValidatorUpdate(
        //     address(0xF9580bf31a403Eea7D1a6e85725966B18DAc7251)
        // );

        // multsigProxyTestnet.proposeValidatorUpdate(
        //     address(0xF9580bf31a403Eea7D1a6e85725966B18DAc7251), true
        // );
        // multsigProxyTestnet.validateValidatorUpdate(
        //     address(0xF9580bf31a403Eea7D1a6e85725966B18DAc7251)
        // );
        // multsigProxyTestnet.executeValidatorUpdate(
        //     address(0xF9580bf31a403Eea7D1a6e85725966B18DAc7251)
        // );

        console.log(address(factory));
    }
}
