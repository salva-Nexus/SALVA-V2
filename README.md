<div align="center">
  <h1>🛡️ Salva </h1>
  <p><b>On-Chain Payment Infrastructure for the Next Billion</b></p>
  
  <img src="https://img.shields.io/badge/Network-Base-blue?style=for-the-badge&logo=base" />
  <img src="https://img.shields.io/badge/Stack-Solidity_|_Assembly/Yul-61DAFB?style=for-the-badge&logo=react" />
</div>

## Why Salva?

Salva lets you link account numbers (like `5265733930`) to wallet addresses (`0x123...`). Each registry gets its own isolated namespace, so multiple applications can use the same Salva Singleton without interfering with each other.

## Features

- **Gas optimized** — Custom storage layout
- **Namespace isolation** — Your registry's mappings are completely separate from everyone else's
- **One-to-one enforcement** — Numbers and addresses can only be linked once (no reassignment)
- **Minimal overhead** — Assembly-based calls skip Solidity's ABI encoding overhead

## Installation

```bash
git clone --recursive https://github.com/salva-Nexus/SALVA-V2.git
cd SALVA-V2
forge install
forge build
```

## Integration

### Singleton Address

**Base Mainnet:** `<SINGLETON_ADDRESS_HERE>`  
**Base Testnet:** `0x679816DA395418c2c72BAD63652badC10Fe78A68`

The Singleton is already deployed. Just use the address above.

### Build your registry

```solidity
import {BaseRegistry} from "./BaseRegistry.sol";

contract MyRegistry is BaseRegistry {
    bytes32 public myNamespace;

    constructor(address singleton) BaseRegistry(singleton) {
        myNamespace = SINGLETON.initializeRegistry();
    }

    function link(uint128 number, address wallet) external {
        _linkNumber(number, wallet);
    }

    // Required view functions
    function resolveAddress(uint128 num, address registry) external view override returns (address) {
        return SINGLETON.resolveAddress(num, registry);
    }

    function resolveNumber(address addr, address registry) external view override returns (uint128) {
        return SINGLETON.resolveNumber(addr, registry);
    }

    function namespace(address registry) external view override returns (bytes32) {
        return SINGLETON.namespace(registry);
    }
}
```

### Deploy

```solidity
MyRegistry registry = new MyRegistry(SINGLETON_ADDRESS);
```

### Use it

```solidity
registry.link(1234567890, 0xYourWalletAddress);
address wallet = registry.resolveAddress(1234567890, address(registry));
```

## Testing

```bash
forge test
forge test -vvv  # verbose
```

## License

MIT