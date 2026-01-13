// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title PasifikaTreasury
 * @author Pasifika Web3 Tech Hub
 * @notice Treasury contract for collecting fees and distributing to validators via governance
 * @dev Validators can propose and vote on distributions from the treasury
 */
contract PasifikaTreasury is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    IERC20 public immutable token;

    struct Distribution {
        address recipient;
        uint256 amount;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    uint256 public proposalCount;
    mapping(uint256 => Distribution) public distributions;
    
    uint256 public votingPeriod = 3 days;
    uint256 public quorumPercent = 51; // 51% of validators must vote for

    event DistributionProposed(
        uint256 indexed proposalId,
        address indexed recipient,
        uint256 amount,
        string description,
        uint256 deadline
    );

    event Voted(
        uint256 indexed proposalId,
        address indexed validator,
        bool support
    );

    event DistributionExecuted(
        uint256 indexed proposalId,
        address indexed recipient,
        uint256 amount
    );

    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);

    /**
     * @notice Initialize the treasury
     * @param _token Address of the Pasifika Token
     * @param _admin Address of the admin
     */
    constructor(address _token, address _admin) {
        require(_token != address(0), "Invalid token address");
        require(_admin != address(0), "Invalid admin address");
        
        token = IERC20(_token);
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(VALIDATOR_ROLE, _admin);
    }

    /**
     * @notice Propose a distribution from the treasury
     * @param recipient Address to receive the distribution
     * @param amount Amount of tokens to distribute
     * @param description Reason for the distribution
     * @return proposalId The ID of the created proposal
     */
    function proposeDistribution(
        address recipient,
        uint256 amount,
        string calldata description
    ) external onlyRole(VALIDATOR_ROLE) returns (uint256 proposalId) {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient treasury balance");

        proposalId = proposalCount++;
        Distribution storage d = distributions[proposalId];
        d.recipient = recipient;
        d.amount = amount;
        d.description = description;
        d.deadline = block.timestamp + votingPeriod;
        d.executed = false;

        emit DistributionProposed(proposalId, recipient, amount, description, d.deadline);
    }

    /**
     * @notice Vote on a distribution proposal
     * @param proposalId ID of the proposal
     * @param support True to vote for, false to vote against
     */
    function vote(uint256 proposalId, bool support) external onlyRole(VALIDATOR_ROLE) {
        Distribution storage d = distributions[proposalId];
        
        require(block.timestamp < d.deadline, "Voting period ended");
        require(!d.hasVoted[msg.sender], "Already voted");
        require(!d.executed, "Already executed");

        d.hasVoted[msg.sender] = true;

        if (support) {
            d.votesFor++;
        } else {
            d.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @notice Execute an approved distribution
     * @param proposalId ID of the proposal to execute
     */
    function executeDistribution(uint256 proposalId) external {
        Distribution storage d = distributions[proposalId];
        
        require(block.timestamp >= d.deadline, "Voting period not ended");
        require(!d.executed, "Already executed");
        require(d.votesFor > d.votesAgainst, "Proposal not approved");
        
        uint256 totalVotes = d.votesFor + d.votesAgainst;
        uint256 validatorCount = getValidatorCount();
        require(
            totalVotes * 100 >= validatorCount * quorumPercent,
            "Quorum not reached"
        );

        d.executed = true;
        token.safeTransfer(d.recipient, d.amount);

        emit DistributionExecuted(proposalId, d.recipient, d.amount);
    }

    /**
     * @notice Add a validator
     * @param validator Address of the validator
     */
    function addValidator(address validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VALIDATOR_ROLE, validator);
        emit ValidatorAdded(validator);
    }

    /**
     * @notice Remove a validator
     * @param validator Address of the validator
     */
    function removeValidator(address validator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(VALIDATOR_ROLE, validator);
        emit ValidatorRemoved(validator);
    }

    /**
     * @notice Update voting period
     * @param newPeriod New voting period in seconds
     */
    function setVotingPeriod(uint256 newPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPeriod >= 1 days, "Voting period too short");
        votingPeriod = newPeriod;
    }

    /**
     * @notice Update quorum percentage
     * @param newQuorum New quorum percentage (1-100)
     */
    function setQuorumPercent(uint256 newQuorum) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newQuorum > 0 && newQuorum <= 100, "Invalid quorum");
        quorumPercent = newQuorum;
    }

    /**
     * @notice Get treasury balance
     * @return balance Current token balance of treasury
     */
    function treasuryBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Check if an address has voted on a proposal
     * @param proposalId ID of the proposal
     * @param voter Address to check
     * @return hasVoted True if the address has voted
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return distributions[proposalId].hasVoted[voter];
    }

    /**
     * @notice Get proposal details
     * @param proposalId ID of the proposal
     */
    function getProposal(uint256 proposalId) external view returns (
        address recipient,
        uint256 amount,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 deadline,
        bool executed
    ) {
        Distribution storage d = distributions[proposalId];
        return (
            d.recipient,
            d.amount,
            d.description,
            d.votesFor,
            d.votesAgainst,
            d.deadline,
            d.executed
        );
    }

    /**
     * @notice Get the number of validators (approximate via role member count)
     * @dev This is a simplified implementation
     */
    function getValidatorCount() public view returns (uint256) {
        return getRoleMemberCount(VALIDATOR_ROLE);
    }

    /**
     * @notice Check if an address is a validator
     * @param account Address to check
     */
    function isValidator(address account) external view returns (bool) {
        return hasRole(VALIDATOR_ROLE, account);
    }
}
