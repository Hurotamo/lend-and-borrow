// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LendBorrow {
    // Constants
    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization
    uint256 public constant LIQUIDATION_THRESHOLD = 110; // 110% liquidation threshold

    // Struct for user accounts
    struct UserAccount {
        uint256 deposits;
        uint256 borrowed;
    }

    // Mapping of user addresses to their account
    mapping(address => UserAccount) public userAccounts;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Liquidate(address indexed liquidator, address indexed user, uint256 amount);

    // Deposit function
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        userAccounts[msg.sender].deposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Borrow function
    function borrow(uint256 amount) external {
        UserAccount storage user = userAccounts[msg.sender];
        require(user.deposits * 100 >= amount * COLLATERAL_RATIO, "Insufficient collateral");

        user.borrowed += amount;
        payable(msg.sender).transfer(amount);

        emit Borrow(msg.sender, amount);
    }

    // Repay function
    function repay() external payable {
        UserAccount storage user = userAccounts[msg.sender];
        require(msg.value > 0, "Repay amount must be greater than zero");
        require(msg.value <= user.borrowed, "Repay amount exceeds borrowed amount");

        user.borrowed -= msg.value;
        emit Repay(msg.sender, msg.value);
    }

    // Withdraw function
    function withdraw(uint256 amount) external {
        UserAccount storage user = userAccounts[msg.sender];
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(user.deposits >= amount, "Insufficient deposits");
        require(
            (user.deposits - amount) * 100 >= user.borrowed * COLLATERAL_RATIO,
            "Withdrawal would exceed collateral ratio"
        );

        user.deposits -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    // Liquidate function
    function liquidate(address userAddress) external {
        UserAccount storage user = userAccounts[userAddress];
        require(user.borrowed > 0, "User has no borrowed amount");
        require(
            user.deposits * 100 < user.borrowed * LIQUIDATION_THRESHOLD,
            "User is not eligible for liquidation"
        );

        uint256 liquidationAmount = user.borrowed;
        user.deposits -= liquidationAmount;
        user.borrowed = 0;

        payable(msg.sender).transfer(liquidationAmount);

        emit Liquidate(msg.sender, userAddress, liquidationAmount);
    }

    // View function to check user account details
    function getUserAccount(address userAddress) external view returns (uint256 deposits, uint256 borrowed) {
        UserAccount memory user = userAccounts[userAddress];
        return (user.deposits, user.borrowed);
    }
}
