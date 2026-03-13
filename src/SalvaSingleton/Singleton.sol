// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Salva Singleton
 * @author Charlie @ Salva Protocol
 * @notice Core registry enabling namespace-isolated account number to address resolution.
 *
 * @dev SALVA MAPPING ABSTRACTION (SMA):
 * Standard Solidity nested mappings perform TWO keccak256 operations:
 *   1. keccak256(outerKey . slot)       → intermediate pointer
 *   2. keccak256(innerKey . intermediate) → final storage location
 *
 * SMA collapses this into ONE keccak256 by packing namespace, key, and slot into a single
 * 256-bit word using memory stores (mstore), then hashing that single word. This transforms
 * a nested mapping into what behaves like a flat mapping with a composite key.
 *
 * Example for _numberToWallet[namespace][number]:
 *   Standard:  keccak256(namespace . slot_2) → temp
 *             keccak256(number . temp)       → final pointer  (TWO hashes)
 *   SMA:      mstore namespace, number, slot_2 into memory
 *             keccak256(packed_data)         → final pointer  (ONE hash)
 *
 * Memory packing uses 3 mstore operations per lookup:
 *   mstore(0x00, namespace)
 *   mstore(0x20, key)        // uint128 number or address wallet
 *   mstore(0x40, slot)
 *   keccak256(0x00, 0x60)    // hash 96 bytes (3 words)
 *
 * Trade-off: All storage access must use inline assembly. High-level `mapping[key]` syntax
 * cannot be used, as it would apply Solidity's double-hash scheme and hit the wrong slot.
 */
contract Singleton {
    error Singleton__Already_Initialized();
    /**
     * @dev Protocol version stored as a bytecode constant.
     * Declared `constant` so the value is embedded directly in bytecode, eliminating SLOAD cost.
     */
    uint8 private constant _VERSION = 2;

    /**
     * @dev Storage layout (slots are explicit because assembly references them by index):
     *   Slot 0: _registryNamespace (mapping(address => bytes32))
     *   Slot 1: _numberToWallet    (mapping(bytes32 => mapping(uint128 => address)))
     *   Slot 2: _walletToNumber    (mapping(bytes32 => mapping(address => uint128)))
     *
     * WARNING: Adding, removing, or reordering any state variable above will shift these
     * slot indices and silently corrupt all assembly-based storage reads and writes.
     */
    mapping(address => bytes32) private _registryNamespace;
    mapping(bytes32 => mapping(uint128 => address)) private _numberToWallet;
    mapping(bytes32 => mapping(address => uint128)) private _walletToNumber;

    /**
     * @dev Guards `initializeRegistry` against reentrancy.
     *
     * Transient reentrancy lock (EIP-1153) — reads transient slot 0x00 and reverts if it
     * is already set to 1. If not set, it writes 1 immediately. Because transient storage
     * is scoped to the current transaction and resets automatically at the end of it, this
     * is a cheaper alternative to a persistent storage-based reentrancy guard.
     * Consequence: a registry cannot call `initializeRegistry`
     */
    modifier nonReentrant() {
        assembly {
            if eq(tload(0x00), 0x01) {
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
     * @dev Uses standard Solidity mapping access for _registryNamespace since it's a single-level
     * mapping (no nested double-hash overhead). The namespace is derived via keccak256(abi.encode(msg.sender))
     * for uniqueness and collision resistance.
     *
     * @return bytes32 Namespace ID assigned to the calling registry.
     */
    function initializeRegistry() external nonReentrant returns (bytes32) {
        if (namespace(msg.sender) > 0) {
            revert Singleton__Already_Initialized();
        }

        bytes32 nSpace = keccak256(abi.encode(msg.sender));
        _registryNamespace[msg.sender] = nSpace;

        assembly {
            tstore(0x00, 0x00)
        }

        return nSpace;
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
     *    Standard Solidity mapping access for _registryNamespace[caller()].
     *    Reverts if the caller has no namespace (ID == 0).
     *
     * 2. SMA pointer derivation:
     *    For _numberToWallet:
     *      mstore(0x00, nSpace)
     *      mstore(0x20, num)
     *      mstore(0x40, _numberToWallet.slot)
     *      keccak256(0x00, 0x60) → storage pointer
     *      This replaces Solidity's TWO-hash nested mapping with ONE hash.
     *
     *    For _walletToNumber:
     *      mstore(0x00, nSpace)
     *      mstore(0x20, wallet)
     *      mstore(0x40, _walletToNumber.slot)
     *      keccak256(0x00, 0x60) → storage pointer
     *
     * 3. One-to-one invariant:
     *    Both storage slots are checked before any write. If either is already non-zero the call
     *    reverts, preventing a number from being reassigned to a new address and preventing an
     *    address from claiming a second number.
     */
    function linkNumber() public {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, _registryNamespace.slot)
            let nSpace := sload(keccak256(0x00, 0x40))
            if iszero(nSpace) {
                revert(0x00, 0x00)
            }

            let num := calldataload(0x04)
            let wallet := calldataload(0x24)

            mstore(0x00, nSpace)
            mstore(0x20, num)
            mstore(0x40, _numberToWallet.slot)
            let addrPtr := keccak256(0x00, 0x60)

            mstore(0x20, wallet)
            mstore(0x40, _walletToNumber.slot)
            let numPtr := keccak256(0x00, 0x60)

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
     *
     * @dev Uses SMA to derive storage pointer with one keccak256 instead of two.
     */
    function resolveAddress(uint128 _num, address _registry) external view returns (address _wallet) {
        bytes32 nSpace = namespace(_registry);
        assembly {
            mstore(0x00, nSpace)
            mstore(0x20, _num)
            mstore(0x40, _numberToWallet.slot)
            _wallet := sload(keccak256(0x00, 0x60))
        }
    }

    /**
     * @notice Resolves a wallet address back to its linked account number within a registry's namespace.
     * @param _wallet   The wallet address to look up.
     * @param _registry The registry contract whose namespace should be searched.
     * @return _num     The linked account number, or 0 if no mapping exists.
     *
     * @dev Uses SMA to derive storage pointer with one keccak256 instead of two.
     */
    function resolveNumber(address _wallet, address _registry) external view returns (uint128 _num) {
        bytes32 nSpace = namespace(_registry);
        assembly {
            mstore(0x00, nSpace)
            mstore(0x20, _wallet)
            mstore(0x40, _walletToNumber.slot)
            _num := sload(keccak256(0x00, 0x60))
        }
    }

    /**
     * @notice Returns the Namespace ID assigned to a given registry contract.
     * @dev Returns 0 if the address has never called `initializeRegistry`.
     *      Used internally by `resolveAddress` and `resolveNumber`, and available externally
     *      for integrations that need to verify a registry's namespace status.
     * @param _registry The registry address to query.
     * @return assigned bytes32 Namespace ID, or 0 if unregistered.
     */
    function namespace(address _registry) public view returns (bytes32) {
        return _registryNamespace[_registry];
    }

    /**
     * @notice Returns the protocol version.
     * @return The uint8 version constant baked into bytecode.
     */
    function version() public pure returns (uint8) {
        return _VERSION;
    }
}
