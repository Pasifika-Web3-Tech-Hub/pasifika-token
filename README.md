# Pasifika Token (PASI)

**ERC-20 Token for Pacific Islander Remittances**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C)](https://getfoundry.sh/)

## Overview

Pasifika Token (PASI) is an ERC-20 token designed specifically for Pacific Islander communities and their diaspora. Built for deployment on the **Pasifika Data Chain** (Chain ID: 999888), it enables:

- **Low cost remittances** - Only 0.5% fee vs 5-15% traditional services
- **Community governance** - Role based access control with validator organizations
- **Financial inclusion** - Simple token transfers without traditional banking barriers
- **Global cross border portability** - Works across US, New Zealand, Australia, Pacific Islands, EU, Russia, Asia, Africa, Arctic, Antarctica, and Middle East

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
| **Remittance Fee** | 0.5% (configurable, max 5%) |

## Features

### Core Functionality
- Standard ERC-20 transfers and approvals
- **Remittance tracking** with corridor identification (e.g., "US-TONGA", "NZ-SAMOA")
- **Batch transfers** for community distributions (up to 100 recipients)
- **Burnable** tokens for supply management
- **Fee collection** - 0.5% fee on remittances sent to Treasury

### Treasury & Governance
- **PasifikaTreasury contract** - Collects fees from remittances
- **Validator voting** - Validators propose and vote on fee distributions
- **Role based access control** using OpenZeppelin AccessControl
- **Validator management** - Add/remove trusted community organizations
- **Pausable** - Emergency stop functionality for security

## Cost Comparison

| Service | Fee | $500 Transfer Cost | Speed |
|---------|-----|-------------------|-------|
| Western Union | 5-10% | $25-50 | 1-3 days |
| MoneyGram | 5-8% | $25-40 | 1-3 days |
| Bank Wire | 3-5% | $15-25 | 3-5 days |
| **Pasifika Token** | **0.5%** | **$2.50** | **< 5 min** |

**Annual savings**: A family sending $500/month saves **$330-450/year** compared to traditional services.

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

**1. Create a keystore for your deployer wallet:**
```bash
cast wallet import pasifika-deployer --interactive
```
You will be prompted to enter your private key and a password to encrypt it.

**2. Deploy the token:**
```bash
forge script script/Deploy.s.sol --rpc-url https://rpc.pasifika.xyz --account pasifika-deployer --broadcast
```
You will be prompted for your keystore password.

**3. (Optional) List your keystores:**
```bash
cast wallet list
```

### Interact with Deployed Token

```bash
# Check balance
cast call <TOKEN_ADDRESS> "balanceOf(address)" <WALLET_ADDRESS> --rpc-url https://rpc.pasifika.xyz

# Transfer tokens (using keystore)
cast send <TOKEN_ADDRESS> "transfer(address,uint256)" <TO_ADDRESS> <AMOUNT> --account pasifika-deployer --rpc-url https://rpc.pasifika.xyz

# Send remittance with corridor tracking (using keystore)
cast send <TOKEN_ADDRESS> "sendRemittance(address,uint256,string)" <TO_ADDRESS> <AMOUNT> "US-TONGA" --account pasifika-deployer --rpc-url https://rpc.pasifika.xyz
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

### Fee Functions

```solidity
// Calculate fee for an amount
function calculateFee(uint256 amount) external view returns (uint256);

// Set treasury address (ADMIN only)
function setTreasury(address newTreasury) external;

// Set fee in basis points, 50 = 0.5% (ADMIN only)
function setFeeBasisPoints(uint256 newFeeBasisPoints) external;
```

### Events

```solidity
event RemittanceSent(
    address indexed from,
    address indexed to,
    uint256 amount,
    uint256 fee,
    string corridor,
    uint256 timestamp
);

event ValidatorAdded(address indexed validator, string organization);
event ValidatorRemoved(address indexed validator);
event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
event FeeUpdated(uint256 oldFee, uint256 newFee);
```

## Treasury Contract

The `PasifikaTreasury` contract collects fees and enables validator governance for distributions.

### Treasury Functions

```solidity
// Propose a distribution (VALIDATOR only)
function proposeDistribution(address recipient, uint256 amount, string calldata description) external returns (uint256 proposalId);

// Vote on a proposal (VALIDATOR only)
function vote(uint256 proposalId, bool support) external;

// Execute approved distribution (anyone can call after voting period)
function executeDistribution(uint256 proposalId) external;

// View treasury balance
function treasuryBalance() external view returns (uint256);

// Get proposal details
function getProposal(uint256 proposalId) external view returns (...);
```

### Governance Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `votingPeriod` | 3 days | Time for validators to vote |
| `quorumPercent` | 51% | Required validator participation |

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
- Reentrancy protection on critical treasury functions
- Custom errors for gas-efficient reverts

### Audit Status

✅ **Audited** - Security audit completed January 13, 2026

| Severity | Found | Fixed |
|----------|-------|-------|
| Critical | 0 | - |
| High | 2 | ✅ 2 |
| Medium | 3 | ✅ 2 |
| Low | 4 | ✅ 4 |
| Informational | 5 | ✅ 4 |

**Key Security Features Implemented:**
- **[H-01] Fixed** - Treasury balance verification at execution time prevents race conditions
- **[H-02] Fixed** - ReentrancyGuard protects treasury distributions
- **[M-02] Fixed** - Validator count stored at proposal creation prevents quorum manipulation
- **[L-01] Fixed** - Zero address validation in constructor
- **[L-03] Fixed** - Voting period bounds (1-30 days)
- **[I-05] Fixed** - Custom errors replace require strings for gas savings

**Audit Report:** [2026-01-13-pasifika-token-audit-report.pdf](../codehawks-security-portfolio/2026-01-13-pasifika-token-audit-report.pdf)

## Development

### Project Structure

```
pasifika-token/
├── src/
│   ├── PasifikaToken.sol      # Main token contract
│   └── PasifikaTreasury.sol   # Treasury & governance contract
├── script/
│   └── Deploy.s.sol           # Deployment scripts
├── test/
│   └── PasifikaToken.t.sol    # Unit tests (38 tests)
├── lib/                        # Dependencies (forge-std, openzeppelin)
├── foundry.toml               # Foundry configuration
├── remappings.txt             # Import remappings
└── README.md
```

### Adding a New Feature

1. Implement in `src/PasifikaToken.sol` or `src/PasifikaTreasury.sol`
2. Add tests in `test/PasifikaToken.t.sol`
3. Run `forge test` to verify
4. Update deployment script if needed

### Test Coverage

```bash
# Run all 38 tests
forge test

# With gas report
forge test --gas-report
```

## License

MIT License - see [LICENSE](LICENSE)

## Links

- **Pasifika Data Chain**: [pasifika-poa-chain](../pasifika-poa-chain/)
- **Whitepaper**: [WHITEPAPER.md](./docs/WHITEPAPER.md)
- **Website**: https://pasifika.xyz
- **Contact**: edwin@pasifika.xyz

---

*Empowering Pacific communities through blockchain technology*
