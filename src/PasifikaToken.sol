// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // Max 5% fee
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000;
    uint256 public constant MAX_BATCH_RECIPIENTS = 100;

    error InvalidAdmin();
    error InvalidRecipient();
    error InvalidAmount();
    error InitialSupplyExceedsMax();
    error WouldExceedMaxSupply();
    error FeeTooHigh();
    error ArrayLengthMismatch();
    error TooManyRecipients();

    address public treasury;
    uint256 public feeBasisPoints = 50; // 0.5% default fee (50 basis points)

    event RemittanceSent(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 fee,
        string corridor,
        uint256 timestamp
    );

    event BatchTransfer(
        address indexed from,
        uint256 recipientCount,
        uint256 totalAmount
    );

    event ValidatorAdded(address indexed validator, string organization);
    event ValidatorRemoved(address indexed validator);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Initialize the Pasifika Token
     * @param defaultAdmin Address that will have the DEFAULT_ADMIN_ROLE
     * @param initialSupply Initial token supply to mint to the admin
     */
    constructor(
        address defaultAdmin,
        uint256 initialSupply
    ) ERC20("Pasifika Token", "PASI") {
        if (defaultAdmin == address(0)) revert InvalidAdmin();
        if (initialSupply > MAX_SUPPLY) revert InitialSupplyExceedsMax();
        
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        _grantRole(VALIDATOR_ROLE, defaultAdmin);

        if (initialSupply > 0) {
            _mint(defaultAdmin, initialSupply);
        }
    }

    /**
     * @notice Send a remittance with corridor tracking (fee applied)
     * @param to Recipient address
     * @param amount Amount of tokens to send (before fee)
     * @param corridor Remittance corridor (e.g., "US-TONGA", "NZ-SAMOA")
     */
    function sendRemittance(
        address to,
        uint256 amount,
        string calldata corridor
    ) external whenNotPaused {
        if (to == address(0)) revert InvalidRecipient();
        if (amount == 0) revert InvalidAmount();
        
        uint256 fee = calculateFee(amount);
        uint256 netAmount = amount - fee;
        
        if (fee > 0 && treasury != address(0)) {
            _transfer(msg.sender, treasury, fee);
        }
        _transfer(msg.sender, to, netAmount);
        
        emit RemittanceSent(msg.sender, to, netAmount, fee, corridor, block.timestamp);
    }

    /**
     * @notice Calculate fee for a given amount
     * @param amount Amount to calculate fee for
     * @return fee The calculated fee
     */
    function calculateFee(uint256 amount) public view returns (uint256) {
        if (treasury == address(0) || feeBasisPoints == 0) {
            return 0;
        }
        return (amount * feeBasisPoints) / BASIS_POINTS_DENOMINATOR;
    }

    /**
     * @notice Set the treasury address
     * @param newTreasury New treasury address
     */
    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldTreasury = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    /**
     * @notice Set the fee in basis points (100 = 1%)
     * @param newFeeBasisPoints New fee in basis points
     */
    function setFeeBasisPoints(uint256 newFeeBasisPoints) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newFeeBasisPoints > MAX_FEE_BASIS_POINTS) revert FeeTooHigh();
        uint256 oldFee = feeBasisPoints;
        feeBasisPoints = newFeeBasisPoints;
        emit FeeUpdated(oldFee, newFeeBasisPoints);
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
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();
        if (recipients.length > MAX_BATCH_RECIPIENTS) revert TooManyRecipients();

        uint256 len = recipients.length;
        uint256 totalAmount = 0;
        
        for (uint256 i = 0; i < len;) {
            if (recipients[i] == address(0)) revert InvalidRecipient();
            totalAmount += amounts[i];
            _transfer(msg.sender, recipients[i], amounts[i]);
            unchecked { ++i; }
        }
        
        emit BatchTransfer(msg.sender, len, totalAmount);
    }

    /**
     * @notice Mint new tokens (only MINTER_ROLE)
     * @param to Address to receive minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (totalSupply() + amount > MAX_SUPPLY) revert WouldExceedMaxSupply();
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
