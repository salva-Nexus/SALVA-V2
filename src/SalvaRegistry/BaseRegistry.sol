// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Context} from "@Context/Context.sol";
import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";

contract BaseRegistry is Context {
    address internal immutable SINGLETON;
    string internal constant NAMESPACE = "@salva";

    constructor(address _singleton) {
        SINGLETON = _singleton;
    }

    function linkToWallet(bytes calldata _name, address _wallet) external returns (bool _isSuccess) {
        _isSuccess = ISalvaSingleton(SINGLETON).linkNameAlias(_name, _wallet, 0, sender());
    }

    function linkToNumber(bytes calldata _name, uint256 _number) external returns (bool _isSuccess) {
        _isSuccess = ISalvaSingleton(SINGLETON).linkNameAlias(_name, address(0), _number, sender());
    }

    function unlink(bytes calldata _name) external returns (bool _isSuccess) {
        _isSuccess = ISalvaSingleton(SINGLETON).unlink(_name, sender());
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
