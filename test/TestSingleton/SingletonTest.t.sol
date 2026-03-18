// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {MultiSig} from "@MultiSig/MultiSig.sol";
import {Singleton} from "@Singleton/Singleton.sol";
import {SalvaRegistry} from "../../src/SalvaRegistry/Registry.sol";
import {DeploySingleton} from "../../script/DeploySingleton.s.sol";

contract TestSingleton is Test {
    Singleton private singleton;
    MultiSig private multisig;
    SalvaRegistry private registry;
    address private owner;
    address private registrar;
    address private EOA = makeAddr("EOA");
    uint64 private acctNumber = 1246371524;
    string private name = "charles";

    function setUp() external {
        DeploySingleton deploy = new DeploySingleton();
        (singleton, multisig, registry, owner, registrar) = deploy.run();

        vm.prank(owner);
        multisig.setSingleton(address(singleton));
    }

    modifier initialized() {
        vm.startPrank(owner);
        multisig.proposeInitialization("@salva", address(registry));
        multisig.validateRegistry(address(registry));
        vm.stopPrank();
        _;
    }

    modifier initializedRegistry2() {
        Registry2 reg2 = new Registry2(address(singleton));
        string memory IDENTIFIER = ".salva";
        vm.startPrank(owner);
        multisig.proposeInitialization(IDENTIFIER, address(reg2));
        multisig.validateRegistry(address(reg2));
        vm.stopPrank();
        _;
    }

    modifier linkNumber() {
        vm.prank(registrar);
        registry.linkNumber(acctNumber, EOA);
        _;
    }

    modifier linkName() {
        vm.prank(registrar);
        registry.linkName(name, EOA);
        _;
    }

    function test_Initialize() external {
        vm.startPrank(owner);
        multisig.proposeInitialization("@salva", address(registry));
        multisig.validateRegistry(address(registry));
        vm.stopPrank();

        assertNotEq(registry.namespace(address(registry)), bytes32(0));
    }

    function test_Only_MultiSig_Can_Initialize() external {
        vm.prank(address(registry));
        vm.expectRevert();
        singleton.initializeRegistry(address(registry), "@salva");
    }

    function test_linkNumber() external initialized {
        vm.prank(registrar);
        uint256 gasStart = gasleft();
        registry.linkNumber(acctNumber, EOA);
        uint256 gasStop = gasleft();

        console.log("Low Leve Link Number Call: ", gasStart - gasStop);
        address _wallet = registry.resolveViaNumber(acctNumber, address(registry));
        console.log(_wallet);
        assertEq(_wallet, EOA);
    }

    function test_Unlink_number() external initialized linkNumber {
        address linked = registry.resolveViaNumber(acctNumber, address(registry));
        assertEq(linked, EOA);
        vm.prank(address(registry));
        singleton.unlinkNumber(acctNumber, EOA);

        assertNotEq(registry.resolveViaNumber(acctNumber, address(registry)), linked);
    }

    function test_linkName() external initialized {
        vm.prank(registrar);
        uint256 gasStart = gasleft();
        registry.linkName(name, EOA);
        uint256 gasStop = gasleft();

        console.log("Low Leve Link Name Call: ", gasStart - gasStop);
        address _wallet = registry.resolveViaName("charles@salva");
        console.log(_wallet);
        assertEq(_wallet, EOA);
    }

    function test_Unlink_Name() external initialized linkName {
        address linked = registry.resolveViaName("charles@salva");
        assertEq(linked, EOA);
        vm.prank(address(registry));
        singleton.unlinkName("charles@salva", EOA);

        assertNotEq(registry.resolveViaName("charles@salva"), linked);
    }

    function test_Phishing_Resistance() external {
        // the main Salva registry is deployed with the identifier "@salva" (all lowercase)
        // so this should not revert
        string memory IDENTIFIER = "@SALVA";
        Registry2 reg2 = new Registry2(address(singleton));

        vm.startPrank(owner);
        multisig.proposeInitialization(IDENTIFIER, address(reg2));
        vm.expectRevert();
        multisig.validateRegistry(address(reg2));
        vm.stopPrank();
    }

    function test_Enforce_Prefix() external {
        string memory IDENTIFIER = ".salva";
        Registry2 reg2 = new Registry2(address(singleton));

        vm.startPrank(owner);
        multisig.proposeInitialization(IDENTIFIER, address(reg2));
        vm.expectRevert();
        multisig.validateRegistry(address(reg2));
        vm.stopPrank();
    }

    function test_Only_Registry_Can_Link() external initialized {
        vm.prank(EOA);
        vm.expectRevert();
        singleton.linkNumberAlias(acctNumber, EOA);

        vm.prank(EOA);
        vm.expectRevert();
        singleton.linkNameAlias(name, EOA);
    }

    function test_Linked_Number_Cannot_Be_Reused() external initialized {
        vm.prank(registrar);
        registry.linkNumber(acctNumber, EOA);

        vm.prank(registrar);
        vm.expectRevert();
        registry.linkNumber(acctNumber, address(0x123));
    }

    function test_Linked_Wallet_Cannot_Be_Reused() external initialized {
        vm.startPrank(registrar);
        registry.linkNumber(acctNumber, EOA);
        registry.linkName(name, EOA);

        vm.expectRevert();
        registry.linkNumber(9876543210, EOA);

        vm.expectRevert();
        registry.linkName("alice", EOA);
        vm.stopPrank();
    }
}

import {Singleton} from "@Singleton/Singleton.sol";

contract Registry2 {
    Singleton private immutable SINGLETON;

    event NumberLinked(uint64 _num, address _wallet);
    event NameLinked(string _name, address _wallet);

    constructor(address _singleton) {
        SINGLETON = Singleton(_singleton);
    }

    function linkNumber(uint64 _num, address _wallet) external {
        emit NumberLinked(_num, _wallet);
        SINGLETON.linkNumberAlias(_num, _wallet);
    }

    function linkName(string memory _name, address _wallet) external {
        emit NameLinked(_name, _wallet);
        SINGLETON.linkNameAlias(_name, _wallet);
    }

    function resolveViaNumber(uint64 _num, address _registry) external view returns (address) {
        return SINGLETON.resolveAddressViaNumber(_num, _registry);
    }

    function resolveViaName(string memory _name) external view returns (address) {
        return SINGLETON.resolveAddressViaName(_name);
    }

    function namespace(address _registry) external view returns (bytes32) {
        return SINGLETON.namespace(_registry);
    }
}

