// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GameToken (GT)
/// @notice ERC20 token minted exclusively by TokenStore. Owner can update TokenStore address.
contract GameToken is ERC20, Ownable {
    /// @notice Address of the TokenStore that is allowed to mint
    address public tokenStore;

    /// @notice Emitted when TokenStore address is updated
    event TokenStoreUpdated(address indexed previousStore, address indexed newStore);

    /// @notice Emitted when tokens are minted by the TokenStore
    event StoreMint(address indexed to, uint256 amount);

    constructor() ERC20("GameToken", "GT") Ownable() {}

    /// @notice Set the TokenStore address. Only owner.
    function setTokenStore(address newStore) external onlyOwner {
        require(newStore != address(0), "Invalid store");
        address previous = tokenStore;
        tokenStore = newStore;
        emit TokenStoreUpdated(previous, newStore);
    }

    /// @notice Mint tokens to `to`. Callable only by TokenStore.
    function mint(address to, uint256 amount) external {
        require(msg.sender == tokenStore, "Not store");
        require(to != address(0), "Zero to");
        require(amount > 0, "Zero amount");
        _mint(to, amount);
        emit StoreMint(to, amount);
    }
}


