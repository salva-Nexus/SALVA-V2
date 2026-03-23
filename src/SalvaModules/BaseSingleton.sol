// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Modifier} from "@Modifier/Modifier.sol";
import {Storage} from "@Storage/Storage.sol";

abstract contract BaseSingleton is Modifier, Storage {

    // Resolves a 10-digit number alias to a wallet address using only the namespace.
    // No registry contract address needed — namespaces are simple and memorable
    // (e.g. @salva, @coinbase) so callers can resolve directly via namespace.
    /** 
    *  @param _num        The number alias to resolve (e.g. 1234567890).
    *  @param _namespace  The bytes16 namespace to resolve under (e.g. "@salva").
    *  @return _wallet    The wallet address linked to this number, or address(0) if unlinked.
    */
    // STORAGE POINTER DERIVATION
    // ───────────────────────────
    // namespace and number each fit within bytes16 — together they fit in bytes32.
    // They are OR-welded into one word, offset by the mapping slot, then hashed:
    //
    //   mstore(0xc0, add(or(_namespace, _num), _numberToWallet.slot))
    //   _wallet := sload(keccak256(0xc0, 0x20))
    //
    //   or(_namespace, _num):
    //   namespace occupies LEFT  16 bytes (e.g. "@salva")
    //   _num      occupies RIGHT 16 bytes (e.g. 1234567890)
    //   They never overlap — safe to OR directly.
    //
    //   add(..., _numberToWallet.slot) offsets the word by the mapping slot
    //   before hashing — domain-separates the key from other mappings.
    //
    //   keccak256(0xc0, 0x20) → unique storage pointer per (namespace, number) pair.
    function resolveAddressViaNumber(uint128 _num, bytes16 _namespace) external view returns (address _wallet) {
        assembly {
            mstore(0xc0, add(or(_namespace, _num), _numberToWallet.slot))
            _wallet := sload(keccak256(0xc0, 0x20))
        }
    }

    // Resolves a welded name alias to a wallet address.
    // The caller passes the fully welded name (e.g. "charles@salva" packed as bytes32) —
    // the same form that linkNameAlias stores. No registry address needed.
    /** 
    *  @param _name    The fully welded name alias as bytes32 (e.g. "charles@salva").
    *  @return _wallet The wallet address linked to this name, or address(0) if unlinked.
    */
    function resolveAddressViaName(bytes32 _name) external view returns (address _wallet) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return _nameToWallet[_name];
    }

    // Returns the namespace and initialization status of a given registry contract.
    // Returns (bytes16(0), false) if the address has never been initialized.
    // Used internally by Initialize, LinkName, LinkNumber, UnlinkName, UnlinkNumber.
    /**
    *  @param _registry  The registry address to query.
    *  @return _nspace      The bytes16 namespace assigned to this registry.
    *  @return _initialized True if this registry has been initialized.
    */
    function namespace(address _registry) public view returns (bytes16 _nspace, bool _initialized) {
        bytes16 nspace = _registryNamespace[_registry];
        bool isInitialized = _isInitialized[nspace];
        return (nspace, isInitialized);
    }
}
