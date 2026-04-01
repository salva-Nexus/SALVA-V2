// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Context} from "@Context/Context.sol";
import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract BaseRegistry is AccessControl, Context {
    address internal immutable SINGLETON;
    string internal constant NAMESPACE = "@salva";
    bytes32 private constant REGISTRAR_ROLE = keccak256("REGISTRAR");

    constructor(address _singleton, address _registrar) {
        SINGLETON = _singleton;
        _grantRole(DEFAULT_ADMIN_ROLE, sender());
        grantRole(REGISTRAR_ROLE, _registrar);
    }

    function linkToWallet(bytes calldata _name, address _wallet)
        external
        onlyRole(REGISTRAR_ROLE)
        returns (bool _isSuccess)
    {
        _isSuccess = ISalvaSingleton(SINGLETON).linkNameAlias(_name, _wallet, 0);
    }

    function linkToNumber(bytes calldata _name, uint256 _number)
        external
        onlyRole(REGISTRAR_ROLE)
        returns (bool _isSuccess)
    {
        _isSuccess = ISalvaSingleton(SINGLETON).linkNameAlias(_name, address(0), _number);
    }

    function unlink(bytes calldata _name) external onlyRole(REGISTRAR_ROLE) returns (bool _isSuccess) {
        _isSuccess = ISalvaSingleton(SINGLETON).unlink(_name);
    }

    function resolveAddress(bytes calldata _name) external view returns (address _addr) {
        _addr = ISalvaSingleton(SINGLETON).resolveAddress(_name);
    }

    function resolveNumber(bytes calldata _name) external view returns (uint256 _num) {
        _num = ISalvaSingleton(SINGLETON).resolveNumber(_name);
    }

    function namespace() external pure returns (string memory) {
        return NAMESPACE;
    }
}
