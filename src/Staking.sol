// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error TransferFailed();
error NeedsMoreThanZero();

contract Staking is ReentrancyGuard {
    uint256 private s_totalSupply;
    uint256 private s_totalNumberStakers;
    mapping(address => uint256) private s_balances;

    event Staked(address indexed user, uint256 indexed amount);
    event WithdrawStake(address indexed user, uint256 indexed amount);

    /**
     * @notice Deposit tokens into this contract
     */
    function stake() external payable nonReentrant moreThanZero {
        if (s_balances[msg.sender] == 0) {
            s_totalNumberStakers += 1;
        }
        s_totalSupply += msg.value;
        s_balances[msg.sender] += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw tokens from this contract
     * @param amount | How much to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (amount > s_balances[msg.sender]) {
            revert NeedsMoreThanZero(); // or create a new custom error for insufficient balance
        }
        s_totalSupply -= amount;
        s_balances[msg.sender] -= amount;
        if (s_balances[msg.sender] == 0) {
            s_totalNumberStakers -= 1;
        }
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
        emit WithdrawStake(msg.sender, amount);
    }

    modifier moreThanZero() {
        if (msg.value == 0) {
            revert NeedsMoreThanZero();
        }
        _;
    }

    /********************/
    /* Getter Functions */
    /********************/
    function getStaked(address account) external view returns (uint256) {
        return s_balances[account];
    }

    function getTotalBalance() external view returns (uint256) {
        return s_totalSupply;
    }

    function getTotalNumberStakers() external view returns (uint256) {
        return s_totalNumberStakers;
    }
}