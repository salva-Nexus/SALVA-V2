// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {SalvaRegistry} from "../src/SalvaRegistry/Registry.sol";
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

    function run() external returns (Singleton, SalvaRegistry, address, address) {
        if (block.chainid != 31337) {
            (Singleton _singleton, SalvaRegistry _registry, address _deployer, address _registrar) = deployLive();
            return (_singleton, _registry, _deployer, _registrar);
        } else {
            (Singleton _singleton, SalvaRegistry _registry, address _deployer, address _registrar) =
                deploySingletonForTest();
            return (_singleton, _registry, _deployer, _registrar);
        }
    }

    function deploySingletonForTest() public broadcast returns (Singleton, SalvaRegistry, address, address) {
        Singleton singleton = new Singleton();
        SalvaRegistry registry = new SalvaRegistry(address(singleton), registrar);
        return (singleton, registry, deployer, registrar);
    }

    function deployLive() public broadcastLive returns (Singleton, SalvaRegistry, address, address) {
        Singleton singleton = new Singleton();
        SalvaRegistry registry = new SalvaRegistry(address(singleton), msg.sender);

        console.log(address(singleton));
        console.log(address(registry));
        return (singleton, registry, msg.sender, msg.sender);
    }
}
