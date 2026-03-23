// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract UnlinkName is BaseSingleton {
    // Unlinks a name alias from its wallet address under the caller's namespace.
    // Only a registered registry may call this.
    //
    // Only the name is passed — the wallet address is derived from the name via
    // _nameToWallet. This prevents an attacker from passing in another person's
    // wallet address to unlink their alias.
    //
    // No existence check is performed — if the name is not linked, the call
    // silently zeroes already-zero slots. Caller wastes only their own gas.
    /**
     * @param _name      The name alias to unlink e.g. "charles".
     * @return _isUnlinked  Always true on success.
     */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — CALLER VERIFICATION
    // ─────────────────────────────────────────────────────────────────────────
    // namespace(sender()) loads the caller's bytes16 namespace.
    // If zero, they never called initializeRegistry → revert.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — NAME WELDING (assembly)
    // ─────────────────────────────────────────────────────────────────────────
    // Same weld logic as linkNameAlias — reconstructs the same _fullName key
    // that was stored at link time so the correct slot can be zeroed.
    //
    //   switch eq(nameLen, 0x10)
    //   case 0x00 → _fullName = or(shr(mul(nameLen, 0x08), nspace), name)
    //   default   → _fullName = or(shr(0x80, nspace), name)
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — WALLET DERIVATION
    // ─────────────────────────────────────────────────────────────────────────
    // _wallet = _nameToWallet[_fullName]
    // The wallet address is read from the forward mapping — not taken from the caller.
    // This is the security fix: passing a wallet param would allow an attacker to
    // unlink a victim's alias by supplying the victim's address directly.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — STORAGE WRITES
    // ─────────────────────────────────────────────────────────────────────────
    // 1. _nameToWallet[_fullName] = address(0)   — clear forward mapping
    // 2. _walletAliases[_wallet].name = bytes32(0) — clear reverse mapping
    function unlinkName(string memory _name) external returns (bool _isUnlinked) {
        (bytes16 nspace,) = namespace(sender());
        if (nspace == bytes16(0)) {
            revert Errors__Not_Registered();
        }

        bytes32 _fullName;
        assembly {
            let nameLen := mload(_name)
            let name := mload(add(_name, 0x20))

            switch eq(nameLen, 0x10)
            case 0x00 {
                _fullName := or(shr(mul(nameLen, 0x08), nspace), name)
            }
            default {
                _fullName := or(shr(0x80, nspace), name)
            }
        }

        address _wallet = _nameToWallet[_fullName];
        _nameToWallet[_fullName] = address(0);
        _walletAliases[_wallet].name = bytes32(0);

        _isUnlinked = true;
    }
}
