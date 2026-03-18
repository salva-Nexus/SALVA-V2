// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initialize} from "@Initialize/Initialize.sol";
import {LinkNumber} from "@LinkNumber/LinkNumber.sol";
import {LinkName} from "@LinkName/LinkName.sol";
import {UnlinkNumber} from "@UnlinkNumber/UnlinkNumber.sol";
import {UnlinkName} from "@UnlinkName/UnlinkName.sol";

/**
 * @title Salva Singleton
 * @author cboi@Salva
 * @notice Core registry enabling namespace-isolated account aliases to address resolution.
 */
contract Singleton is Initialize, LinkNumber, LinkName, UnlinkNumber, UnlinkName {
    /**
     * @dev Protocol version stored as a bytecode constant.
     *      Declared `constant` so the value is embedded directly in bytecode,
     *      eliminating SLOAD cost.
     */
    uint8 private constant _VERSION = 2;

    constructor(address _multiSig) {
        _MULTISIG = _multiSig;
    }

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
        bytes32 nSpace = namespace(_registry);
        assembly {
            mstore(0x00, nSpace)
            mstore(0x20, _num)
            mstore(0x40, _numberToWallet.slot)
            _wallet := sload(keccak256(0x00, 0x60))
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
            _wallet := sload(add(or(mload(add(_name, 0x20)), _nameToWallet.slot), _NAME_TO_WALLET_SALT))
        }
    }

    /**
     * @notice Returns the namespace assigned to a given registry contract.
     * @dev    Returns bytes32(0) if the address has never called `initializeRegistry`.
     *         The namespace packs the registry's identifier (left 12 bytes) and its
     *         address (right 20 bytes) into a single bytes32 slot.
     *         Used internally by resolveAddressViaNumber and available externally
     *         for integrations that need to verify a registry's namespace status.
     * @param _registry The registry address to query.
     * @return _nSpace  Packed namespace (identifier OR address), or bytes32(0) if unregistered.
     */
    function namespace(address _registry) public view returns (bytes32 _nSpace) {
        assembly {
            _nSpace := sload(add(or(shl(0x08, _registry), _registryNamespace.slot), _NSPACE_SALT))
        }
    }

    /**
     * @notice Returns the protocol version.
     * @return The uint8 version constant baked into bytecode.
     */
    function version() public pure returns (uint8) {
        return _VERSION;
    }
}
