// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PasifikaToken.sol";
import "../src/PasifikaTreasury.sol";

/**
 * @title DeployEthereum
 * @notice Deployment script for Pasifika Token on Ethereum/L2 networks for DEX trading
 * @dev This deploys PASI token to public networks where it can be traded on Uniswap, etc.
 * 
 * Prerequisites:
 *   1. Get an Etherscan API key: https://etherscan.io/myapikey
 *   2. Get an RPC URL (Alchemy/Infura): https://alchemy.com or https://infura.io
 *   3. Set up a deployer wallet with ETH for gas
 * 
 * Setup:
 *   export ETHERSCAN_API_KEY="your-api-key"
 *   export ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR-KEY"
 *   cast wallet import deployer --interactive
 * 
 * Deploy to Sepolia testnet (recommended first):
 *   forge script script/DeployEthereum.s.sol --rpc-url sepolia --account deployer --broadcast --verify
 * 
 * Deploy to Ethereum mainnet:
 *   forge script script/DeployEthereum.s.sol --rpc-url mainnet --account deployer --broadcast --verify
 * 
 * Deploy to Base:
 *   forge script script/DeployEthereum.s.sol --rpc-url base --account deployer --broadcast --verify
 */
contract DeployEthereum is Script {
    // Initial supply for DEX liquidity: 10 million tokens
    uint256 constant INITIAL_SUPPLY = 10_000_000 * 10 ** 18;

    function run() external {
        // Get deployer address from environment variable
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        
        console.log("=== Deploying PASI Token for DEX Trading ===");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Initial Supply:", INITIAL_SUPPLY / 10 ** 18, "PASI");

        vm.startBroadcast(deployer);

        // 1. Deploy Token
        PasifikaToken token = new PasifikaToken(deployer, INITIAL_SUPPLY);
        console.log("");
        console.log("PasifikaToken deployed at:", address(token));

        // 2. Deploy Treasury
        PasifikaTreasury treasury = new PasifikaTreasury(address(token), deployer);
        console.log("PasifikaTreasury deployed at:", address(treasury));

        // 3. Link Treasury to Token
        token.setTreasury(address(treasury));
        console.log("Treasury linked to Token");

        vm.stopBroadcast();

        // Post-deployment instructions
        console.log("");
        console.log("=== NEXT STEPS FOR DEX TRADING ===");
        console.log("1. Contract will auto-verify on Etherscan if --verify flag used");
        console.log("2. Add liquidity on Uniswap:");
        console.log("   - Go to https://app.uniswap.org/add");
        console.log("   - Paste token address:", address(token));
        console.log("   - Pair with ETH or USDC");
        console.log("   - Set initial price and add liquidity");
        console.log("");
        console.log("3. View on Etherscan:");
        if (block.chainid == 1) {
            console.log("   https://etherscan.io/token/", address(token));
        } else if (block.chainid == 11155111) {
            console.log("   https://sepolia.etherscan.io/token/", address(token));
        } else if (block.chainid == 8453) {
            console.log("   https://basescan.org/token/", address(token));
        } else if (block.chainid == 42161) {
            console.log("   https://arbiscan.io/token/", address(token));
        } else if (block.chainid == 137) {
            console.log("   https://polygonscan.com/token/", address(token));
        }
    }
}
