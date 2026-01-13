// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PasifikaToken.sol";
import "../src/PasifikaTreasury.sol";

/**
 * @title DeployPasifikaToken
 * @notice Deployment script for Pasifika Token and Treasury on Pasifika Data Chain
 * @dev Run with: forge script script/Deploy.s.sol --rpc-url https://rpc.pasifika.xyz --account <keystore_name> --broadcast
 * 
 * Setup keystore:
 *   cast wallet import pasifika-deployer --interactive
 * 
 * Deploy:
 *   forge script script/Deploy.s.sol --rpc-url https://rpc.pasifika.xyz --account pasifika-deployer --broadcast
 */
contract DeployPasifikaToken is Script {
    // Initial supply: 100 million tokens (10% of max supply)
    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10 ** 18;

    function run() external {
        // Get the deployer address from the private key used for broadcast
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        address deployer;
        
        if (deployerPrivateKey != 0) {
            deployer = vm.addr(deployerPrivateKey);
            vm.startBroadcast(deployerPrivateKey);
        } else {
            // When using --account flag, use tx.origin as deployer
            deployer = tx.origin;
            vm.startBroadcast();
        }
        
        console.log("=== Deploying Pasifika Token System ===");
        console.log("Deployer:", deployer);
        console.log("Initial Supply:", INITIAL_SUPPLY / 10 ** 18, "PASI");

        // 1. Deploy Token
        PasifikaToken token = new PasifikaToken(deployer, INITIAL_SUPPLY);
        console.log("PasifikaToken deployed at:", address(token));

        // 2. Deploy Treasury
        PasifikaTreasury treasury = new PasifikaTreasury(address(token), deployer);
        console.log("PasifikaTreasury deployed at:", address(treasury));

        // 3. Link Treasury to Token (enables fee collection)
        token.setTreasury(address(treasury));
        console.log("Treasury linked to Token");

        vm.stopBroadcast();

        console.log("");
        console.log("=== Deployment Complete ===");
        console.log("Token Name:", token.name());
        console.log("Token Symbol:", token.symbol());
        console.log("Total Supply:", token.totalSupply() / 10 ** 18, "PASI");
        console.log("Fee:", token.feeBasisPoints(), "basis points (0.5%)");
        console.log("Treasury:", address(treasury));
    }
}

/**
 * @title SetupValidators
 * @notice Script to add validator organizations to both Token and Treasury
 * @dev Run with: forge script script/Deploy.s.sol:SetupValidators --rpc-url https://rpc.pasifika.xyz --account pasifika-deployer --broadcast --sig "run(address,address)" <TOKEN_ADDRESS> <TREASURY_ADDRESS>
 */
contract SetupValidators is Script {
    function run(address tokenAddress, address treasuryAddress) external {
        PasifikaToken token = PasifikaToken(tokenAddress);
        PasifikaTreasury treasury = PasifikaTreasury(treasuryAddress);

        vm.startBroadcast();

        // Example validators - replace with actual community organization addresses
        // Token validators (for token governance)
        // token.addValidator(0x..., "Tonga Community Center");
        // token.addValidator(0x..., "Samoa Cultural Association");
        // token.addValidator(0x..., "Fiji Pacific Hub");

        // Treasury validators (for fee distribution voting)
        // treasury.addValidator(0x...);

        vm.stopBroadcast();

        console.log("Validators setup complete");
        console.log("Token:", tokenAddress);
        console.log("Treasury:", treasuryAddress);
    }
}
