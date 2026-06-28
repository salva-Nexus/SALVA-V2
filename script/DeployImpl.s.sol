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
        upgrade();
    }

    function upgrade() public {
        // address ngnsMainnet = address(0x78E9917e6A7D7DD2fd3fc031723741F4f755641C);
        // address ngnsTestnet = (0xae7597fa3414Bc94254fA7777663882355ED6Cb7);
        Singleton singProxyMainnet = Singleton(0xD5B1Cb07403b946b536c77a6102723808971c87C);
        // Singleton singProxyTestnet = Singleton(0x75e36Bb8F36A6aE1799E34E3161719964fECC22C);
        MultiSig multsigproxyMainnet = MultiSig(0xd0960377a40E3d554945Bd801EC36c2f62d0d205);
        // MultiSig multsigProxyTestnet = MultiSig(0x361A059ae5ef356f70DD535dc3f5A7db59350Ec6);
        // RegistryFactory factoryProxyMainnet =
        //     RegistryFactory(0x540bC86d5D66A7426C4026ff93D75297Ad4777BB);
        // RegistryFactory factoryProxyTestnet =
        //    RegistryFactory(0x7B56bc1e4eFCAED94882F69003087Eef93aC4c41);

        Singleton newSingleton = new Singleton();
        // MultiSig newMultiSig = new MultiSig();
        // RegistryFactory newFactory = new RegistryFactory();

        address[1] memory proxies = [address(singProxyMainnet)];
        address[1] memory newImpls = [address(newSingleton)];

        for (uint256 i = 0; i < proxies.length;) {
            address proxy = proxies[i];
            address newImpl = newImpls[i];
            if (proxy == address(multsigproxyMainnet)) {
                multsigproxyMainnet.proposeUpgrade(proxy, newImpl, true);
            } else {
                multsigproxyMainnet.proposeUpgrade(proxy, newImpl, false);
            }
            multsigproxyMainnet.validateUpgrade(newImpl);
            multsigproxyMainnet.executeUpgrade(newImpl);

            unchecked {
                i++;
            }
        }

        // console.log("Singleton upgraded to:", address(newSingleton));
    }
}
