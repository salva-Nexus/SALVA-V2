// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {SalvaRegistry} from "../src/SalvaSingleton/SalvaRegistry/Registry.sol";

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
        vm.startBraodcast();
        _;
        vm.stopBroadcast();
    }

    function run() external returns (Singleton, SalvaRegistry, address, address) {
        return deploySingleton();
    }

    function deploySingletonForTest() public broadcast returns (Singleton, SalvaRegistry, address, address) {
        Singleton singleton = new Singleton();
        SalvaRegistry resgistry = new SalvaRegistry(address(singleton), registrar);
        return (singleton, resgistry, deployer, registrar);
    }

    function deployLive() public broadcastLive {
        Singleton singleton = new Singleton();
        SalvaRegistry resgistry = new SalvaRegistry(address(singleton), msg.sender);

        console.log(address(singleton));
        console.log(address(registry));
    }
}
