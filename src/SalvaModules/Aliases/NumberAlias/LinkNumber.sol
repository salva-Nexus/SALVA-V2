// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract LinkNumber is BaseSingleton {
    function linkNumberAlias(uint64 _num, address _wallet) external {
        assembly {
            mstore(0xc0, caller())
            mstore(0xe0, _registryNamespace.slot)
            let nspace := sload(keccak256(0xc0, 0x40))
            if iszero(nspace) {
                revert(0x00, 0x00)
            }

            // NUMBER CHECK
            let _nspace := shl(0x80, nspace)
            let numToWalletPtr := add(add(or(_num, _nspace), _numberToWallet.slot), _NUMBER_TO_WALLET_SALT)
            if sload(numToWalletPtr) {
                revert(0x00, 0x00)
            }

            // WALLET CHECK - BIDIRECTIONAL MAPPING
            let walletToNumPtr := add(_wallet, add(_WALLET_ALIASES_SALT, 0x01))
            let walletToNum := sload(walletToNumPtr)
            if gt(walletToNum, 0x00) {
                revert(0x00, 0x00)
            }

            sstore(numToWalletPtr, _wallet)
            sstore(walletToNumPtr, _num)
        }
    }
}
