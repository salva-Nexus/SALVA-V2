// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// import {Singleton} from "@Singleton/Singleton.sol";
// import {Test, console} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {SalvaRegistry} from "../../src/SalvaRegistry/Registry.sol";

// contract Handler is StdInvariant, Test {
//     Singleton private singleton;
//     address private registrar;
//     address private owner;
//     SalvaRegistry[] private registry;
//     uint256 private DoubleInitializationSuccess;
//     uint256 private SuccessfulLinkNumberCalls;
//     uint128[] private linkedNumbers;
//     address[] private linkedAddresses;

//     constructor(Singleton _singleton, SalvaRegistry[] memory _registry, address _registrar, address _owner) {
//         singleton = _singleton;
//         registrar = _registrar;
//         owner = _owner;
//         for (uint128 i = 0; i < _registry.length;) {
//             registry.push(_registry[i]);

//             uint128 _num = 1862547292 + i;
//             string memory makeaddr = string(abi.encodePacked(_num));
//             address _addr = makeAddr(makeaddr);

//             vm.prank(registrar);
//             _registry[i].linkNumber(_num, _addr);
//             linkedNumbers.push(_num);
//             linkedAddresses.push(_addr);

//             unchecked {
//                 i++;
//             }
//         }
//     }

//     function randomSelector(uint256 _randomness) public {
//         uint256 selector = _randomness % 100;
//         if (selector < 51) {
//             initialize(_randomness);
//         } else {
//             linkNumber(_randomness);
//         }
//     }

//     function initialize(uint256 _random) public {
//         SalvaRegistry _registry = _pickRegistry(_random);

//         vm.prank(address(_registry));
//         try singleton.initializeRegistry() {
//             // Record if double initialization successfull
//             DoubleInitializationSuccess++;
//         } catch {}
//     }

//     function linkNumber(uint256 _random) public {
//         SalvaRegistry _registry = _pickRegistry(_random);

//         uint128 _num = linkedNumbers[_random % linkedNumbers.length];
//         address _addr = linkedAddresses[_random % linkedAddresses.length];

//         bytes4 selector = Singleton.linkNumber.selector;
//         bytes memory data = abi.encodeWithSelector(selector, _num, _addr);

//         vm.prank(address(_registry));
//         (bool success,) = address(singleton).call(data);

//         if (success) {
//             assembly {
//                 sstore(SuccessfulLinkNumberCalls.slot, add(sload(SuccessfulLinkNumberCalls.slot), 0x01))
//             }
//         }
//     }

//     function _getReinitializationSuccessCount() external view returns (uint256) {
//         return DoubleInitializationSuccess;
//     }

//     function _getSuccessfulLinkNumberCalls() external view returns (uint256) {
//         return SuccessfulLinkNumberCalls;
//     }

//     function _pickRegistry(uint256 _random) internal view returns (SalvaRegistry) {
//         return registry[_random % registry.length];
//     }
// }
