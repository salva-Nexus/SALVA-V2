// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract Salt {
    // keccak256("salva.v2.singleton._numberToWallet")
    bytes32 internal constant _NUMBER_TO_WALLET_SALT =
        0x611104dcba7bf3413a6ff2cf1ca7b1fce858dffa2f2a3ba6d5904ec00a91518a;

    // keccak256("salva.v2.singleton.nameToWallet")
    bytes32 internal constant _NAME_TO_WALLET_SALT = 0x5415ea9680222ca68b72c70a4b6b69e33e700d6299885d0ba1fa188b932267c1;

    // keccak256("salva.v2.singleton.walletAliases")
    bytes32 internal constant _WALLET_ALIASES_SALT = 0x0c57d69214bd4b97e4912ff651178d8aa7d58a9bddae0f2ba850708500a09061;
}
