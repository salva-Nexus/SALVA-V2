<div align="center">
  <h1>🛡️ Salva V2 </h1>
  <p><b>On-Chain Payment Infrastructure for the Next Billion</b></p>
  
  <img src="https://img.shields.io/badge/Network-Base-blue?style=for-the-badge&logo=base" />
  <img src="https://img.shields.io/badge/Stack-Solidity_|_Assembly/Yul-61DAFB?style=for-the-badge&logo=react" />
</div>

# 🛡️ Salva V2

In the traditional world, you send money using a **Phone Number** or a **Name**. In crypto, you have to use long, confusing addresses like `0x71C...`.

**Salva** bridges this gap. It allows any application (like a bank, a wallet, or a payment app) to create its own private directory where users can link their real-world identity to their digital wallet—safely, permanently, and with zero room for impersonation.

### Key Benefits

- **Universal onchain naming + resolution Layer** Charles can map he's coinbase address to charles@coinbase, chainlink can point AggregatorV3 address to aggregatorv3@chainlink, or vrf@chainlink.. all differ across all Singleton deployed accross various chains.

- **Phishing Protection:** Scammers can't trick you by using capital letters (e.g., `Charles` vs `charles`). Salva sees them as the same person.
- **One Person, One Name:** You can't "squat" on multiple names within the same app.

---

```solidity
// Singleton - Base Testnet -> <>
// Singleton - Base Mainnet -> <>
// Singleton - Eth Testnet -> <>
// Singleton - Eth Mainnet -> <>
```

## 🗺️ How it Works (The Flow)

Salva is structured like a secure vault. Before a user can get a name, the "Owner" of that namespace must be verified by a group of guardians (Validators).

### 1. The Guardians (MultiSig)

A group of trusted Validators must agree to open a new "Registry."

- **The Rule:** No one can just claim a brand name like `@coinbase` or `@metamask` without thorough verification.
- **The Safety:** Every major change has a **24-hour waiting period** to prevent rush decisions.

### 2. The App Gateways (Registries)

Each app (like a Payment App) gets its own isolated "Registry."
A Registry like - @salva, @coinbase, @uniswap, etc

- Think of this as a private phonebook.
- What happens in the "App A" phonebook doesn't affect "App B."

### 3. The Users

Once an app is live, users can link their details:

**Link a Name:**

SALVA WALLET: `alice` → `0x123...` - alice now owns alice@salva pointing to her Salva Wallet Address

COINBASE: `alice` → `0x456...` - alice now owns alice@coinbase pointing to her coinbase Wallet Address

UNISWAP: `alice` → `0x789...` - alice now owns alice@uniswap pointing to her uniswap Wallet Address

UNISWAP: `router` -> `0x453...` - Uniswap router contract address now at router@uniswap

**Link a Number:** 

SALVA WALLET: `5265733930` → `0x123...` - alice now owns 5265733930 pointing to her Salva Wallet Address

Numbers are not welded to name spaces, but they are still isolated per namespace techinically.

And so on..

**NOTE:** alice@salva and alice@coinbase are different identities, made unique by there namespaces - @walletname

---

## 🛠️ Developer Integration

### Installation

```bash
git clone --recursive https://github.com/salva-Nexus/SALVA-V2.git
cd SALVA-V2
forge install
forge build
```

### Testing

```bash
forge test
```

## ⚖️ License

Distributed under the MIT License. See `LICENSE` for more information.