// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract Storage {
    address internal immutable _MULTISIG;

    mapping(bytes16 => bool) internal _isInitialized;

    mapping(address => bytes16) internal _registryNamespace;

    mapping(bytes16 => address) internal _nameToWallet;

    mapping(uint64 => address) internal _numberToWallet;

    struct WalletAlias {
        bytes32 name;
        uint64 num;
    }
    mapping(address => WalletAlias) internal _walletAliases;
}
