// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract Initialize is BaseSingleton {
    // phishing proof was designed for when registration was decentralized,
    // now that it's centralized and goes through Salva Admin(s) validation,
    // i'll have to remove it.... it's redundant...
    // the only thing i'll worry about is that none of salva admin gets compromised,
    // imagine wallets like blockchain.com wants to register, with the phishing proof, it'll be @blockchaincom
    // which is not standard,
    // cboi@blockchain.com is better

    function initializeRegistry(address _registry, bytes16 _nspace) external onlyMultiSig(_MULTISIG) returns (bool) {
        // registry identifier eg @salva is also your name space, therefor namespace will now return string
        // namespace length max will now be bytes16 max...
        // i can imagine @walletconnect or @blockchain.com
        // byte12 is fucking small
        // and since this function will be called sparingly, there is no need for the full low level
        // ======================================================================
        // even though registration passes through salva admin/ multisig
        // this function isn't trusting the data
        if (_registry == address(0) || _nspace[0] != 0x40) {
            revert Errors__Invalid_Address_Or_Identifier_Too_Long_Or_Invalid_Prefix();
        }

        (bytes16 nspace, bool isInitialized) = namespace(_registry);
        if (nspace != bytes16(0) || isInitialized) {
            revert Errors__Double_Initialization();
        }

        _registryNamespace[_registry] = _nspace;
        _isInitialized[_nspace] = true;
        return true;
    }
}
