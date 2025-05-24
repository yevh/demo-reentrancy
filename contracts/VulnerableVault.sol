// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title VulnerableVault (for demo only)
/// @notice Intentionally unsafe ETH vault that can be drained via re-entrancy.
contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        require(msg.value > 0, "Zero value");
        balances[msg.sender] += msg.value;
    }

    /// @notice Withdraw amount - UNSAFE: external call before storage update
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Send funds before updating storage (vulnerable!)
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");

        // Update storage after interaction (enables reentrancy)
        unchecked {
            balances[msg.sender] -= amount;
        }
    }

    receive() external payable {
        deposit();
    }
}