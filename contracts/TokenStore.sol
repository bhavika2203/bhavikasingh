// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./GameToken.sol";

/// @title TokenStore
/// @notice Sells GT for USDT at 1:1 and mints GT to buyers. Owner can withdraw USDT.
contract TokenStore is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdt;
    GameToken public immutable gameToken;

    /// @notice Emitted when a purchase is made
    event Purchased(address indexed buyer, uint256 usdtSpent, uint256 gtMinted);
    /// @notice Emitted on owner withdrawal
    event Withdrawn(address indexed to, uint256 amount);

    constructor(IERC20 usdt_, GameToken gameToken_) Ownable() {
        require(address(usdt_) != address(0), "usdt zero");
        require(address(gameToken_) != address(0), "gt zero");
        usdt = usdt_;
        gameToken = gameToken_;
    }

    /// @notice Buy GT at 1:1 using USDT. Caller must approve USDT first.
    function buy(uint256 usdtAmount) external {
        require(usdtAmount > 0, "zero amount");
        // Pull USDT from buyer
        usdt.safeTransferFrom(msg.sender, address(this), usdtAmount);
        // Mint GT to buyer
        gameToken.mint(msg.sender, usdtAmount);
        emit Purchased(msg.sender, usdtAmount, usdtAmount);
    }

    /// @notice Withdraw accumulated USDT to owner
    function withdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "zero amount");
        usdt.safeTransfer(owner(), amount);
        emit Withdrawn(owner(), amount);
    }
}


