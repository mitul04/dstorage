// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {
    constructor() ERC20("StorageToken", "STOR") Ownable(msg.sender) {
        // Initial supply minted to deployer (owner account)
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /// @notice Mint new tokens as rewards for storage nodes
    function mintReward(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        _mint(to, amount);
    }
}
