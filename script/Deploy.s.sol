// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PasifikaToken.sol";

/**
 * @title DeployPasifikaToken
 * @notice Deployment script for Pasifika Token on Pasifika Data Chain
 * @dev Run with: forge script script/Deploy.s.sol --rpc-url https://rpc.pasifika.xyz --broadcast
 */
contract DeployPasifikaToken is Script {
    // Initial supply: 100 million tokens (10% of max supply)
    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10 ** 18;

    function run() external {
        // Load deployer private key from environment
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying PasifikaToken...");
        console.log("Deployer:", deployer);
        console.log("Initial Supply:", INITIAL_SUPPLY / 10 ** 18, "PASI");

        vm.startBroadcast(deployerPrivateKey);

        PasifikaToken token = new PasifikaToken(deployer, INITIAL_SUPPLY);

        vm.stopBroadcast();

        console.log("PasifikaToken deployed at:", address(token));
        console.log("Token Name:", token.name());
        console.log("Token Symbol:", token.symbol());
        console.log("Total Supply:", token.totalSupply() / 10 ** 18, "PASI");
    }
}

/**
 * @title SetupValidators
 * @notice Script to add initial validator organizations
 */
contract SetupValidators is Script {
    function run(address tokenAddress) external {
        uint256 adminPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        PasifikaToken token = PasifikaToken(tokenAddress);

        vm.startBroadcast(adminPrivateKey);

        // Example validators - replace with actual community organization addresses
        // token.addValidator(0x..., "Tonga Community Center");
        // token.addValidator(0x..., "Samoa Cultural Association");
        // token.addValidator(0x..., "Fiji Pacific Hub");

        vm.stopBroadcast();

        console.log("Validators setup complete");
    }
}
