// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// import {Test, console} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {Singleton} from "@Singleton/Singleton.sol";
// import {SalvaRegistry} from "../../src/SalvaRegistry/Registry.sol";
// import {DeploySingleton} from "../../script/DeploySingleton.s.sol";
// import {Handler} from "./SingletonHandler.t.sol";

// contract TestSingleton is StdInvariant, Test {
//     Singleton private singleton;
//     SalvaRegistry[] private registry;
//     Handler private handler;
//     address private owner;
//     address private registrar;
//     address private EOA = makeAddr("EOA");
//     uint128 private acctNumber = 1246371524;

//     function setUp() external {
//         DeploySingleton deploy = new DeploySingleton();
//         (singleton,, owner, registrar) = deploy.run();

//         for (uint256 i = 0; i < 50;) {
//             vm.prank(owner);
//             registry.push(new SalvaRegistry(address(singleton), registrar));

//             unchecked {
//                 i++;
//             }
//         }
//         handler = new Handler(singleton, registry, registrar, owner);
//         targetContract(address(handler));

//         bytes4[] memory selector = new bytes4[](1);
//         selector[0] = handler.randomSelector.selector;
//         targetSelector(FuzzSelector({addr: address(handler), selectors: selector}));
//     }

//     function invariant_Registry_Can_Only_Initialize_Once() external view {
//         assertEq(handler._getReinitializationSuccessCount(), 0);
//     }

//     function invariant_Maintain_Strict_OneToOne_Mapping() external view {
//         assertEq(handler._getSuccessfulLinkNumberCalls(), 0);
//     }
// }
