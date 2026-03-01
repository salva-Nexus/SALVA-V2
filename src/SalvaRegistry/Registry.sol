// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract SalvaRegistry is BaseRegistry, AccessControl {
    bytes32 private constant REGISTRAR_ROLE = keccak256("REGISTRAR");

    event SalvaNamespace(uint32 _namespace);
    event NumberLinked(uint128 _num, address _addr);

    constructor(address _singleton, address _registrar) BaseRegistry(_singleton) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(REGISTRAR_ROLE, _registrar);
    }

    function initialize() external {
        emit SalvaNamespace(_initialize());
    }

    // we are not keeping record here to save gas cost, we let the Singleton be the source of truth, we'll read from it
    function linkNumber(uint128 _num, address _addr) external onlyRole(REGISTRAR_ROLE) {
        emit NumberLinked(_num, _addr);
        _linkNumber(_num, _addr);
    }

    function resolveAddress(uint128 _num, address _registry) external view override returns (address) {
        return SINGLETON.resolveAddress(_num, _registry);
    }

    function resolveNumber(address _addr, address _registry) external view override returns (uint128) {}

    function namespace(address _registry) external view override returns (uint32) {
        return SINGLETON.namespace(_registry);
    }
}
