<div align="center">
  <h1>🛡️ Salva Naming Service (SNS)</h1>
  <p><b>On-Chain Alias Resolution Infrastructure for the Next Billion</b></p>

  <img src="https://img.shields.io/badge/Network-Base-blue?style=for-the-badge&logo=base" />
  <img src="https://img.shields.io/badge/Stack-Solidity_|_Assembly/Yul-61DAFB?style=for-the-badge&logo=ethereum" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</div>

---

# 🛡️ Salva Naming Service (SNS)

In the traditional world, you send money using a name. In crypto, you are forced to use long, intimidating addresses like `0x71C7656EC7ab88b098defB751B7401B5f6d8976F`. One wrong character, and your funds are gone forever.

Salva bridges this gap. It is a secure, decentralized naming layer that allows any app — a wallet, a bank, or a payment protocol — to give its users a simple, human-readable **Name Alias** that resolves directly to their wallet address.

---

## 💡 The Problem

Crypto today feels like the early internet, where you had to type raw IP addresses to visit a website. It is error-prone and blocks the next billion users from joining because the interface is too technical and unforgiving.

---

## ✨ The Salva Solution

Salva allows apps to create their own **Namespaces**. A user registers a single Name Alias (like `alice`) and that name resolves directly to their wallet address.

- Alice is `alice@salva`. When you send to her, the protocol resolves her name directly to her wallet address.
- Bob is `bob@coinbase`. His name resolves to his wallet address within the Coinbase namespace.
- The same person can hold `miracle@salva` as their main identity, `miracle_business@coinbase` for one venture, and `miracle_savings@coinbase` for another — all pointing to separate wallets.

---

## 🌟 Why Salva is Different

**Identity You Can Trust**
Namespaces are protected by a Guardians system (MultiSig). No one can impersonate a major brand like `@metamask` or `@trustwallet` — every namespace must be verified by a quorum of validators before it goes live.

**Total Isolation**
What happens in `@salva` stays in `@salva`. `alice@salva` and `alice@coinbase` are entirely distinct identities. Each app has total control over its own phonebook with zero interference from other namespaces.

**Phishing Defense**
Salva automatically prevents look-alike scams using lowercase enforcement and alphabetical flipping for underscore-split names. `charles_okoronkwo` and `okoronkwo_charles` resolve to the exact same record — making name-order squatting economically pointless.

**Permanent and Cheap**
Registration is a one-time fee of **$1 USD** paid in ETH, priced live via Chainlink. No renewals. No annual fees. You pay once and the alias is yours until you choose to unlink it.

---

## 🗺️ How It Works

### 1. The Verification (Guardians)

Before an app can start naming its users, it must be approved. Salva uses a **48-hour security window** for every new namespace registration. This delay allows validators to detect and block fraudulent or malicious namespace claims before they are finalized on-chain.

### 2. The App Gateways (Registries)

Once approved, an app gets its own isolated **Registry** — a dedicated contract through which its users register and manage their aliases. Each registry is deployed by Salva and is the only authorized caller for its namespace in the singleton.

### 3. Backend Authorization (Signature Gate)

Every `link` call must carry a valid ECDSA signature from the Salva backend. This ensures all registrations pass through the off-chain reserved-name whitelist check before touching the chain — without making the registry permissioned or breaking the user's `msg.sender` identity.

### 4. The Resolution (The Result)

When a name is queried, the singleton resolves the alias to its linked wallet address instantly using a welded keccak256 storage key — no loops, no lookups, one `sload`.

| Name Alias          | Namespace    | Resolves To        |
| :------------------ | :----------- | :----------------- |
| `alice`             | `@salva`     | `0x123...`         |
| `bob`               | `@coinbase`  | `0x456...`         |
| `miracle`           | `@salva`     | `0x789...`         |
| `miracle_business`  | `@coinbase`  | `0xabc...`         |
| `aggregatorv3_base` | `@chainlink` | `0xaggrv3baseaddr` |

---

## 🏗️ Contract Architecture

```
MultiSig
  └── proposeInitialization → validateRegistry → executeInit
        └── Singleton.initializeRegistry(registry, namespaceHandle, length)

User EOA
  └── BaseRegistry.link(name, wallet, signature)
        ├── ecrecover(signature) == backendSigner  ✓
        └── Singleton.linkNameAlias(name, wallet, senderEOA)
              ├── namespace(registry) → @salva
              ├── _normalizeAndValidate(name)       → canonical form
              ├── _computeNameHash(name, @salva)    → storage key
              └── _performLinkToWallet(key, wallet) → sstore

User EOA
  └── BaseRegistry.unlink(name)
        └── Singleton.unlink(name, senderEOA)
              ├── _normalizeAndValidate(name)       → canonical form
              ├── _computeNameHash(name, @salva)    → storage key
              ├── _checkCaller(senderEOA, key)      → ownership verify
              └── _performUnlink(key, senderHash)   → sstore(0x00)
```

---

## 🛠️ Developer Installation

```bash
git clone https://github.com/salva-Nexus/SALVA-V2.git
cd SALVA-V2
forge install
forge build
```

### Testing

```bash
forge test
forge test -vvv
```

---

## ⚖️ License

Distributed under the MIT License. See [`LICENSE`](./LICENSE) for more information.