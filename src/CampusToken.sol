// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";


contract CampusToken is ERC20, AccessControl{
  // Role
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // owner/admin address
  address public owner;
  uint256 public constant initSupply = 10_000_000;
  uint256 public constant maxSupply = 100_000_000;

  // Error types
  error ERC20MaxSupplyReached(address sender, address receiver, uint256 amount);

  constructor() ERC20("Vibe Campus Token", "VIBT") {
    owner = msg.sender;
    _mint(msg.sender, initSupply);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function _update(address from, address to, uint256 value) internal override {
    // Minting
    if (from == address(0) && (totalSupply() + value > maxSupply)) {
        revert ERC20MaxSupplyReached(from, to, value);
    }

    super._update(from, to, value);
  }

  function mintVibeToken(address receiver, uint256 amount) external onlyRole(MINTER_ROLE){
    _mint(receiver, amount);
  }

  function grantNamedRole(address account, string memory roleName) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(keccak256(bytes(roleName)), account);
  }
}