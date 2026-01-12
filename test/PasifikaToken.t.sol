// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PasifikaToken.sol";

contract PasifikaTokenTest is Test {
    PasifikaToken public token;
    
    address public admin = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public validator = address(4);
    
    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10 ** 18;

    event RemittanceSent(
        address indexed from,
        address indexed to,
        uint256 amount,
        string corridor,
        uint256 timestamp
    );

    event ValidatorAdded(address indexed validator, string organization);
    event ValidatorRemoved(address indexed validator);

    function setUp() public {
        vm.prank(admin);
        token = new PasifikaToken(admin, INITIAL_SUPPLY);
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
        vm.expectRevert("Initial supply exceeds max supply");
        new PasifikaToken(admin, exceedingSupply);
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

    function test_SendRemittance() public {
        uint256 amount = 500 * 10 ** 18;
        string memory corridor = "US-TONGA";
        
        vm.prank(admin);
        token.transfer(user1, amount);
        
        vm.expectEmit(true, true, false, true);
        emit RemittanceSent(user1, user2, amount, corridor, block.timestamp);
        
        vm.prank(user1);
        token.sendRemittance(user2, amount, corridor);
        
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.balanceOf(user1), 0);
    }

    function test_SendRemittance_RevertZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("Cannot send to zero address");
        token.sendRemittance(address(0), 100, "US-TONGA");
    }

    function test_SendRemittance_RevertZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert("Amount must be greater than zero");
        token.sendRemittance(user1, 0, "US-TONGA");
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
        vm.expectRevert("Arrays length mismatch");
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
        vm.expectRevert("Would exceed max supply");
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
        
        vm.prank(user1);
        token.sendRemittance(user2, amount, corridor);
        
        assertEq(token.balanceOf(user2), amount);
    }
}
