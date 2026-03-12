// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract SalvaRegistry is BaseRegistry, AccessControl {
    bytes32 private constant REGISTRAR_ROLE = keccak256("REGISTRAR");

    event SalvaNamespace(bytes32 _namespace);
    event NumberLinked(uint128 _num, address _wallet);

    constructor(address _singleton, address _registrar) BaseRegistry(_singleton) {
        bytes32 nSpace = SINGLETON.initializeRegistry();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(REGISTRAR_ROLE, _registrar);

        emit SalvaNamespace(nSpace);
    }

    // we are not keeping record here to save gas cost, we let the Singleton be the source of truth, we'll read from it
    function linkNumber(uint128 _num, address _wallet) external onlyRole(REGISTRAR_ROLE) {
        emit NumberLinked(_num, _wallet);
        _linkNumber(_num, _wallet);
    }

    function resolveAddress(uint128 _num, address _registry) external view override returns (address) {
        return SINGLETON.resolveAddress(_num, _registry);
    }

    function resolveNumber(address _wallet, address _registry) external view override returns (uint128) {}

    function namespace(address _registry) external view override returns (bytes32) {
        return SINGLETON.namespace(_registry);
    }
}
