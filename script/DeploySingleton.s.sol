// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {MultiSig} from "@MultiSig/MultiSig.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@MockV3Aggregator/MockV3Aggregator.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {RegistryFactory} from "@RegistryFactory/RegistryFactory.sol";

contract DeploySingleton is Script {
    uint256 deployerKey;
    address deployer;

    constructor() {
        (deployer, deployerKey) = makeAddrAndKey("OWNER");
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

    function run() external returns (Singleton, MultiSig, BaseRegistry, address, uint256, MockV3Aggregator) {
        if (block.chainid != 31337) {
            (
                Singleton _singleton,
                MultiSig multisig,
                BaseRegistry _registry,
                address _deployer,
                uint256 key,
                MockV3Aggregator mockEth
            ) = deployLive();
            return (_singleton, multisig, _registry, _deployer, key, mockEth);
        } else {
            (
                Singleton _singleton,
                MultiSig multisig,
                BaseRegistry _registry,
                address _deployer,
                uint256 key,
                MockV3Aggregator mockEth
            ) = deploySingletonForTest();
            return (_singleton, multisig, _registry, _deployer, key, mockEth);
        }
    }

    function deploySingletonForTest()
        public
        broadcast
        returns (Singleton, MultiSig, BaseRegistry, address, uint256, MockV3Aggregator)
    {
        //============ MULTISIG============
        MockV3Aggregator mockEth = new MockV3Aggregator(8, 2000e8);
        MultiSig multisig = new MultiSig();
        bytes memory mInit = abi.encodeWithSelector(multisig.initialize.selector);
        MultiSig wrappedMultiSig = MultiSig(address(new ERC1967Proxy(address(multisig), mInit)));

        //============SINGLETON============
        Singleton singleton = new Singleton();
        bytes memory sInit = abi.encodeWithSelector(singleton.initialize.selector, address(wrappedMultiSig));
        Singleton wrappedSingleton = Singleton(payable(address(new ERC1967Proxy(address(singleton), sInit))));

        //============REGISTRY============
        RegistryFactory factory =
            new RegistryFactory(address(new BaseRegistry()), address(wrappedMultiSig), address(mockEth), deployer);
        wrappedMultiSig.setSingletonAndFactory(address(wrappedSingleton), address(factory));
        BaseRegistry salvaregistry = BaseRegistry(wrappedMultiSig.deployAndProposeInit("@salva"));

        return (wrappedSingleton, wrappedMultiSig, salvaregistry, deployer, deployerKey, mockEth);
    }

    function deployLive()
        public
        broadcastLive
        returns (Singleton, MultiSig, BaseRegistry, address, uint256, MockV3Aggregator)
    {
        address dataFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        address backend = 0xfD5A9828bac27495FAb7F6174b3de386E0554187;

        //============ MULTISIG============
        MultiSig multisig = new MultiSig();
        bytes memory mInit = abi.encodeWithSelector(multisig.initialize.selector);
        MultiSig wrappedMultiSig = MultiSig(address(new ERC1967Proxy(address(multisig), mInit)));

        //============SINGLETON============
        Singleton singleton = new Singleton();
        bytes memory sInit = abi.encodeWithSelector(singleton.initialize.selector, address(wrappedMultiSig));
        Singleton wrappedSingleton = Singleton(payable(address(new ERC1967Proxy(address(singleton), sInit))));

        //============REGISTRY============
        RegistryFactory factory =
            new RegistryFactory(address(new BaseRegistry()), address(wrappedMultiSig), dataFeed, backend);
        wrappedMultiSig.setSingletonAndFactory(address(wrappedSingleton), address(factory));
        // BaseRegistry registry = BaseRegistry(wrappedMultiSig.deployAndProposeInit("@salva"));

        console.log("SINGETON", address(wrappedSingleton));
        //console.log("REGISTRY", address(registry));
        console.log("MULTISIG", address(wrappedMultiSig));
        return
            (
                wrappedSingleton,
                wrappedMultiSig,
                BaseRegistry(address(0)),
                msg.sender,
                0,
                new MockV3Aggregator(8, 2000e8)
            );
    }
}
