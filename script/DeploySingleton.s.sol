// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {MultiSig} from "@MultiSig/MultiSig.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@MockV3Aggregator/MockV3Aggregator.sol";

contract DeploySingleton is Script {
    uint256 deployerKey;
    address deployer;
    address registrar;

    constructor() {
        (deployer, deployerKey) = makeAddrAndKey("OWNER");
        registrar = makeAddr("registrar");
    }

    modifier broadcast() {
        vm.startBroadcast(deployerKey);
        _;
        vm.stopBroadcast();
    }

    modifier broadcastLive() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function run() external returns (Singleton, MultiSig, BaseRegistry, address, uint256, address, MockV3Aggregator) {
        if (block.chainid != 31337) {
            (
                Singleton _singleton,
                MultiSig multisig,
                BaseRegistry _registry,
                address _deployer,
                uint256 key,
                address _registrar,
                MockV3Aggregator mockEth
            ) = deployLive();
            return (_singleton, multisig, _registry, _deployer, key, _registrar, mockEth);
        } else {
            (
                Singleton _singleton,
                MultiSig multisig,
                BaseRegistry _registry,
                address _deployer,
                uint256 key,
                address _registrar,
                MockV3Aggregator mockEth
            ) = deploySingletonForTest();
            return (_singleton, multisig, _registry, _deployer, key, _registrar, mockEth);
        }
    }

    function deploySingletonForTest()
        public
        broadcast
        returns (Singleton, MultiSig, BaseRegistry, address, uint256, address, MockV3Aggregator)
    {
        MockV3Aggregator mockEth = new MockV3Aggregator(8, 2000e8);
        MultiSig multisig = new MultiSig();
        Singleton singleton = new Singleton(address(multisig));
        BaseRegistry registry = new BaseRegistry(address(singleton), deployer, "@salva", address(mockEth));
        multisig.setSingleton(address(singleton));
        return (singleton, multisig, registry, deployer, deployerKey, registrar, mockEth);
    }

    function deployLive()
        public
        broadcastLive
        returns (Singleton, MultiSig, BaseRegistry, address, uint256, address, MockV3Aggregator)
    {
        address dataFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        address backend = 0xfD5A9828bac27495FAb7F6174b3de386E0554187;
        MultiSig multisig = new MultiSig();
        Singleton singleton = new Singleton(address(multisig));
        BaseRegistry registry = new BaseRegistry(address(singleton), backend, "@salva", dataFeed);
        MockV3Aggregator mockEth = new MockV3Aggregator(8, 2000e8);

        multisig.setSingleton(address(singleton));
        console.log("SINGETON", address(singleton));
        console.log("REGISTRY", address(registry));
        console.log("MULTISIG", address(multisig));
        return (singleton, multisig, registry, msg.sender, 0, msg.sender, mockEth);
    }
}
