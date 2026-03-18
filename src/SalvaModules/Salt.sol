// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract Salt {
    // keccak256("salva.v2.singleton.nspace")
    bytes32 internal constant _NSPACE_SALT = 0x0e69ca985d281c235813eed420b4fabc37bf87db9c2fbe28384506a2c9e52e46;

    // keccak256("salva.v2.singleton.identifier")
    bytes32 internal constant _IDENTIFIER_SALT = 0x80103e7017b0f74d4759e05bddf541ff54ad4b18ac89d3a488c014864c95e157;

    // keccak256("salva.v2.singleton.nameToWallet")
    bytes32 internal constant _NAME_TO_WALLET_SALT = 0x5415ea9680222ca68b72c70a4b6b69e33e700d6299885d0ba1fa188b932267c1;

    // keccak256("salva.v2.singleton.walletAliases")
    bytes32 internal constant _WALLET_ALIASES_SALT = 0x0c57d69214bd4b97e4912ff651178d8aa7d58a9bddae0f2ba850708500a09061;
}
