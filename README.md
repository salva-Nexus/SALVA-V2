<div align="center">
  <h1>🛡️ Salva V2</h1>
  <p><b>On-Chain Naming + Resolution Infrastructure for the Next Billion</b></p>

  <img src="https://img.shields.io/badge/Network-Base-blue?style=for-the-badge&logo=base" />
  <img src="https://img.shields.io/badge/Stack-Solidity_|_Assembly/Yul-61DAFB?style=for-the-badge&logo=ethereum" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</div>

---

# 🛡️ Salva V2

In the traditional world, you send money using a name. In crypto, you are forced to use long, intimidating addresses like `0x71C7656EC7ab88b098defB751B7401B5f6d8976F`. One wrong character, and your funds are gone.

Salva bridges this gap. It is a secure, decentralized naming layer that allows any app — a wallet, a bank, or a payment protocol — to give its users a simple, human-readable **Name Alias**.

---

## 💡 The Problem

Currently, crypto feels like the early days of the internet, where you had to type in raw IP addresses to visit a website. It's error-prone and blocks the "next billion" users from joining because the interface is too technical.

---

## ✨ The Salva Solution

Salva allows apps to create their own **Namespaces**. A user registers a single Name Alias (like `alice`), and that name points to the specific destination data the app needs — whether that's a blockchain Wallet Address or an internal system Number.

- Alice is `alice@salva`. When you send to her, the protocol resolves her name directly to her Wallet Address.
- Charlie is `charlie@salva`. Because his app uses internal routing, his name resolves directly to a Number.

---

## 🌟 Why Salva is Different

**Identity You Can Trust**
Namespaces are protected by a "Guardians" system (MultiSig). No one can impersonate a major brand like `@metamask` or `@trustwallet` — every namespace must be verified by a quorum of validators.

**Total Isolation**
What happens in `@salva` stays in `@salva`. `alice@salva` and `alice@coinbase` are entirely distinct. Each app has total control over its own "phonebook."

**Phishing Defense**
Salva automatically prevents "look-alike" scams using lowercase enforcement and alphabetical flipping for names with underscores. `charles_okoronkwo` and `okoronkwo_charles` resolve to the same record.

**Strict Integrity**
The protocol enforces a One-Link rule. A name can point to a Wallet **or** a Number, but never both. This prevents data ambiguity and ensures 1:1 mapping.

---

## 🗺️ How It Works

### 1. The Verification (Guardians)

Before an app can start naming its users, it must be approved. Salva uses a **48-hour security window** for every new app registration. This delay allows validators to detect and block any malicious or fraudulent namespace claims.

### 2. The App Gateways (Registries)

Once approved, an app gets its own isolated **Registry** — a private digital space where it manages how its users' names resolve, without interference from others.

### 3. The Resolution (The Result)

When a name is queried, the Singleton resolves the Name Alias to its linked data instantly.

| Name Alias          | App Namespace | Resolves To...  | Type   |
| :---------          | :------------ | :-------------- | :----- |
| `alice`             | `@salva`      | `0x123...`      | Wallet |
| `bob`               | `@coinbase`   | `0x456...`      | Wallet |
| `charlie`           | `@salva`      | `5265733930`    | Number |
| `usdc_eth`          | `@usdc~       | `0xusdcethaddr` | Address|
| `aggregatorv3_base` | `@chainlink`  | `0xaggrv3baseaddr`  | Address|

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