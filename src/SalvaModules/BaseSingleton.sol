// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Modifier} from "@Modifier/Modifier.sol";
import {Storage} from "@Storage/Storage.sol";
import {Salt} from "@Salt/Salt.sol";
import {Errors} from "@Errors/Errors.sol";

abstract contract BaseSingleton is Modifier, Storage, Salt, Errors {
    /**
     * @notice Resolves a namespaced number alias to its linked wallet address.
     * @dev    Derives the storage pointer via keccak256(nSpace ++ _num ++ slot) —
     *         keccak is required here because the composite key exceeds 32 bytes
     *         and cannot be packed via OR + salt without collision risk.
     * @param _num      The 10-digit number alias to resolve.
     * @param _registry The registry contract address whose namespace to query under.
     * @return _wallet  The wallet address linked to this number, or address(0) if unlinked.
     */
    function resolveAddressViaNumber(uint64 _num, address _registry) external view returns (address _wallet) {
        (bytes16 nspace,) = namespace(_registry);
        assembly {
            _wallet := sload(add(add(or(_num, nspace), _numberToWallet.slot), _NUMBER_TO_WALLET_SALT))
        }
    }

    /**
     * @notice Resolves a welded name alias to its linked wallet address.
     * @dev    The caller must pass the fully welded name (e.g. "charles@salva"),
     *         not just the raw name. The welded form is what linkNameAlias stores —
     *         the name bytes OR-packed with the registry identifier.
     *         Storage pointer: add(or(weldedName, _nameToWallet.slot), _NAME_TO_WALLET_SALT)
     * @param _name    The fully welded name alias (e.g. "charles@salva").
     * @return _wallet The wallet address linked to this name, or address(0) if unlinked.
     */
    function resolveAddressViaName(string memory _name) external view returns (address _wallet) {
        assembly {
            _wallet := sload(add(add(mload(add(_name, 0x20)), _nameToWallet.slot), _NAME_TO_WALLET_SALT))
        }
    }

    function namespace(address _registry) public view returns (bytes16 _nspace, bool _initialized) {
        bytes16 nspace = _registryNamespace[_registry];
        bool isInitialized = _isInitialized[nspace];
        return (nspace, isInitialized);
    }
}
