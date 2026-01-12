# Pasifika Token (PASI)

**ERC-20 Token for Pacific Islander Remittances**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C)](https://getfoundry.sh/)

## Overview

Pasifika Token (PASI) is an ERC-20 token designed specifically for Pacific Islander communities and their diaspora. Built for deployment on the **Pasifika Data Chain** (Chain ID: 999888), it enables:

- **Low-cost remittances** - Near zero transaction fees on Pasifika PoA Chain
- **Community governance** - Role based access control with validator organizations
- **Financial inclusion** - Simple token transfers without traditional banking barriers
- **Global cross-border portability** - Works across US, New Zealand, Australia, Pacific Islands, EU, Russia, Asia, Africa, Arctic, Antarctica, and Middle East

## Token Specifications

| Property | Value |
|----------|-------|
| **Name** | Pasifika Token |
| **Symbol** | PASI |
| **Decimals** | 18 |
| **Max Supply** | 1,000,000,000 (1 billion) |
| **Initial Supply** | 100,000,000 (100 million) |
| **Standard** | ERC-20 |
| **Network** | Pasifika Data Chain (999888) |

## Features

### Core Functionality
- Standard ERC-20 transfers and approvals
- **Remittance tracking** with corridor identification (e.g., "US-TONGA", "NZ-SAMOA")
- **Batch transfers** for community distributions (up to 100 recipients)
- **Burnable** tokens for supply management

### Governance
- **Role based access control** using OpenZeppelin AccessControl
- **Validator management** - Add/remove trusted community organizations
- **Pausable** - Emergency stop functionality for security

### Roles
| Role | Description |
|------|-------------|
| `DEFAULT_ADMIN_ROLE` | Full administrative control |
| `MINTER_ROLE` | Can mint new tokens (up to max supply) |
| `PAUSER_ROLE` | Can pause/unpause transfers |
| `VALIDATOR_ROLE` | Trusted community validators |

## Installation

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Git

### Setup

```bash
# Clone the repository
cd /home/user/Documents/pasifika-web3-tech-hub/pasifika-token

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std

# Build
forge build

# Run tests
forge test
```

## Usage

### Build

```bash
forge build
```

### Test

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test test_SendRemittance

# Gas report
forge test --gas-report
```

### Deploy to Pasifika Data Chain

The Pasifika Data Chain is live at **https://rpc.pasifika.xyz**

```bash
# Deploy using your private key
PRIVATE_KEY=0x... forge script script/Deploy.s.sol --rpc-url https://rpc.pasifika.xyz --broadcast

# Or use the configured RPC alias
PRIVATE_KEY=0x... forge script script/Deploy.s.sol --rpc-url pasifika --broadcast
```

### Interact with Deployed Token

```bash
# Check balance
cast call <TOKEN_ADDRESS> "balanceOf(address)" <WALLET_ADDRESS> --rpc-url https://rpc.pasifika.xyz

# Transfer tokens
cast send <TOKEN_ADDRESS> "transfer(address,uint256)" <TO_ADDRESS> <AMOUNT> --private-key <PRIVATE_KEY> --rpc-url https://rpc.pasifika.xyz

# Send remittance with corridor tracking
cast send <TOKEN_ADDRESS> "sendRemittance(address,uint256,string)" <TO_ADDRESS> <AMOUNT> "US-TONGA" --private-key <PRIVATE_KEY> --rpc-url https://rpc.pasifika.xyz
```

## Contract API

### Core Functions

```solidity
// Standard ERC-20 transfer
function transfer(address to, uint256 amount) external returns (bool);

// Send remittance with corridor tracking
function sendRemittance(address to, uint256 amount, string calldata corridor) external;

// Batch transfer to multiple recipients
function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external;

// Mint new tokens (MINTER_ROLE only)
function mint(address to, uint256 amount) external;

// Burn tokens
function burn(uint256 amount) external;
```

### Governance Functions

```solidity
// Add a validator organization (ADMIN only)
function addValidator(address validator, string calldata organization) external;

// Remove a validator (ADMIN only)
function removeValidator(address validator) external;

// Check if address is a validator
function isValidator(address account) external view returns (bool);

// Pause all transfers (PAUSER_ROLE only)
function pause() external;

// Unpause transfers (PAUSER_ROLE only)
function unpause() external;
```

### Events

```solidity
event RemittanceSent(
    address indexed from,
    address indexed to,
    uint256 amount,
    string corridor,
    uint256 timestamp
);

event ValidatorAdded(address indexed validator, string organization);
event ValidatorRemoved(address indexed validator);
```

## Remittance Corridors

Supported corridor codes for tracking (examples):

### Pacific Region
| Corridor | Description |
|----------|-------------|
| `US-TONGA` | United States to Tonga |
| `US-SAMOA` | United States to Samoa |
| `US-FIJI` | United States to Fiji |
| `NZ-TONGA` | New Zealand to Tonga |
| `NZ-SAMOA` | New Zealand to Samoa |
| `AU-TONGA` | Australia to Tonga |
| `AU-FIJI` | Australia to Fiji |

### Europe (EU)
| Corridor | Description |
|----------|-------------|
| `EU-TONGA` | European Union to Tonga |
| `EU-SAMOA` | European Union to Samoa |
| `UK-FIJI` | United Kingdom to Fiji |

### Russia
| Corridor | Description |
|----------|-------------|
| `RU-TONGA` | Russia to Tonga |
| `RU-SAMOA` | Russia to Samoa |
| `RU-FIJI` | Russia to Fiji |

### Asia
| Corridor | Description |
|----------|-------------|
| `JP-TONGA` | Japan to Tonga |
| `CN-FIJI` | China to Fiji |
| `SG-SAMOA` | Singapore to Samoa |
| `KR-TONGA` | South Korea to Tonga |

### Middle East
| Corridor | Description |
|----------|-------------|
| `AE-TONGA` | UAE to Tonga |
| `SA-FIJI` | Saudi Arabia to Fiji |
| `QA-SAMOA` | Qatar to Samoa |

### Africa
| Corridor | Description |
|----------|-------------|
| `ZA-TONGA` | South Africa to Tonga |
| `NG-FIJI` | Nigeria to Fiji |
| `KE-SAMOA` | Kenya to Samoa |

### Polar Regions
| Corridor | Description |
|----------|-------------|
| `AQ-PACIFIC` | Antarctica to Pacific Islands |
| `AR-PACIFIC` | Arctic to Pacific Islands |

*Custom corridor codes can be used for any origin-destination pair.*

## Security

- Built on audited OpenZeppelin contracts (v5.0.1)
- Role based access control for sensitive operations
- Pausable functionality for emergency response
- Max supply cap prevents unlimited minting

### Audit Status

⚠️ **Not yet audited** - This token is in development phase. A security audit is recommended before mainnet deployment.

## Development

### Project Structure

```
pasifika-token/
├── src/
│   └── PasifikaToken.sol      # Main token contract
├── script/
│   └── Deploy.s.sol           # Deployment scripts
├── test/
│   └── PasifikaToken.t.sol    # Unit tests
├── lib/                        # Dependencies (forge-std, openzeppelin)
├── foundry.toml               # Foundry configuration
├── remappings.txt             # Import remappings
└── README.md
```

### Adding a New Feature

1. Implement in `src/PasifikaToken.sol`
2. Add tests in `test/PasifikaToken.t.sol`
3. Run `forge test` to verify
4. Update deployment script if needed

## License

MIT License - see [LICENSE](LICENSE)

## Links

- **Pasifika Data Chain**: [pasifika-poa-chain](../pasifika-poa-chain/)
- **PoC Documentation**: [pasifika_token_poc.md](./pasifika_token_poc.md)
- **Website**: https://pasifika.xyz
- **Contact**: edwin@pasifika.xyz

---

*Empowering Pacific communities through blockchain technology*
