// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {MultiSig} from "@MultiSig/MultiSig.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {console} from "forge-std/Test.sol";

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

    function run() external returns (Singleton, MultiSig, BaseRegistry, address, address) {
        if (block.chainid != 31337) {
            (Singleton _singleton, MultiSig multisig, BaseRegistry _registry, address _deployer, address _registrar) =
                deployLive();
            return (_singleton, multisig, _registry, _deployer, _registrar);
        } else {
            (Singleton _singleton, MultiSig multisig, BaseRegistry _registry, address _deployer, address _registrar) =
                deploySingletonForTest();
            return (_singleton, multisig, _registry, _deployer, _registrar);
        }
    }

    function deploySingletonForTest() public broadcast returns (Singleton, MultiSig, BaseRegistry, address, address) {
        MultiSig multisig = new MultiSig();
        Singleton singleton = new Singleton(address(multisig));
        BaseRegistry registry = new BaseRegistry(address(singleton));
        return (singleton, multisig, registry, deployer, registrar);
    }

    function deployLive() public broadcastLive returns (Singleton, MultiSig, BaseRegistry, address, address) {
        MultiSig multisig = new MultiSig();
        Singleton singleton = new Singleton(address(multisig));
        BaseRegistry registry = new BaseRegistry(address(singleton));

        multisig.setSingleton(address(singleton));
        console.log("SINGETON", address(singleton));
        console.log("REGISTRY", address(registry));
        console.log("MULTISIG", address(multisig));
        return (singleton, multisig, registry, msg.sender, msg.sender);
    }
}
