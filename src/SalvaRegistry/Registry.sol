// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Context} from "@Context/Context.sol";
import {BaseRegistry} from "@BaseRegistry/BaseRegistry.sol";

contract SalvaRegistry is BaseRegistry, AccessControl, Context {
    bytes32 private constant REGISTRAR_ROLE = keccak256("REGISTRAR");

    event NumberLinked(uint128 _num, address _wallet);
    event NameLinked(string _name, address _wallet);

    event NumberUnlinked(uint128 _num);
    event NameUnlinked(string _name);

    constructor(address _singleton, address _registrar) BaseRegistry(_singleton) {
        _grantRole(DEFAULT_ADMIN_ROLE, sender());
        grantRole(REGISTRAR_ROLE, _registrar);
    }

    function linkNumber(uint128 _num, address _wallet) external onlyRole(REGISTRAR_ROLE) returns (bool) {
        emit NumberLinked(_num, _wallet);
        return _linkAlias("", _num, _wallet);
    }

    function linkName(string memory _name, address _wallet) external onlyRole(REGISTRAR_ROLE) returns (bool) {
        emit NameLinked(_name, _wallet);
        return _linkAlias(_name, 0, _wallet);
    }

    function unlinkNumber(uint128 _number) external onlyRole(REGISTRAR_ROLE) returns (bool) {
        emit NumberUnlinked(_number);
        return _unlinkAlias("", _number);
    }

    function unlinkName(string memory _name) external onlyRole(REGISTRAR_ROLE) returns (bool) {
        emit NameUnlinked(_name);
        return _unlinkAlias(_name, 0);
    }

    function resolveViaNumber(uint128 _num) external view returns (address) {
        return _resolveAlias("", _num);
    }

    function resolveViaName(string calldata _name) external view returns (address) {
        return _resolveAlias(_name, 0);
    }
}
