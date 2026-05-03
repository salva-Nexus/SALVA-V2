// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { BaseRegistry } from "@BaseRegistry/BaseRegistry.sol";
import { MultiSig } from "@MultiSig/MultiSig.sol";
import { RegistryFactory } from "@RegistryFactory/RegistryFactory.sol";
import { Singleton } from "@Singleton/Singleton.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

contract DeployImpl is Script {
    modifier broadcastLive() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function run() external broadcastLive {
        address ngnsMainnet = address(0x78E9917e6A7D7DD2fd3fc031723741F4f755641C);
        address ngnsTestnet = (0xae7597fa3414Bc94254fA7777663882355ED6Cb7);
        Singleton singProxyMainnet = Singleton(0xc03eDeB2EF48B752ce46600d088206f5334e5546);
        Singleton singProxyTestnet = Singleton(0x75e36Bb8F36A6aE1799E34E3161719964fECC22C);
        MultiSig multsigproxyMainnet = MultiSig(0xd2611e3acE93303052478af5EE5d13e2E9c63C7A);
        MultiSig multsigProxyTestnet = MultiSig(0x361A059ae5ef356f70DD535dc3f5A7db59350Ec6);
        RegistryFactory factoryProxyMainnet =
            RegistryFactory(0xdc2b063198Fa973F37232256Bb822F456332eFc8);
        RegistryFactory factoryProxyTestnet =
            RegistryFactory(0x7B56bc1e4eFCAED94882F69003087Eef93aC4c41);
    }
}
