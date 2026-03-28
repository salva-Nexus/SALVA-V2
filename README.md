<div align="center">
  <h1>🛡️ Salva V2</h1>
  <p><b>On-Chain Naming + Resolution Infrastructure for the Next Billion</b></p>

  <img src="https://img.shields.io/badge/Network-Base-blue?style=for-the-badge&logo=base" />
  <img src="https://img.shields.io/badge/Stack-Solidity_|_Assembly/Yul-61DAFB?style=for-the-badge&logo=ethereum" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</div>

---

# 🛡️ Salva V2

In the traditional world, you send money using a **number** or a **name**. In crypto, you send to an address like `0x71C7656EC7ab88b098defB751B7401B5f6d8976F`.

**Salva** closes that gap. It allows any application — a wallet, a payment app, a protocol — to create its own isolated namespace where users can link a human-readable identity to their on-chain address. Permanently. Without impersonation.

Every namespace is isolated. `alice@salva` and `alice@coinbase` are different identities, belonging to different people, on different apps. The Singleton is the single source of truth for all of them.

---

## Key Properties

- **Universal On-Chain Identity Layer** — Any application can plug in. `charles@coinbase`, `aggregatorv3@chainlink`, `router@uniswap` — all resolved through the same Singleton deployed across chains.
- **Namespace Isolation** — What happens inside `@salva` has no effect on `@coinbase`. Each registry is completely independent.
- **Phishing Protection** — The contract enforces lowercase-only identities. `Charles` and `charles` are treated as the same person. A scammer cannot register a visually identical name.
- **One Identity Per Wallet** — A wallet can hold at most one name alias and one number alias per namespace. No squatting.
- **Permanent Registration** — Once a namespace is registered, it cannot be deleted. Aliases are one-time assignments.

---

```solidity
// Singleton - Base Testnet  -> <>
// Singleton - Base Mainnet  -> <>
// Singleton - Eth Testnet   -> <>
// Singleton - Eth Mainnet   -> <>
```

---

## 🗺️ How it Works

### 1. The Guardians — MultiSig

No namespace can be claimed without approval from a quorum of Salva validators.

- A validator proposes a new registry with its namespace identifier (e.g. `@coinbase`).
- A majority of validators must approve the proposal.
- Once quorum is reached, a **48-hour timelock** begins. The proposal cannot execute until the window expires — giving validators time to detect and block any malicious or erroneous registration.
- After 48 hours, any validator can call `executeInit` to finalize the registration.

This prevents namespace squatting. Nobody registers `@metamask` or `@trustwallet` without the real protocol being behind it.

### 2. The App Gateways — Registries

Each approved application gets its own isolated registry under a unique namespace.

Think of it as a private phonebook. `@salva` is Salva's phonebook. `@coinbase` is Coinbase's phonebook. The contents of one have no effect on the other.

### 3. The Users — Aliases

Once a registry is live, users can link their identity:

**Name Aliases**

| App | Name | Wallet |
|---|---|---|
| `@salva` | `alice` | `0x123...` → `alice@salva` |
| `@coinbase` | `alice` | `0x456...` → `alice@coinbase` |
| `@uniswap` | `router` | `0x453...` → `router@uniswap` |

**Number Aliases**

| App | Number | Wallet |
|---|---|---|
| `@salva` | `5265733930` | `0x123...` |

Numbers are scoped per namespace. The same number can exist across different registries without collision.

> `alice@salva` and `alice@coinbase` are different identities. The namespace is what makes them unique.

---

## 🛠️ Developer Integration

### Installation

```bash
git clone --recursive https://github.com/salva-Nexus/SALVA-V2.git
cd SALVA-V2
forge install
forge build
```

### Build Your Registry

```solidity
import {BaseRegistry} from "./BaseRegistry.sol";

contract MyRegistry is BaseRegistry {
    constructor(address singleton) BaseRegistry(singleton) {}

    function link(uint128 number, address wallet) external {}
}
```

### Testing

```bash
forge test
forge test -vvv
```

---

## ⚖️ License

Distributed under the MIT License. See `LICENSE` for more information.