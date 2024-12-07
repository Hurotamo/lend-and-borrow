# lend-and-borrow
sample smart contract for lend and borrow solidity 


This Solidity contract implements a **Lending and Borrowing System** with collateral requirements and liquidation rules. Here's a breakdown of the contract's functionality and structure:

---

### **1. Constants**

```solidity
uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization
uint256 public constant LIQUIDATION_THRESHOLD = 110; // 110% liquidation threshold
```

- **COLLATERAL_RATIO (150%)**: Users must have collateral worth at least 150% of the borrowed amount.
- **LIQUIDATION_THRESHOLD (110%)**: If the collateral falls below 110% of the borrowed amount, their position becomes eligible for liquidation.

---

### **2. Struct for User Accounts**

```solidity
struct UserAccount {
    uint256 deposits;
    uint256 borrowed;
}
```

- **deposits**: Tracks how much a user has deposited as collateral.
- **borrowed**: Tracks how much a user has borrowed.

---

### **3. State Variables**

```solidity
mapping(address => UserAccount) public userAccounts;
```

- Maps each user's Ethereum address to their **UserAccount**, storing deposit and loan data.

---

### **4. Events**

```solidity
event Deposit(address indexed user, uint256 amount);
event Borrow(address indexed user, uint256 amount);
event Repay(address indexed user, uint256 amount);
event Withdraw(address indexed user, uint256 amount);
event Liquidate(address indexed liquidator, address indexed user, uint256 amount);
```

- **Events** are emitted during state changes (e.g., when depositing, borrowing, repaying, etc.), allowing dApps and blockchain explorers to track contract activities.

---

### **5. Deposit Function**

```solidity
function deposit() external payable {
    require(msg.value > 0, "Deposit amount must be greater than zero");
    userAccounts[msg.sender].deposits += msg.value;
    emit Deposit(msg.sender, msg.value);
}
```

- Allows users to deposit Ether as collateral.
- **Key checks**:
  - Deposit must be greater than zero.
- Updates the user's deposit balance and emits a `Deposit` event.

---

### **6. Borrow Function**

```solidity
function borrow(uint256 amount) external {
    UserAccount storage user = userAccounts[msg.sender];
    require(user.deposits * 100 >= amount * COLLATERAL_RATIO, "Insufficient collateral");

    user.borrowed += amount;
    payable(msg.sender).transfer(amount);

    emit Borrow(msg.sender, amount);
}
```

- Allows users to borrow Ether based on their collateral.
- **Key checks**:
  - Borrowed amount must be within the collateral limit (`deposits × 100 ≥ borrowed × COLLATERAL_RATIO`).
- Updates the borrowed balance and sends Ether to the user, emitting a `Borrow` event.

---

### **7. Repay Function**

```solidity
function repay() external payable {
    UserAccount storage user = userAccounts[msg.sender];
    require(msg.value > 0, "Repay amount must be greater than zero");
    require(msg.value <= user.borrowed, "Repay amount exceeds borrowed amount");

    user.borrowed -= msg.value;
    emit Repay(msg.sender, msg.value);
}
```

- Allows users to repay their loans.
- **Key checks**:
  - Repay amount must be greater than zero and less than or equal to the borrowed amount.
- Updates the borrowed balance and emits a `Repay` event.

---

### **8. Withdraw Function**

```solidity
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
```

- Allows users to withdraw their collateral, ensuring they still meet collateralization requirements.
- **Key checks**:
  - Withdrawal must not leave insufficient collateral (`(deposits - amount) × 100 ≥ borrowed × COLLATERAL_RATIO`).

---

### **9. Liquidate Function**

```solidity
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
```

- Allows anyone to liquidate a user if their collateral falls below the liquidation threshold.
- **Key checks**:
  - User must have borrowed funds.
  - Collateral must be below the liquidation threshold.
- Liquidator receives the user's collateral equal to the borrowed amount, and the user’s loan is cleared.

---

### **10. View Function**

```solidity
function getUserAccount(address userAddress) external view returns (uint256 deposits, uint256 borrowed) {
    UserAccount memory user = userAccounts[userAddress];
    return (user.deposits, user.borrowed);
}
```

- Fetches the deposit and borrowed balances for any user.

---

### **Key Features**
1. **Collateralization**: Ensures borrowed amounts are backed by sufficient collateral.
2. **Liquidation**: Protects the contract from bad debts when collateral becomes insufficient.
3. **Event Logging**: Facilitates tracking of all actions (deposit, borrow, etc.).
4. **User Accounts**: Each user has an independent account for deposits and loans.

