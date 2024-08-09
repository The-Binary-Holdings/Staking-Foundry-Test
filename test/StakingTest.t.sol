// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/Staking.sol";

contract StakingTest is Test {
    Staking private staking;
    address private user1;
    address private user2;

    function setUp() public {
        staking = new Staking();
        user1 = vm.addr(1);
        user2 = vm.addr(2);
    }

    function testInitialValues() public {
        assertEq(staking.getTotalBalance(), 0);
        assertEq(staking.getTotalNumberStakers(), 0);
        assertEq(staking.getStaked(user1), 0);
    }

    function testStake() public {
        vm.deal(user1, 1 ether);

        vm.prank(user1);
        staking.stake{value: 1 ether}();

        assertEq(staking.getTotalBalance(), 1 ether);
        assertEq(staking.getTotalNumberStakers(), 1);
        assertEq(staking.getStaked(user1), 1 ether);
    }

    function testStakeMoreThanZero() public {
        vm.expectRevert(NeedsMoreThanZero.selector);

        vm.prank(user1);
        staking.stake{value: 0}();
    }

    function testWithdraw() public {
        vm.deal(user1, 1 ether);

        vm.prank(user1);
        staking.stake{value: 1 ether}();

        vm.prank(user1);
        staking.withdraw(0.5 ether);

        assertEq(staking.getTotalBalance(), 0.5 ether);
        assertEq(staking.getTotalNumberStakers(), 1);
        assertEq(staking.getStaked(user1), 0.5 ether);
    }

    function testWithdrawInsufficientBalance() public {
        vm.deal(user1, 1 ether);

        vm.prank(user1);
        staking.stake{value: 1 ether}();

        vm.expectRevert(NeedsMoreThanZero.selector);

        vm.prank(user1);
        staking.withdraw(2 ether);
    }

    function testWithdrawAll() public {
        vm.deal(user1, 1 ether);

        vm.prank(user1);
        staking.stake{value: 1 ether}();

        vm.prank(user1);
        staking.withdraw(1 ether);

        assertEq(staking.getTotalBalance(), 0);
        assertEq(staking.getTotalNumberStakers(), 0);
        assertEq(staking.getStaked(user1), 0);
    }

    function testMultipleStakers() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);

        vm.prank(user1);
        staking.stake{value: 1 ether}();

        vm.prank(user2);
        staking.stake{value: 2 ether}();

        assertEq(staking.getTotalBalance(), 3 ether);
        assertEq(staking.getTotalNumberStakers(), 2);
        assertEq(staking.getStaked(user1), 1 ether);
        assertEq(staking.getStaked(user2), 2 ether);
    }

    function testWithdrawFailsIfTransferFails() public {
        vm.deal(user1, 1 ether);

        vm.prank(user1);
        staking.stake{value: 1 ether}();
        console.log("After staking, user1 balance:", address(user1).balance);
        console.log("After staking, staking contract balance:", address(staking).balance);

        vm.prank(address(staking));
        (bool sent, ) = user1.call{value: 1 ether}("");
        require(sent, "Failed to send Ether");
        console.log("After sending Ether directly to user1, user1 balance:", address(user1).balance);
        console.log("After sending Ether directly to user1, staking contract balance:", address(staking).balance);

        vm.expectRevert(TransferFailed.selector);

        vm.prank(user1);
        staking.withdraw(1 ether);
        console.log("After attempting to withdraw, user1 balance:", address(user1).balance);
        console.log("After attempting to withdraw, staking contract balance:", address(staking).balance);
    }
}
