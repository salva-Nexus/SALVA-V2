// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Singleton} from "@Singleton/Singleton.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Context} from "@Context/Context.sol";

contract SalvaRegistry is AccessControl, Context {
    bytes32 private constant REGISTRAR_ROLE = keccak256("REGISTRAR");
    string private constant IDENTIFIER = "@salva";
    Singleton private immutable SINGLETON;

    event NumberLinked(uint64 _num, address _wallet);
    event NameLinked(string _name, address _wallet);

    constructor(address _singleton, address _registrar) {
        SINGLETON = Singleton(_singleton);
        _grantRole(DEFAULT_ADMIN_ROLE, sender());
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

    function resolveViaNumber(uint64 _num, string memory _namespace) external view returns (address) {
        // forge-lint: disable-next-line(unsafe-typecast)
        bytes16 _nspace = bytes16(bytes(_namespace));
        return SINGLETON.resolveAddressViaNumber(_num, _nspace);
    }

    function resolveViaName(string memory _name) external view returns (address) {
        // forge-lint: disable-next-line(unsafe-typecast)
        bytes32 name = bytes32(bytes(_name));
        return SINGLETON.resolveAddressViaName(name);
    }

    function namespace(address _registry) external view returns (bytes32, bool) {
        return SINGLETON.namespace(_registry);
    }
}
