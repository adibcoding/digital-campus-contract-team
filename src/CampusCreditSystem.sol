// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./CampusToken.sol";

contract CampusCreditSystem {
    CampusToken public token;
    address public owner;

    uint256 public constant VIBE_PER_MONAD = 1000;

    error ZeroAmount();

    event TopUp(address indexed user, uint256 monadAmount, uint256 vibeAmount);

    constructor(address _address) {
        token = CampusToken(_address);
        owner = msg.sender;
    }

    // 🔼 Top up by sending native MONAD token
    function topUpWithMonad() public payable {
        if (msg.value == 0) revert ZeroAmount();

        uint256 vibeAmount = msg.value * VIBE_PER_MONAD / 1 ether;

        // Mint token
        token.mintVibeToken(msg.sender, vibeAmount);

        emit TopUp(msg.sender, msg.value, vibeAmount);
    }

    receive() external payable {
      topUpWithMonad();
    }
}
