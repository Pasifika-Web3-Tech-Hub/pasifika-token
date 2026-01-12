// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PasifikaToken
 * @author Pasifika Web3 Tech Hub
 * @notice ERC-20 token for Pacific Islander remittances and community economic activity
 * @dev Deployed on Pasifika Data Chain (Chain ID: 999888) with zero gas fees
 * 
 * Key Features:
 * - Low-cost transfers for Pacific diaspora remittances
 * - Role-based access control for community governance
 * - Pausable for emergency situations
 * - Burnable for token economics management
 * - Minting controlled by authorized validators
 */
contract PasifikaToken is ERC20, ERC20Burnable, ERC20Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion tokens

    event RemittanceSent(
        address indexed from,
        address indexed to,
        uint256 amount,
        string corridor,
        uint256 timestamp
    );

    event ValidatorAdded(address indexed validator, string organization);
    event ValidatorRemoved(address indexed validator);

    /**
     * @notice Initialize the Pasifika Token
     * @param defaultAdmin Address that will have the DEFAULT_ADMIN_ROLE
     * @param initialSupply Initial token supply to mint to the admin
     */
    constructor(
        address defaultAdmin,
        uint256 initialSupply
    ) ERC20("Pasifika Token", "PASI") {
        require(initialSupply <= MAX_SUPPLY, "Initial supply exceeds max supply");
        
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        _grantRole(VALIDATOR_ROLE, defaultAdmin);

        if (initialSupply > 0) {
            _mint(defaultAdmin, initialSupply);
        }
    }

    /**
     * @notice Send a remittance with corridor tracking
     * @param to Recipient address
     * @param amount Amount of tokens to send
     * @param corridor Remittance corridor (e.g., "US-TONGA", "NZ-SAMOA")
     */
    function sendRemittance(
        address to,
        uint256 amount,
        string calldata corridor
    ) external whenNotPaused {
        require(to != address(0), "Cannot send to zero address");
        require(amount > 0, "Amount must be greater than zero");
        
        _transfer(msg.sender, to, amount);
        
        emit RemittanceSent(msg.sender, to, amount, corridor, block.timestamp);
    }

    /**
     * @notice Batch transfer to multiple recipients (useful for community distributions)
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to send
     */
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external whenNotPaused {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length <= 100, "Too many recipients");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot send to zero address");
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    /**
     * @notice Mint new tokens (only MINTER_ROLE)
     * @param to Address to receive minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Would exceed max supply");
        _mint(to, amount);
    }

    /**
     * @notice Pause all token transfers (emergency only)
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause token transfers
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Add a validator organization
     * @param validator Address of the validator
     * @param organization Name of the organization
     */
    function addValidator(
        address validator,
        string calldata organization
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VALIDATOR_ROLE, validator);
        emit ValidatorAdded(validator, organization);
    }

    /**
     * @notice Remove a validator
     * @param validator Address of the validator to remove
     */
    function removeValidator(address validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(VALIDATOR_ROLE, validator);
        emit ValidatorRemoved(validator);
    }

    /**
     * @notice Check if an address is a validator
     * @param account Address to check
     * @return bool True if the address has VALIDATOR_ROLE
     */
    function isValidator(address account) external view returns (bool) {
        return hasRole(VALIDATOR_ROLE, account);
    }

    // Required overrides for multiple inheritance
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
