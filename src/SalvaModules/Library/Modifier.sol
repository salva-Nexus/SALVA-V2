// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Errors} from "@Errors/Errors.sol";
import {Context} from "@Context/Context.sol";

/**
 * @title Modifier
 * @notice Shared modifier library for the Salva singleton.
 * @dev Provides reentrancy protection via EIP-1153 transient storage and
 *      MultiSig-only access control.
 */
abstract contract Modifier is Errors, Context {
    /**
     * @notice Guards against reentrant calls using transient storage slot 0x00.
     * @dev Uses `tload` / `tstore` (EIP-1153) for gas-efficient reentrancy
     *      locking that is automatically cleared at the end of the transaction.
     *      Reverts with empty data on reentrant entry.
     */
    modifier nonReentrant() {
        assembly {
            if gt(tload(0x00), 0x00) {
                revert(0x00, 0x00)
            }
            tstore(0x00, 0x01)
        }
        _;
        assembly {
            tstore(0x00, 0x00) // this is just for test, will comment out before deployment
        }
    }

    /**
     * @notice Restricts access to the Salva MultiSig contract.
     * @dev Resolves the caller via `sender()` and compares against the
     *      protocol-defined `multiSig` address.  Used exclusively to gate
     *      registry initialization — no other operation is authorized through
     *      this modifier.
     * @param multiSig The expected MultiSig contract address.
     */
    modifier onlyMultiSig(address multiSig) {
        if (sender() != multiSig) revert Errors__Not_Authorized();
        _;
    }
}
