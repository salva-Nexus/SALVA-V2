// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Singleton} from "@Singleton/Singleton.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract SalvaRegistry is AccessControl {
    bytes32 private constant REGISTRAR_ROLE = keccak256("REGISTRAR");
    string private constant IDENTIFIER = "@salva";
    Singleton private immutable SINGLETON;

    event NumberLinked(uint64 _num, address _wallet);
    event NameLinked(string _name, address _wallet);

    constructor(address _singleton, address _registrar) {
        SINGLETON = Singleton(_singleton);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(REGISTRAR_ROLE, _registrar);
    }

    function linkNumber(uint64 _num, address _wallet) external onlyRole(REGISTRAR_ROLE) {
        emit NumberLinked(_num, _wallet);
        SINGLETON.linkNumberAlias(_num, _wallet);
    }

    function linkName(string memory _name, address _wallet) external onlyRole(REGISTRAR_ROLE) {
        emit NameLinked(_name, _wallet);
        SINGLETON.linkNameAlias(_name, _wallet);
    }

    function resolveViaNumber(uint64 _num, address _registry) external view returns (address) {
        return SINGLETON.resolveAddressViaNumber(_num, _registry);
    }

    function resolveViaName(string memory _name) external view returns (address) {
        return SINGLETON.resolveAddressViaName(_name);
    }

    function namespace(address _registry) external view returns (bytes32, bool) {
        return SINGLETON.namespace(_registry);
    }
}
