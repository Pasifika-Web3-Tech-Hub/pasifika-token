// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PasifikaToken.sol";
import "../src/PasifikaTreasury.sol";

contract PasifikaTokenTest is Test {
    PasifikaToken public token;
    PasifikaTreasury public treasury;
    
    address public admin = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public validator = address(4);
    
    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10 ** 18;

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

    function setUp() public {
        vm.startPrank(admin);
        token = new PasifikaToken(admin, INITIAL_SUPPLY);
        treasury = new PasifikaTreasury(address(token), admin);
        token.setTreasury(address(treasury));
        vm.stopPrank();
    }

    // ============ Constructor Tests ============

    function test_Constructor() public view {
        assertEq(token.name(), "Pasifika Token");
        assertEq(token.symbol(), "PASI");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY);
    }

    function test_Constructor_ZeroInitialSupply() public {
        vm.prank(admin);
        PasifikaToken zeroToken = new PasifikaToken(admin, 0);
        assertEq(zeroToken.totalSupply(), 0);
    }

    function test_Constructor_RevertExceedsMaxSupply() public {
        uint256 exceedingSupply = token.MAX_SUPPLY() + 1;
        vm.expectRevert(PasifikaToken.InitialSupplyExceedsMax.selector);
        new PasifikaToken(admin, exceedingSupply);
    }

    function test_Constructor_RevertZeroAdmin() public {
        vm.expectRevert(PasifikaToken.InvalidAdmin.selector);
        new PasifikaToken(address(0), INITIAL_SUPPLY);
    }

    function test_AdminHasAllRoles() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), admin));
        assertTrue(token.hasRole(token.MINTER_ROLE(), admin));
        assertTrue(token.hasRole(token.VALIDATOR_ROLE(), admin));
    }

    // ============ Transfer Tests ============

    function test_Transfer() public {
        uint256 amount = 1000 * 10 ** 18;
        
        vm.prank(admin);
        token.transfer(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY - amount);
    }

    // ============ Remittance Tests ============

    function test_SendRemittance_WithFee() public {
        uint256 amount = 1000 * 10 ** 18;
        string memory corridor = "US-TONGA";
        
        vm.prank(admin);
        token.transfer(user1, amount);
        
        uint256 expectedFee = token.calculateFee(amount); // 0.5% = 5 tokens
        uint256 expectedNet = amount - expectedFee;
        
        vm.prank(user1);
        token.sendRemittance(user2, amount, corridor);
        
        assertEq(token.balanceOf(user2), expectedNet);
        assertEq(token.balanceOf(address(treasury)), expectedFee);
        assertEq(token.balanceOf(user1), 0);
    }

    function test_SendRemittance_NoFeeWithoutTreasury() public {
        // Deploy token without treasury
        vm.prank(admin);
        PasifikaToken tokenNoTreasury = new PasifikaToken(admin, INITIAL_SUPPLY);
        
        uint256 amount = 1000 * 10 ** 18;
        
        vm.prank(admin);
        tokenNoTreasury.transfer(user1, amount);
        
        vm.prank(user1);
        tokenNoTreasury.sendRemittance(user2, amount, "US-TONGA");
        
        // No fee deducted when treasury is not set
        assertEq(tokenNoTreasury.balanceOf(user2), amount);
    }

    function test_SendRemittance_RevertZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(PasifikaToken.InvalidRecipient.selector);
        token.sendRemittance(address(0), 100, "US-TONGA");
    }

    function test_SendRemittance_RevertZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert(PasifikaToken.InvalidAmount.selector);
        token.sendRemittance(user1, 0, "US-TONGA");
    }

    // ============ Fee Tests ============

    function test_CalculateFee() public view {
        uint256 amount = 1000 * 10 ** 18;
        uint256 fee = token.calculateFee(amount);
        // 0.5% fee = 5 tokens
        assertEq(fee, 5 * 10 ** 18);
    }

    function test_SetFeeBasisPoints() public {
        vm.prank(admin);
        token.setFeeBasisPoints(100); // 1%
        
        assertEq(token.feeBasisPoints(), 100);
        
        uint256 amount = 1000 * 10 ** 18;
        uint256 fee = token.calculateFee(amount);
        assertEq(fee, 10 * 10 ** 18); // 1% = 10 tokens
    }

    function test_SetFeeBasisPoints_RevertTooHigh() public {
        vm.prank(admin);
        vm.expectRevert(PasifikaToken.FeeTooHigh.selector);
        token.setFeeBasisPoints(501); // > 5%
    }

    function test_SetTreasury() public {
        address newTreasury = address(0x999);
        
        vm.expectEmit(true, true, false, false);
        emit TreasuryUpdated(address(treasury), newTreasury);
        
        vm.prank(admin);
        token.setTreasury(newTreasury);
        
        assertEq(token.treasury(), newTreasury);
    }

    // ============ Batch Transfer Tests ============

    function test_BatchTransfer() public {
        address[] memory recipients = new address[](3);
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = validator;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10 ** 18;
        amounts[1] = 200 * 10 ** 18;
        amounts[2] = 300 * 10 ** 18;
        
        vm.prank(admin);
        token.batchTransfer(recipients, amounts);
        
        assertEq(token.balanceOf(user1), 100 * 10 ** 18);
        assertEq(token.balanceOf(user2), 200 * 10 ** 18);
        assertEq(token.balanceOf(validator), 300 * 10 ** 18);
    }

    function test_BatchTransfer_RevertArrayMismatch() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        
        vm.prank(admin);
        vm.expectRevert(PasifikaToken.ArrayLengthMismatch.selector);
        token.batchTransfer(recipients, amounts);
    }

    // ============ Minting Tests ============

    function test_Mint() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        
        vm.prank(admin);
        token.mint(user1, mintAmount);
        
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }

    function test_Mint_RevertNotMinter() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user1, 1000);
    }

    function test_Mint_RevertExceedsMaxSupply() public {
        uint256 remaining = token.MAX_SUPPLY() - token.totalSupply();
        
        vm.prank(admin);
        vm.expectRevert(PasifikaToken.WouldExceedMaxSupply.selector);
        token.mint(user1, remaining + 1);
    }

    // ============ Pause Tests ============

    function test_Pause() public {
        vm.prank(admin);
        token.pause();
        
        assertTrue(token.paused());
    }

    function test_Pause_RevertNotPauser() public {
        vm.prank(user1);
        vm.expectRevert();
        token.pause();
    }

    function test_TransferWhenPaused_Reverts() public {
        vm.prank(admin);
        token.pause();
        
        vm.prank(admin);
        vm.expectRevert();
        token.transfer(user1, 100);
    }

    function test_Unpause() public {
        vm.startPrank(admin);
        token.pause();
        token.unpause();
        vm.stopPrank();
        
        assertFalse(token.paused());
    }

    // ============ Validator Tests ============

    function test_AddValidator() public {
        string memory org = "Tonga Community Center";
        
        vm.expectEmit(true, false, false, true);
        emit ValidatorAdded(validator, org);
        
        vm.prank(admin);
        token.addValidator(validator, org);
        
        assertTrue(token.isValidator(validator));
    }

    function test_RemoveValidator() public {
        vm.startPrank(admin);
        token.addValidator(validator, "Test Org");
        
        vm.expectEmit(true, false, false, false);
        emit ValidatorRemoved(validator);
        
        token.removeValidator(validator);
        vm.stopPrank();
        
        assertFalse(token.isValidator(validator));
    }

    function test_AddValidator_RevertNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        token.addValidator(validator, "Test Org");
    }

    // ============ Burn Tests ============

    function test_Burn() public {
        uint256 burnAmount = 1000 * 10 ** 18;
        
        vm.prank(admin);
        token.burn(burnAmount);
        
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
    }

    // ============ Fuzz Tests ============

    function testFuzz_Transfer(uint256 amount) public {
        amount = bound(amount, 1, INITIAL_SUPPLY);
        
        vm.prank(admin);
        token.transfer(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
    }

    function testFuzz_SendRemittance(uint256 amount, string calldata corridor) public {
        amount = bound(amount, 1, INITIAL_SUPPLY);
        
        vm.prank(admin);
        token.transfer(user1, amount);
        
        uint256 expectedFee = token.calculateFee(amount);
        uint256 expectedNet = amount - expectedFee;
        
        vm.prank(user1);
        token.sendRemittance(user2, amount, corridor);
        
        assertEq(token.balanceOf(user2), expectedNet);
        assertEq(token.balanceOf(address(treasury)), expectedFee);
    }
}

contract PasifikaTreasuryTest is Test {
    PasifikaToken public token;
    PasifikaTreasury public treasury;
    
    address public admin = address(1);
    address public validator1 = address(2);
    address public validator2 = address(3);
    address public validator3 = address(4);
    address public recipient = address(5);
    address public user1 = address(6);
    
    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10 ** 18;

    function setUp() public {
        vm.startPrank(admin);
        token = new PasifikaToken(admin, INITIAL_SUPPLY);
        treasury = new PasifikaTreasury(address(token), admin);
        token.setTreasury(address(treasury));
        
        // Add validators
        treasury.addValidator(validator1);
        treasury.addValidator(validator2);
        treasury.addValidator(validator3);
        vm.stopPrank();
        
        // Fund treasury with some tokens
        vm.prank(admin);
        token.transfer(address(treasury), 1000 * 10 ** 18);
    }

    function test_TreasuryBalance() public view {
        assertEq(treasury.treasuryBalance(), 1000 * 10 ** 18);
    }

    function test_ProposeDistribution() public {
        vm.prank(validator1);
        uint256 proposalId = treasury.proposeDistribution(
            recipient,
            100 * 10 ** 18,
            "Validator reward Q1"
        );
        
        assertEq(proposalId, 0);
        
        (address r, uint256 amt, string memory desc, , , , uint256 valCount, bool executed) = treasury.getProposal(0);
        assertEq(r, recipient);
        assertEq(amt, 100 * 10 ** 18);
        assertEq(desc, "Validator reward Q1");
        assertEq(valCount, 4); // admin + 3 validators
        assertFalse(executed);
    }

    function test_VoteOnProposal() public {
        vm.prank(validator1);
        treasury.proposeDistribution(recipient, 100 * 10 ** 18, "Test");
        
        vm.prank(validator1);
        treasury.vote(0, true);
        
        vm.prank(validator2);
        treasury.vote(0, true);
        
        (, , , uint256 votesFor, uint256 votesAgainst, , , ) = treasury.getProposal(0);
        assertEq(votesFor, 2);
        assertEq(votesAgainst, 0);
    }

    function test_ExecuteDistribution() public {
        vm.prank(validator1);
        treasury.proposeDistribution(recipient, 100 * 10 ** 18, "Test");
        
        // All validators vote yes
        vm.prank(validator1);
        treasury.vote(0, true);
        vm.prank(validator2);
        treasury.vote(0, true);
        vm.prank(validator3);
        treasury.vote(0, true);
        
        // Fast forward past voting period
        vm.warp(block.timestamp + 4 days);
        
        treasury.executeDistribution(0);
        
        assertEq(token.balanceOf(recipient), 100 * 10 ** 18);
    }

    function test_ExecuteDistribution_RevertNotApproved() public {
        vm.prank(validator1);
        treasury.proposeDistribution(recipient, 100 * 10 ** 18, "Test");
        
        // Majority votes no
        vm.prank(validator1);
        treasury.vote(0, false);
        vm.prank(validator2);
        treasury.vote(0, false);
        
        vm.warp(block.timestamp + 4 days);
        
        vm.expectRevert(PasifikaTreasury.ProposalNotApproved.selector);
        treasury.executeDistribution(0);
    }

    // ============ Security Fix Tests ============

    function test_ExecuteDistribution_RevertInsufficientBalance() public {
        // Create two proposals that together exceed treasury balance
        // Treasury has 1000 tokens initially
        
        vm.prank(validator1);
        treasury.proposeDistribution(recipient, 600 * 10 ** 18, "First distribution");
        
        vm.prank(validator2);
        treasury.proposeDistribution(user1, 600 * 10 ** 18, "Second distribution");
        
        // Vote yes on both proposals
        vm.prank(validator1);
        treasury.vote(0, true);
        vm.prank(validator2);
        treasury.vote(0, true);
        vm.prank(validator3);
        treasury.vote(0, true);
        vm.prank(admin);
        treasury.vote(0, true);
        
        vm.prank(validator1);
        treasury.vote(1, true);
        vm.prank(validator2);
        treasury.vote(1, true);
        vm.prank(validator3);
        treasury.vote(1, true);
        vm.prank(admin);
        treasury.vote(1, true);
        
        vm.warp(block.timestamp + 4 days);
        
        // Execute first proposal - treasury now has 400 tokens
        treasury.executeDistribution(0);
        assertEq(token.balanceOf(recipient), 600 * 10 ** 18);
        
        // Second proposal should revert due to insufficient balance (needs 600, has 400)
        vm.expectRevert(PasifikaTreasury.InsufficientTreasuryBalance.selector);
        treasury.executeDistribution(1);
    }

    function test_QuorumUsesValidatorCountAtCreation() public {
        // Create proposal with 4 validators
        vm.prank(validator1);
        treasury.proposeDistribution(recipient, 100 * 10 ** 18, "Test");
        
        // Get 3 votes (75% of 4 validators = passes 51% quorum)
        vm.prank(validator1);
        treasury.vote(0, true);
        vm.prank(validator2);
        treasury.vote(0, true);
        vm.prank(validator3);
        treasury.vote(0, true);
        
        // Remove validators after voting (shouldn't affect quorum)
        vm.prank(admin);
        treasury.removeValidator(validator3);
        
        vm.warp(block.timestamp + 4 days);
        
        // Should still execute because quorum uses count at creation (4)
        treasury.executeDistribution(0);
        assertEq(token.balanceOf(recipient), 100 * 10 ** 18);
    }

    function test_IsValidator() public view {
        assertTrue(treasury.isValidator(validator1));
        assertTrue(treasury.isValidator(admin));
        assertFalse(treasury.isValidator(recipient));
    }

    function test_GetValidatorCount() public view {
        // admin + 3 validators = 4
        assertEq(treasury.getValidatorCount(), 4);
    }
}
