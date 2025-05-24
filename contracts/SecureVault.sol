// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SecureVault
/// @notice Hardened ETH vault that resists re-entrancy attacks.
contract SecureVault is ReentrancyGuard {
    mapping(address => uint256) private _balances;

    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice Accept ETH and credit sender balance.
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Zero value");
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw exactly `amount` wei.
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero amount");
        uint256 current = _balances[msg.sender];
        require(current >= amount, "Insufficient balance");

        // Update storage before external call
        unchecked {
            _balances[msg.sender] = current - amount;
        }

        // Transfer ETH
        (bool ok, bytes memory reason) = msg.sender.call{value: amount}("");
        if (!ok) {
            _balances[msg.sender] = current; // restore state
            assembly {
                revert(add(reason, 32), mload(reason))
            }
        }

        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Withdraw caller's entire balance.
    function withdrawAll() external nonReentrant {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        _balances[msg.sender] = 0;
        (bool ok, bytes memory reason) = msg.sender.call{value: amount}("");
        if (!ok) {
            _balances[msg.sender] = amount; // restore state
            assembly {
                revert(add(reason, 32), mload(reason))
            }
        }

        emit Withdrawal(msg.sender, amount);
    }

    receive() external payable {
        _receive(msg.sender);
    }

    fallback() external payable {
        _receive(msg.sender);
    }

    function _receive(address from) private {
        _balances[from] += msg.value;
        emit Deposit(from, msg.value);
    }
}