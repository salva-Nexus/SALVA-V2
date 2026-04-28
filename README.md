<div align="center">

<br />

### **Salva Naming Service (SNS)**
*On-Chain Alias Resolution Infrastructure for the Next Billion*

<br />

[![Network](https://img.shields.io/badge/Network-Base_Mainnet_&_Testnet-0052FF?style=for-the-badge&logo=coinbase)](https://base.org)
[![Language](https://img.shields.io/badge/Stack-Solidity_|_Assembly%2FYul-363636?style=for-the-badge&logo=ethereum)](https://soliditylang.org)
[![License](https://img.shields.io/badge/License-MIT-D4AF37?style=for-the-badge)](./LICENSE)
[![Status](https://img.shields.io/badge/Status-Live_on_Mainnet-00C853?style=for-the-badge)](https://basescan.org)

<br />

> **SNS is live.** Human-readable wallet aliases are now available on Base Mainnet and Base Testnet.

<br />

</div>

---

## 📋 Table of Contents

- [The Problem](#-the-problem)
- [The Solution](#-the-salva-solution)
- [Contract Addresses](#-contract-addresses)
- [Why Salva is Different](#-why-salva-is-different)
- [How It Works](#️-how-it-works)
- [Contract Architecture](#️-contract-architecture)
- [Developer Installation](#️-developer-installation)
- [License](#️-license)

---

## 💡 The Problem

Crypto today feels like the early internet, where you had to type raw IP addresses to visit a website.

You send money using a name in the traditional world. In crypto, you are forced to memorize or copy intimidating strings like `0x71C7656EC7ab88b098defB751B7401B5f6d8976F`. One wrong character and your funds are gone — permanently, irreversibly, with no recourse.

This is not a UX problem. It is a trust problem. And it is blocking the next billion users from ever joining.

---

## ✨ The Salva Solution

Salva is a secure, decentralized naming layer that lets any app — a wallet, a neobank, a payment protocol — give its users a simple, human-readable **Name Alias** that resolves directly to their on-chain address.

```
alice@salva          →   0x123...abc
bob@coinbase         →   0x456...def
miracle@salva        →   0x789...ghi
miracle_biz@coinbase →   0xabc...jkl
```

Register once. Yours forever.

---

## 📍 Contract Addresses

### 🟢 Base Mainnet

| Contract     | Address                                                                                                                              |
| :----------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| **Singleton** | [`0xc03eDeB2EF48B752ce46600d088206f5334e5546`](https://basescan.org/address/0xaeb9fcC270F240FAA9A7f9d8b84eD6fE5c8f6b61) |

### 🔵 Base Testnet (Sepolia)

| Contract      | Address                                                                                                                                            |
| :------------ | :------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Singleton** | [`0x75e36Bb8F36A6aE1799E34E3161719964fECC22C`](https://sepolia.basescan.org/address/0xa77eF18F47DE0AcA77faBF329FE0f8820D7F98a6) |

> The Singleton is the single source of truth for all namespace storage and alias resolution across every registry. Individual registry (gateway) addresses are deployed per namespace and can be queried from the factory.

---

## 🌟 Why Salva is Different

### 🔐 Identity You Can Trust

Namespaces are protected by a **Guardians system** — a MultiSig governance layer with a mandatory 24-hour security window on every new namespace. No one can impersonate `@metamask`, `@trustwallet`, or `@coinbase` without passing a validator quorum. The delay exists precisely to let guardians detect and block fraudulent claims before they finalize.

### 🏠 Total Namespace Isolation

`alice@salva` and `alice@coinbase` are entirely distinct identities. Each app owns its own phonebook with zero interference from any other namespace. Storage keys are computed from a welded `keccak256` hash of `name + namespace`, making collision mathematically impossible.

### 🛡️ Phishing Defense by Design

Salva automatically neutralizes look-alike scams:

- All names are **lowercased** at the contract level
- Underscore-split names are **alphabetically normalized** — `charles_obi` and `obi_charles` resolve to the same record

Name-order squatting becomes economically pointless. There is nothing to squat.

### 💰 Permanent and Affordable

Registration is a **one-time fee** paid in USDC, USDT or NGNs.

---

## 🗺️ How It Works

### 1. App Gateways (Registries)

Each approved namespace gets an isolated **Registry** — a minimal proxy clone deployed by the `RegistryFactory`. The registry is the only authorized caller for its namespace slot in the Singleton.

```
RegistryFactory.deployRegistry(@coinbase)
  → deploys EIP-1167 clone
  → initializes with Singleton + namespace
  → returns registry address to MultiSig
```

### 2. Signature Authorization Gate

Every `link` call must carry a valid ECDSA signature from the Salva backend signer. This ensures all registrations pass the off-chain reserved-name whitelist check before touching the chain — without making the registry permissioned or breaking the user's `msg.sender` identity.

The signer address is read from the `RegistryFactory` on every call, so key rotation propagates instantly to all registries with no per-clone update.

### 3. Name Registration Flow

```
User Safe
  └── MultiSend (delegatecall)
        ├── tx1: feeToken.approve(registry, 1 USDC)
        └── tx2: registry.link(nameBytes, wallet, feeToken, signature)
                    ├── ecrecover(signature) == backendSigner  ✓
                    ├── IERC20(feeToken).safeTransferFrom(Safe → Singleton)
                    └── Singleton.linkNameAlias(name, wallet, Safe)
                          ├── namespace(registry) → @salva
                          ├── _normalizeAndValidate(name)
                          ├── _computeNameHash(name, @salva) → storage key
                          └── _performLinkToWallet(key, wallet) → sstore
```

### 4. Resolution (Instant)

```
resolveAddress("alice@salva") → keccak256("alice@salva") → 0x123...abc
```

One function call. One storage slot. Deterministic.

### 5. Name Resolution Table

| Name Alias            | Namespace      | Resolves To         |
| :-------------------- | :------------- | :------------------ |
| `alice`               | `@salva`       | `0x123...abc`       |
| `bob`                 | `@coinbase`    | `0x456...def`       |
| `miracle`             | `@salva`       | `0x789...ghi`       |
| `miracle_business`    | `@coinbase`    | `0xabc...jkl`       |
| `aggregatorv3_base`   | `@chainlink`   | `0xaggrv3...addr`   |

---

## 🛠️ Developer Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Setup

```bash
git clone https://github.com/salva-Nexus/SALVA-V2.git
cd SALVA-V2
forge install
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run with verbose trace output
forge test -vvv

# Run a specific test file
forge test --match-path test/BaseRegistry.t.sol -vvv
```

### Resolve a Name (via CLI)

```bash
# Resolve alice@salva on Base Mainnet
cast call 0x1E77312B4aF261F411F96aeb2eA20e13934b0D02 \
  "resolveAddress(bytes)(address)" \
  $(cast --from-utf8 "alice@salva") \
  --rpc-url https://mainnet.base.org

# Resolve on Base Testnet
cast call 0xa77eF18F47DE0AcA77faBF329FE0f8820D7F98a6 \
  "resolveAddress(bytes)(address)" \
  $(cast --from-utf8 "alice@salva") \
  --rpc-url https://sepolia.base.org
```

---

## ⚖️ License

Distributed under the MIT License. See [`LICENSE`](./LICENSE) for more information.

---

<div align="center">

Built on [Base](https://base.org) &nbsp;·&nbsp; Secured by [Safe](https://safe.global) &nbsp;·&nbsp; 

</div>