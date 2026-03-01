// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Singleton} from "@Singleton/Singleton.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {SalvaRegistry} from "../../src/SalvaSingleton/SalvaRegistry/Registry.sol";

contract Handler is  StdInvariant, Test {
  Singleton private singleton;
  address private registrar;
  address private owner;
  SalvaRegistry[] private registry;
  uint256 private DoubleInitializationFailure;
  uint256 private DoubleInitializationSuccess;

  constructor(Singleton _singleton, SalvaRegistry[] memory _registry, address _registrar, address _owner) {
    singleton = _singleton;
    registrar = _registrar;
    owner = _owner;
    for(uint256 i = 0; i < _registry.length;) {
      registry.push(_registry[i]);

      unchecked {
        i++;
      }
    }
  }

  function randomSelector(/*uint256 _randomness, */uint256 _random) public {
    // uint256 selector = _randomness % 100;
    // if(selector < 5) {
    //   initialize(_random);
    // }
    initialize(_random);
  }

  function initialize(uint256 _random) public {
    SalvaRegistry _registry = _pickRegistry(_random);
    // uint256 acctNumber = (_random % 99_000_000_000) + 1_000_000_000; // make sure it's between 10 digit and 11 digit range

    // First, Correct Initialization
    for(uint256 i = 0; i < registry.length;) {
      vm.prank(owner);
      registry[i].initialize();
      unchecked {
        i++;
      }
    }

    // then random Reinitialization
    vm.prank(owner);
    try _registry.initialize() {
      // Record if double initialization successfull
      DoubleInitializationSuccess++;
    } catch {}
  }

  function _getReinitializationSuccessCount() external view returns (uint256) {
    return DoubleInitializationSuccess;
  }

  function _pickRegistry(uint256 _random) internal view returns (SalvaRegistry) {
    return registry[_random % registry.length];
  }

}