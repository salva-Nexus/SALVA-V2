// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BaseSingleton} from "@BaseSingleton/BaseSingleton.sol";

abstract contract LinkName is BaseSingleton {
    // Links a human-readable name alias to a wallet address under the caller's namespace.
    // Only a registered registry may call this. The same name can exist across different
    // registries without collision because the storage key is a weld of the name bytes
    // and the registry's namespace — the name alone is never the key.
    /**
     *  @param _name    The name alias to link e.g. "charles". Validated by phishingProof —
     *                 only lowercase letters, digits 2–9, '.', '-', '_' allowed. Max 16 bytes.
     *  @param _wallet  The wallet address to link the name alias to.
     *  @return _isLinked  Always true on success.
     */
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 1 — CALLER VERIFICATION
    // ─────────────────────────────────────────────────────────────────────────
    // namespace(sender()) loads the caller's bytes16 namespace from _registryNamespace.
    // If zero, they never called initializeRegistry → revert.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 2 — NAME WELDING (assembly)
    // ─────────────────────────────────────────────────────────────────────────
    // The weldedName packs the name and namespace into a single bytes32 key —
    // producing a namespaced identity like "charles@salva".
    //
    //   NAMESPACE NORMALIZATION
    //   ────────────────────────
    //   _registryNamespace stores bytes16. Solidity left-aligns bytes16 within
    //   the RIGHT half of a bytes32 slot:
    //
    //   nspace (loaded):
    //   0x000000000000000000000000000000004073616c766100000000000000000000
    //    ├─────── 16 zero bytes ─────────┤├────── @salva + padding ──────┤
    //
    //   If nameLen < 16 — shift nspace to the right(after length of name):
    //   shr(mul(nameLen, 0x08), nspace) then OR with name.
    //
    //   If nameLen == 16 — shift to the right half,
    //   nspace already sits in the right half at its loaded position.
    //
    //   switch eq(nameLen, 0x10)
    //   case 0x00 → _fullName = or(shr(mul(nameLen, 0x08), nspace), name)
    //   default   → _fullName = or(shr(0x80, nspace), name)
    //
    //   EXAMPLE — name = "charles" (7 bytes), namespace = "@salva" (6 bytes):
    //
    //   nspace:
    //   0x4073616c76610000000000000000000000000000000000000000000000000000
    //
    //   shr(56 bits):
    //   0x00000000000000 4073616c766100000000000000000000000000000000000000
    //    ├ 7 zero bytes┤"@salva"
    //
    //   OR name:
    //   0x636861726c6573 4073616c766100000000000000000000000000000000000000
    //    "charles"        "@salva"
    //
    //   _fullName = "charles@salva" packed in bytes32 ✓
    //
    //   MAX WELD SIZE: name (bytes16) + namespace (bytes16) = full bytes32.
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 3 — COLLISION + WALLET CHECK
    // ─────────────────────────────────────────────────────────────────────────
    // Two checks before writing:
    // 1. _nameToWallet[_fullName] != address(0) → name already taken → revert
    // 2. _walletAliases[_wallet].name != bytes32(0) → wallet already has a name → revert
    //
    // ─────────────────────────────────────────────────────────────────────────
    // STEP 4 — STORAGE WRITES
    // ─────────────────────────────────────────────────────────────────────────
    // 1. _nameToWallet[_fullName] = _wallet   — forward resolution
    // 2. _walletAliases[_wallet].name = _fullName — reverse mapping (bidirectional protection)
    function linkNameAlias(string memory _name, address _wallet)
        external
        phishingProof(_name)
        returns (bool _isLinked)
    {
        (bytes16 nspace,) = namespace(sender());
        if (nspace == bytes16(0)) {
            revert Errors__Not_Registered();
        }

        bytes32 _fullName;
        assembly {
            let nameLen := mload(_name)
            let name := mload(add(_name, 0x20))

            // if nameLen == 16, nspace already sits in right half — no shift needed
            switch eq(nameLen, 0x10)
            case 0x00 {
                _fullName := or(shr(mul(nameLen, 0x08), nspace), name)
            }
            default {
                _fullName := or(shr(0x80, nspace), name)
            }
        }

        address checkWallet = _nameToWallet[_fullName];
        bytes32 checkName = _walletAliases[_wallet].name;
        if (checkWallet != address(0) || checkName != bytes32(0)) {
            revert Errors__Taken();
        }

        _nameToWallet[_fullName] = _wallet;
        _walletAliases[_wallet].name = _fullName;

        _isLinked = true;
    }
}
