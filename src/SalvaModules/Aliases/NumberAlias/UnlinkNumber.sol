// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract UnlinkNumber is BaseSingleton {
    function unlinkNumber(uint64 _num, address _wallet) external {
        assembly {
            mstore(0xc0, caller())
            mstore(0xe0, _registryNamespace.slot)
            let nspace := sload(keccak256(0xc0, 0x40))
            if iszero(nspace) {
                revert(0x00, 0x00)
            }

            let _nspace := shl(0x80, nspace)
            let numToWalletPtr := add(add(or(_num, _nspace), _numberToWallet.slot), _NUMBER_TO_WALLET_SALT)
            let walletToNumPtr := add(_wallet, add(_WALLET_ALIASES_SALT, 0x01))

            // No existence check — registry is expected to pass correct, existing data.
            // Passing non-existent aliases silently zeroes storage. Caller wastes only their own gas.
            sstore(numToWalletPtr, 0x00)
            sstore(walletToNumPtr, 0x00)
        }
    }
}
