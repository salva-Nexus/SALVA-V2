<div align="center">
  <h1>🛡️ Salva </h1>
  <p><b>On-Chain Payment Infrastructure for the Next Billion</b></p>
  
  <img src="https://img.shields.io/badge/Network-Base-blue?style=for-the-badge&logo=base" />
  <img src="https://img.shields.io/badge/Stack-Node.js_|_React-61DAFB?style=for-the-badge&logo=react" />
  <img src="https://img.shields.io/badge/Standard-ERC--4337-orange?style=for-the-badge" />
</div>

---

## Overview

Salva V2 is built around two contracts:

- **Singleton** — the central storage layer. Holds all namespace assignments and bidirectional number-to-address mappings. All state lives here.
- **BaseRegistry** — an abstract contract your registry inherits from. Provides internal assembly wrappers that call the Singleton directly, cutting the gas overhead of Solidity's default ABI encoding.

The Singleton uses Salva Mapping Abstraction (SMA) that reduces every mapping lookup from two `keccak256` operations down to one by bit-packing the namespace, key, and slot into a single 256-bit word before hashing. This saves roughly ~2,000 gas per write and ~500 per read compared to standard nested mappings.

---

## How Integration Works

`BaseRegistry` holds a single `immutable` reference to the Singleton and exposes two `internal` functions your registry uses to interact with it. Your registry is also expected to implement three `external view` functions — `resolveAddress`, `resolveNumber`, and `namespace` — which are declared `virtual` in `BaseRegistry` and can be fulfilled by forwarding to the Singleton.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseRegistry} from "./BaseRegistry.sol";

contract UserRegistry is BaseRegistry {
    uint32 public myNamespace;

    constructor(address _singleton) BaseRegistry(_singleton) {
        // Don't initialize here! Contract not deployed yet!
    }

    /**
     * @notice Initialize the registry and receive namespace
     * @dev Must be called AFTER deployment, not in constructor
     */
    function initialize() external {
        myNamespace = _initialize();
    }

    function register(uint128 _id, address _user) external {
        // your access logic here
        _linkNumber(_id, _user);
    }

    function resolveAddress(uint128 _num, address _registry) 
        external 
        view 
        override 
        returns (address) 
    {
        return singleton.resolveAddress(_num, _registry);
    }

    function resolveNumber(address _addr, address _registry) 
        external 
        view 
        override 
        returns (uint128) 
    {
        return singleton.resolveNumber(_addr, _registry);
    }

    function namespace(address _registry) 
        external 
        view 
        override 
        returns (uint32) 
    {
        return singleton.namespace(_registry);
    }
}

```

---

## BaseRegistry Internals

### `_initialize()`

Calls `initializeRegistry()` on the Singleton (selector `0xb2a4b788`) and returns the assigned `uint32` Namespace ID.

The call writes the selector to `0x00`, calls the Singleton with 4 bytes of calldata, and reads the return value back from `0x00` — bypassing Solidity's return-data handling entirely.

**Important:** The Singleton's `onlyRegistry` modifier uses `caller()` to assign the namespace, so `_initialize()` must be called from the registry contract itself. Calling it through an intermediate contract will assign the namespace to the wrong address and revert on any future call from your registry.

The modifier also checks `EXTCODESIZE` on the caller, which means `_initialize()` cannot be called by an EOA and from within a constructor (where `extcodesize` is still 0). Deploy your registry first, then call `_initialize()` in a separate transaction or post-deploy setup step.

### `_linkNumber(uint128 _num, address _addr)`

Calls `linkNumber()` on the Singleton (selector `0x52d067c4`).

Manually packs the selector, `_num`, and `_addr` into memory slots `0x00`–`0x44` and fires the call with no return data expected. This avoids Solidity touching the free memory pointer for encoding and decoding.

The Singleton enforces a strict one-to-one invariant: a number cannot point to two addresses, and an address cannot hold two numbers. If either slot is already populated, the call reverts.

---

## Gas: Where the Savings Come From

**Selector packing** — `shl(0xe0, selector)` places the 4-byte function selector at the start of a 32-byte memory word manually. Solidity does this automatically but only after going through its memory management setup.

**Skipping the free memory pointer** — calldata is written directly into `0x00`–`0x44`. Solidity normally updates the free pointer at `0x40` before any memory write. Here, that update never happens.

**No return-data copy overhead** — `_linkNumber` passes `0x00` as the return data size so the EVM never copies return bytes into memory. `_initialize` reads the return value straight from `0x00` instead of going through Solidity's ABI decoder.

One thing worth being clear on: `BaseRegistry` still makes a real external `CALL` to the Singleton. The savings come entirely from stripping Solidity's encoding and decoding overhead around that call — not from eliminating the call itself.

---

## Constraints

**Hardcoded selectors** — `0xb2a4b788` (`initializeRegistry`) and `0x52d067c4` (`linkNumber`) are baked into `BaseRegistry`. If the Singleton's function names or parameter types ever change, these selectors must be updated manually.

**Write-once** — `_linkNumber` reverts if either the number or the address is already mapped. There is no update or overwrite path by design.

**No constructor initialization** — the Singleton's `onlyRegistry` modifier rejects callers with `EXTCODESIZE == 0`. `_initialize()` cannot be called inside a constructor. It must be called in a post-deployment transaction.

**No EOA namespaces** — the same `EXTCODESIZE` check blocks externally owned accounts from registering a namespace. Only deployed contracts qualify.

**Reentrancy guard** — the Singleton uses EIP-1153 transient storage as a per-transaction lock. A registry cannot call `initializeRegistry` more than once within the same transaction.

## 🚀 Installation & Setup

### 1. Clone the Repository

Clone the project along with its submodules to ensure all dependencies (OpenZeppelin, Forge-Std) are included:

```bash
git clone --recursive https://github.com/salva-Nexus/SALVA-V2.git
cd SALVA-V2
```

### 2. Install Dependencies

If you have already cloned the repo without submodules, or need to initialize them manually:

```bash
# Initialize and update submodules
git submodule update --init --recursive

# Install Forge dependencies
forge install
```

### 3. Build the Project

Verify that the environment is set up correctly by compiling the contracts:

```bash
forge build
```

---

## 🛠 Quick Start Integration

### 1. Inherit from BaseRegistry

Ensure your contract inherits `BaseRegistry.sol` and provides the Singleton address to the constructor.

### 2. Deploy & Initialize

Because of the `EXTCODESIZE` check, you cannot initialize in the constructor. Your deployment script should look like this:

```solidity
// Example Deployment Script
UserRegistry registry = new UserRegistry(SINGLETON_ADDRESS);
registry.initialize(); // This calls _initialize() internally
```

### 3. Run Tests

Validate your integration using the built-in test suite:

```bash
forge test
```
