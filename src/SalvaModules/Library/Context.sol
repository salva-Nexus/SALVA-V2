// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Context
 * @notice Minimal abstraction over `msg.sender` to support meta-transaction patterns
 *         and consistent sender access across the entire Salva protocol.
 * @dev All contracts that need to identify the caller should inherit this contract
 *      and call `_msgSender()` rather than reading `msg.sender` directly.
 */
abstract contract Context {
    /**
     * @notice Returns the address of the immediate transaction sender.
     * @return msgSender The `msg.sender` of the current call.
     */
    function _msgSender() internal view returns (address msgSender) {
        msgSender = msg.sender;
    }
}
