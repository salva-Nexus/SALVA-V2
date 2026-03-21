// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract UnlinkName is BaseSingleton {
    function unlinkName(string memory _name, address _wallet) external {
        assembly {
            mstore(0xc0, caller())
            mstore(0xe0, _registryNamespace.slot)
            let nspace := sload(keccak256(0xc0, 0x40))
            if iszero(nspace) {
                revert(0x00, 0x00)
            }

            let nameToWalletPtr := add(or(mload(add(_name, 0x20)), _nameToWallet.slot), _NAME_TO_WALLET_SALT)
            let walletToNamePtr := add(_wallet, add(_WALLET_ALIASES_SALT, 0x00))

            // No existence check — registry is expected to pass correct, existing data.
            // Passing non-existent aliases silently zeroes already zeroed storage. Caller wastes only their own gas.
            sstore(nameToWalletPtr, 0x00)
            sstore(walletToNamePtr, 0x00)
        }
    }
}
