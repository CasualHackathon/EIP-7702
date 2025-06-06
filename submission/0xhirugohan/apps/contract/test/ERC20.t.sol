// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { MYToken } from "../src/ERC20.sol";

contract ERC20Test is Test {
    MYToken public myToken;
    uint256 public immutable maxSupply = 1_000_000;
    address public immutable deployer = makeAddr("deployer");
    address public immutable alice = makeAddr("alice");

    function setUp() public {
        vm.startPrank(deployer);
        myToken = new MYToken(maxSupply);
        vm.stopPrank();
    }

    function test_DeployerShouldMintedMaxSupply() public view {
        vm.assertEq(myToken.balanceOf(deployer), maxSupply);
    }

    // should approve and check allowance
    function test_ShouldApproveAllowance() public {
        uint256 initialAllowed = myToken.allowance(deployer, alice);
        uint256 allowedAmount = 1_000;

        vm.startPrank(deployer);
        myToken.approve(alice, allowedAmount);
        vm.stopPrank();

        vm.assertEq(initialAllowed, 0);
        vm.assertEq(myToken.allowance(deployer, alice), allowedAmount);
    }

    // should transfer
    function test_shouldTransfer() public {
        uint256 aliceInitialBalance = myToken.balanceOf(alice);
        uint256 transferAmount = 1_000;

        vm.startPrank(deployer);
        myToken.transfer(alice, transferAmount);
        vm.stopPrank();

        vm.assertEq(aliceInitialBalance, 0);
        vm.assertEq(myToken.balanceOf(alice), transferAmount);
        vm.assertEq(myToken.balanceOf(deployer), maxSupply - transferAmount);
    }
}