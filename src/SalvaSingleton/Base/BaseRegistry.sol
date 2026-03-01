// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Singleton} from "@Singleton/Singleton.sol";

/**
 * @title BaseRegistry
 * @author Salva Protocol
 * @notice Abstract base contract for building namespace-isolated registries on top of the Salva Singleton.
 *
 * @dev DESIGN INTENT:
 * A high-level Solidity contract calling the Singleton would pay for Solidity's ABI encoder
 * (memory expansion, free pointer updates, return-data copying). BaseRegistry eliminates this
 * overhead by making all Singleton calls through hand-rolled assembly that writes calldata
 * directly into the low memory slots (0x00–0x43) and reads return values in place.
 *
 * NAMESPACE CACHING:
 * The Singleton is the authoritative source for a registry's namespace ID. BaseRegistry does
 * not enforce local caching — child contracts may store the ID returned by `_initialize()` in
 * a state variable (one SSTORE, cheap SLOADs after) or omit it and read from the Singleton
 * on demand. The right choice depends on how frequently the child needs its own namespace ID.
 *
 * INHERITANCE MODEL:
 * Consumers inherit this contract and call `_initialize()` once post-deployment to register
 * with the Singleton, then call `_linkNumber()` to record number-to-address mappings. The three
 * virtual view functions (`resolveAddress`, `resolveNumber`, `namespace`) must be implemented
 * by the child — typically by forwarding directly to `singleton`.
 */
abstract contract BaseRegistry {
    /**
     * @dev Immutable reference to the Singleton.
     * Declared `immutable` so the address is embedded in the contract's bytecode at deployment,
     * eliminating an SLOAD on every access. Marked `internal` so child contracts can reference
     * it directly (e.g. to forward view calls).
     */
    Singleton internal immutable SINGLETON;

    /**
     * @param _singleton Address of the deployed Singleton contract.
     */
    constructor(address _singleton) {
        SINGLETON = Singleton(_singleton);
    }

    /**
     * @notice Registers this contract with the Singleton and returns its assigned Namespace ID.
     * @dev Must be called once after deployment. Cannot be called from within a constructor
     * because the Singleton's `onlyRegistry` modifier rejects callers where `extcodesize == 0`.
     *
     * Assembly walk-through:
     *
     * 1. Selector placement:
     *    `shl(0xe0, 0xb2a4b788)` shifts the `initializeRegistry()` selector 224 bits left,
     *    placing it in the top 4 bytes of the 32-byte word written to 0x00. Bytes 0x04–0x1f
     *    are zero — no further calldata is needed since `initializeRegistry` takes no arguments.
     *
     * 2. Call:
     *    `call(gas(), _singleton, 0x00, 0x00, 0x04, 0x00, 0x20)` — forwards all remaining gas,
     *    sends 4 bytes of calldata from 0x00, and writes 32 bytes of return data back to 0x00.
     *    The Singleton performs a manual `return(0x00, 0x20)` with the assigned namespace ID,
     *    so the return value lands directly at 0x00 without any ABI decoding overhead.
     *
     * 3. Return value:
     *    `mload(0x00)` reads the namespace ID that the Singleton wrote into the return slot.
     *    The free memory pointer at 0x40 is never updated — this is intentional and safe
     *    because no Solidity memory allocation follows this assembly block.
     *
     * @return _nSpace The uint32 Namespace ID assigned to this registry by the Singleton.
     */
    function _initialize() internal returns (uint32 _nSpace) {
        address _singleton = address(SINGLETON);
        assembly {
            mstore(0x00, shl(0xe0, 0xb2a4b788))
            let success := call(gas(), _singleton, 0x00, 0x00, 0x04, 0x00, 0x20)
            if iszero(success) {
                revert(0x00, 0x00)
            }
            // return namespace
            _nSpace := mload(0x00)
        }
    }

    /**
     * @notice Links an account number to a wallet address under this registry's namespace.
     * @dev Forwards to `Singleton.linkNumber()` via a raw assembly call, bypassing Solidity's
     * ABI encoder to avoid memory expansion and free pointer overhead.
     *
     * Assembly walk-through:
     *
     * 1. Selector placement:
     *    `shl(0xe0, 0x52d067c4)` places the `linkNumber()` selector in the top 4 bytes at 0x00.
     *
     * 2. Argument packing:
     *    `mstore(0x04, _num)`  — writes _num  (uint128) right-aligned into bytes 0x04–0x23.
     *    `mstore(0x24, _addr)` — writes _addr (address) right-aligned into bytes 0x24–0x43.
     *    This produces the same memory layout as standard ABI encoding for (uint128, address)
     *    without touching the free memory pointer at 0x40. The commented-out `mload(0x40)` is
     *    a deliberate omission — skipping the free pointer update is the source of the gas saving.
     *
     * 3. Call:
     *    `call(gas(), _singleton, 0x00, 0x00, 0x44, 0x00, 0x00)` — sends 68 bytes of calldata
     *    (4 selector + 32 _num + 32 _addr) and expects no return data.
     *    The Singleton reads arguments directly from calldata offsets 0x04 and 0x24, which
     *    aligns exactly with the layout written here.
     *
     * @param _num  The 128-bit account number to register.
     * @param _addr The wallet address to link to `_num`.
     */
    function _linkNumber(uint128 _num, address _addr) internal {
        address _singleton = address(SINGLETON);
        assembly {
            // let ptr := mload(0x40)
            mstore(0x00, shl(0xe0, 0x52d067c4))
            mstore(0x04, _num)
            mstore(0x24, _addr)
            let success := call(gas(), _singleton, 0x00, 0x00, 0x44, 0x00, 0x00)
            if iszero(success) {
                revert(0x00, 0x00)
            }
        }
    }

    /**
     * @notice Resolves an account number to its linked wallet address.
     * @dev Child contracts should implement this by forwarding to `singleton.resolveAddress()`.
     * @param _num      The 128-bit account number to look up.
     * @param _registry The registry whose namespace should be searched.
     * @return          The linked wallet address, or address(0) if not found.
     */
    function resolveAddress(uint128 _num, address _registry) external view virtual returns (address);

    /**
     * @notice Resolves a wallet address back to its linked account number.
     * @dev Child contracts should implement this by forwarding to `singleton.resolveNumber()`.
     * @param _addr     The wallet address to look up.
     * @param _registry The registry whose namespace should be searched.
     * @return          The linked account number, or 0 if not found.
     */
    function resolveNumber(address _addr, address _registry) external view virtual returns (uint128);

    /**
     * @notice Returns the Namespace ID assigned to a given registry.
     * @dev Child contracts should implement this by forwarding to `singleton.namespace()`.
     * @param _registry The registry address to query.
     * @return          The assigned uint32 Namespace ID, or 0 if unregistered.
     */
    function namespace(address _registry) external view virtual returns (uint32);
}
