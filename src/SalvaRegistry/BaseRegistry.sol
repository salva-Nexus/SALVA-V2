// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Context} from "@Context/Context.sol";
import {ISalvaSingleton} from "@ISalvaSingleton/ISalvaSingleton.sol";

/**
 * @title BaseRegistry
 * @notice Abstract base contract for creating Salva naming registries.
 * @dev Provides internal helpers to route alias management to the core Singleton.
 */
abstract contract BaseRegistry {
    /// @notice Address of the core Salva naming system.
    address internal immutable SINGLETON;

    /// @notice The fixed identifier/domain associated with this specific registry.
    string internal constant NAMESPACE = "@salva";

    /**
     * @notice Initializes the registry with the Singleton address.
     * @param _singleton The deployed ISalvaSingleton contract address.
     */
    constructor(address _singleton) {
        SINGLETON = _singleton;
    }

    /**
     * @notice Internal helper to link a wallet to either a name or a number alias.
     * @dev Prioritizes Name linking if _number is 0 and _name is provided.
     * @param _name The string name to link (ignored if _number > 0).
     * @param _number The numeric identifier to link (takes priority if non-zero).
     * @param _wallet The destination wallet address for the alias.
     * @return _isSuccess True if the Singleton successfully updated the mapping.
     */
    function _linkAlias(string memory _name, uint128 _number, address _wallet) internal returns (bool _isSuccess) {
        if (_number == 0 && bytes(_name).length != 0x00) {
            _isSuccess = ISalvaSingleton(SINGLETON).linkNameAlias(_name, _wallet);
        } else {
            _isSuccess = ISalvaSingleton(SINGLETON).linkNumberAlias(_number, _wallet);
        }
    }

    /**
     * @notice Internal helper to remove an existing alias mapping.
     * @param _name The name alias to remove.
     * @param _number The numeric alias to remove.
     * @return _isSuccess True if the mapping was cleared.
     */
    function _unlinkAlias(string memory _name, uint128 _number) internal returns (bool _isSuccess) {
        if (_number == 0 && bytes(_name).length != 0x00) {
            _isSuccess = ISalvaSingleton(SINGLETON).unlinkName(_name);
        } else {
            _isSuccess = ISalvaSingleton(SINGLETON).unlinkNumber(_number);
        }
    }

    /**
     * @notice Internal view helper to resolve an alias to a wallet address.
     * @param _name The string name to resolve.
     * @param _number The numeric identifier to resolve.
     * @return _addr The wallet address linked to the alias, or address(0).
     */
    function _resolveAlias(string memory _name, uint128 _number) internal view returns (address _addr) {
        if (_number == 0) {
            bytes32 name = bytes32(bytes(_name));
            _addr = ISalvaSingleton(SINGLETON).resolveAddressViaName(name);
        } else {
            bytes16 _nspace = bytes16(bytes(namespace()));
            _addr = ISalvaSingleton(SINGLETON).resolveAddressViaNumber(_number, _nspace);
        }
    }

    /**
     * @notice Returns the namespace identifier for this registry.
     * @return The constant string NAMESPACE.
     */
    function namespace() public pure returns (string memory) {
        return NAMESPACE;
    }
}
