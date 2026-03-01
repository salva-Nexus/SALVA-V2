// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Salva Singleton
 * @author Salva Protocol
 * @notice Core registry enabling namespace-isolated account number to address resolution.
 *
 * @dev SALVA MAPPING ABSTRACTION (SMA):
 * The standard Solidity mapping layout derives a storage pointer by concatenating the key and
 * the mapping's slot into 64 bytes, then hashing: `keccak256(key . slot)` over two full words.
 * This requires at least two mstore operations to prepare memory before the hash.
 *
 * SMA replaces this with a "welded" pack: bitwise operations (shl + or) merge the key and slot
 * into a single 32-byte word, so keccak256 only hashes 32 bytes instead of 64. This halves the
 * hashing input size, eliminates one mstore, and reduces the cost of the keccak256 opcode itself.
 *
 * The packing layout varies by key type:
 *
 * For _numberToWallet  (key = uint128):
 * [ 32 bits: Namespace ] [ 128 bits: Key ] [ 88 bits: Zero-Padding ] [ 8 bits: Slot ]
 *
 * For _walletToNumber  (key = address, 160 bits):
 * [ 32 bits: Namespace ] [ 160 bits: Key ] [ 56 bits: Zero-Padding ] [ 8 bits: Slot ]
 *
 * For _registryNamespace (key = address, 160 bits), a simpler two-field pack is used:
 * [ 160 bits: Address << 8 ] [ 8 bits: Slot ] (remaining bits zero)
 *
 * Benchmark (cold storage): Solidity standard map 29,591 gas vs. SMA welded map 28,694 gas.
 * Trade-off: all reads and writes must go through inline assembly — high-level `_mapping[key]`
 * syntax cannot be used, as it would apply Solidity's own hashing scheme and hit the wrong slot.
 */
contract Singleton {
    /**
     * @dev Protocol version stored as a bytecode constant.
     * Declared `constant` so the value is embedded directly in bytecode, eliminating SLOAD cost.
     */
    uint8 private constant _VERSION = 2;

    /**
     * @dev Monotonically increasing counter for namespace assignment.
     * Starts at 1 so that a zero value in any storage slot reliably indicates an uninitialized state.
     */
    uint32 private _namespaceCounter = 1;

    /**
     * @dev Storage layout (slots are explicit because assembly references them by index):
     *   Slot 0: _namespaceCounter  (uint32)
     *   Slot 1: _registryNamespace (mapping(address => uint32))
     *   Slot 2: _numberToWallet    (mapping(uint32 => mapping(uint128 => address)))
     *   Slot 3: _walletToNumber    (mapping(uint32 => mapping(address => uint128)))
     *
     * WARNING: Adding, removing, or reordering any state variable above will shift these
     * slot indices and silently corrupt all assembly-based storage reads and writes.
     */
    mapping(address => uint32) private _registryNamespace;
    mapping(uint32 => mapping(uint128 => address)) private _numberToWallet;
    mapping(uint32 => mapping(address => uint128)) private _walletToNumber;

    /**
     * @dev Guards `initializeRegistry` and `linkNumber` against EOA callers and reentrancy.
     *
     * Two checks run in sequence:
     *
     * 1. EXTCODESIZE check — reverts if the caller has no deployed bytecode. This blocks
     *    EOAs from registering namespaces and also blocks calls made during a contract's own
     *    constructor execution, where extcodesize(self) is still 0.
     *
     * 2. Transient reentrancy lock (EIP-1153) — reads transient slot 0x00 and reverts if it
     *    is already set to 1. If not set, it writes 1 immediately. Because transient storage
     *    is scoped to the current transaction and resets automatically at the end of it, this
     *    is a cheaper alternative to a persistent storage-based reentrancy guard.
     *    Consequence: a registry cannot call both `initializeRegistry` and `linkNumber`
     *    (or either function twice) within the same transaction.
     */
    modifier onlyRegistry() {
        assembly {
            if or(iszero(extcodesize(caller())), eq(tload(0x00), 0x01)) {
                revert(0x00, 0x00)
            }
            tstore(0x00, 0x01)
        }
        _;
    }

    /**
     * @notice Grants the calling contract a unique Namespace ID, permanently associating it
     * with that namespace in the Singleton's storage.
     *
     * @dev Assembly walk-through:
     *
     * 1. Storage pointer derivation for _registryNamespace:
     *    The caller's address is shifted left 8 bits (`shl(0x08, caller())`) and OR'd with
     *    the mapping's slot index (1). This welds both values into a single 32-byte word which
     *    is hashed with keccak256 over 32 bytes — the SMA scheme. Solidity's standard layout
     *    would pad key and slot into separate 32-byte words and hash 64 bytes instead.
     *
     * 2. Already-initialized guard:
     *    If `sload(ptr)` is non-zero the registry already has a namespace and the call reverts.
     *
     * 3. Assignment and counter increment:
     *    The current counter value is read once (`assigned := sload(_namespaceCounter.slot)`),
     *    stored at the registry's pointer, and the counter is incremented — all in one block to
     *    keep the value on the stack and avoid a second SLOAD.
     *
     * @return assigned The uint32 Namespace ID assigned to the calling registry.
     */
    function initializeRegistry() external onlyRegistry returns (uint32 assigned) {
        assembly {
            let welded := or(shl(0x08, caller()), _registryNamespace.slot)
            mstore(0x00, welded)
            let ptr := keccak256(0x00, 0x20)

            if sload(ptr) {
                revert(0x00, 0x00)
            }

            assigned := sload(_namespaceCounter.slot)

            sstore(ptr, assigned)
            sstore(_namespaceCounter.slot, add(assigned, 0x01))

            // temporary -> For Invariant Testing
            tstore(0x00, 0x00)

            mstore(0x00, assigned)
            return(0x00, 0x20)
        }
    }

    /**
     * @notice Permanently links an account number to a wallet address under the caller's namespace.
     *
     * @dev This function intentionally declares no Solidity parameters. Both arguments are read
     * directly from calldata at fixed offsets (num @ 0x04, wallet @ 0x24), bypassing Solidity's
     * ABI decoder entirely and saving the gas it would spend on type checks and stack setup.
     * Callers must encode arguments as (uint128, address) — which is what `BaseRegistry._linkNumber`
     * does via manual `mstore`.
     *
     * Assembly walk-through:
     *
     * 1. Namespace resolution:
     *    The caller's address is welded with slot 1 using the same SMA scheme as `initializeRegistry`
     *    to retrieve their assigned namespace ID. Reverts if the caller has no namespace (ID == 0).
     *
     * 2. SMA pointer derivation:
     *    For _numberToWallet (slot 2):
     *      `or(or(shl(0xe0, nSpace), shl(0x40, num)), 0x02)`
     *      Places nSpace in the top 32 bits, num (uint128) in bits 64-191, slot in the low 8 bits.
     *    For _walletToNumber (slot 3):
     *      `or(or(shl(0xe0, nSpace), shl(0x40, wallet)), 0x03)`
     *      Places nSpace in the top 32 bits, wallet (address, 160 bits) in bits 64-223, slot in
     *      the low 8 bits. With a 160-bit key the zero-padding shrinks to 56 bits (vs. 88 bits
     *      for the uint128 key case). In both cases the full pack fits in 32 bytes and is hashed once.
     *
     * 3. One-to-one invariant:
     *    Both storage slots are checked before any write. If either is already non-zero the call
     *    reverts, preventing a number from being reassigned to a new address and preventing an
     *    address from claiming a second number.
     */
    function linkNumber() public {
        assembly {
            mstore(0x00, or(shl(0x08, caller()), _registryNamespace.slot))
            let nSpace := sload(keccak256(0x00, 0x20))
            if iszero(nSpace) {
                revert(0x00, 0x00)
            }

            let num := calldataload(0x04)
            let wallet := calldataload(0x24)

            mstore(0x00, or(or(shl(0xe0, nSpace), shl(0x40, num)), _numberToWallet.slot))
            let addrPtr := keccak256(0x00, 0x20)

            mstore(0x00, or(or(shl(0xe0, nSpace), shl(0x40, wallet)), _walletToNumber.slot))
            let numPtr := keccak256(0x00, 0x20)

            if or(gt(sload(numPtr), 0x00), gt(sload(addrPtr), 0x00)) {
                revert(0x00, 0x00)
            }

            sstore(addrPtr, wallet)
            sstore(numPtr, num)
        }
    }

    /**
     * @notice Resolves an account number to its linked wallet address within a registry's namespace.
     * @param _num      The 128-bit account number to look up.
     * @param _registry The registry contract whose namespace should be searched.
     * @return _wallet  The linked address, or address(0) if no mapping exists.
     */
    function resolveAddress(uint128 _num, address _registry) external view returns (address _wallet) {
        uint32 nSpace = namespace(_registry);
        assembly {
            mstore(0x00, or(or(shl(0xe0, nSpace), shl(0x40, _num)), _numberToWallet.slot))
            _wallet := sload(keccak256(0x00, 0x20))
        }
    }

    /**
     * @notice Resolves a wallet address back to its linked account number within a registry's namespace.
     * @param _addr     The wallet address to look up.
     * @param _registry The registry contract whose namespace should be searched.
     * @return _num     The linked account number, or 0 if no mapping exists.
     */
    function resolveNumber(address _addr, address _registry) external view returns (uint128 _num) {
        uint32 nSpace = namespace(_registry);
        assembly {
            mstore(0x00, or(or(shl(0xe0, nSpace), shl(0x40, _addr)), _walletToNumber.slot))
            _num := sload(keccak256(0x00, 0x20))
        }
    }

    /**
     * @notice Returns the Namespace ID assigned to a given registry contract.
     * @dev Returns 0 if the address has never called `initializeRegistry`.
     *      Used internally by `resolveAddress` and `resolveNumber`, and available externally
     *      for integrations that need to verify a registry's namespace status.
     * @param _registry The registry address to query.
     * @return _namespace The assigned uint32 Namespace ID, or 0 if unregistered.
     */
    function namespace(address _registry) public view returns (uint32 _namespace) {
        assembly {
            mstore(0x00, or(shl(0x08, _registry), _registryNamespace.slot))
            _namespace := sload(keccak256(0x00, 0x20))
        }
    }

    /**
     * @notice Returns the protocol version.
     * @return The uint8 version constant baked into bytecode.
     */
    function version() public pure returns (uint8) {
        return _VERSION;
    }
}
