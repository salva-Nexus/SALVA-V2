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

    function run() external returns (Singleton, SalvaRegistry, address, address) {
        return deploySingleton();
    }

    function deploySingleton() public broadcast returns (Singleton, SalvaRegistry, address, address) {
        Singleton singleton = new Singleton();
        SalvaRegistry resgistry = new SalvaRegistry(address(singleton), registrar);
        return (singleton, resgistry, deployer, registrar);
    }
}
