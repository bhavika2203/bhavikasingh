# PvP Match Staking System on Ethereum

This project implements a blockchain-based PvP (player vs player) match staking system built with Solidity and Hardhat. 
It includes ERC20 tokens for staking and a secure game match contract that manages staking, joining, and payout logic with an API Gateway controlled result submission.

1.Project Structure
/contracts
├─ GameToken.sol # ERC20 token (GT), minting controlled by TokenStore
├─ TokenStore.sol # Allows users to buy GT using USDT at 1:1 rate
├─ PlayGame.sol # PvP match staking and result payout contract
└─ MockUSDT.sol # Mock USDT token for local testing
/scripts
└─ deploy.js # Deployment script for all contracts
/test
├─ GameToken.test.js
├─ TokenStore.test.js
└─ PlayGame.test.js
hardhat.config.js # Hardhat configuration
package.json # Project dependencies and scripts

2.Features
- **GameToken (GT)**: ERC20 token mintable only by the TokenStore contract.
- **TokenStore**: Users buy GT tokens using USDT at a fixed 1:1 rate.
- **PlayGame**: Players create and join PvP matches by staking GT tokens.
- **Result submission** is restricted to a trusted API Gateway.
- **Automatic payout** to the winner with full escrow amount.
- Owner emergency cancellation for open matches.
- Events emitted for all major state changes.
- Gas-efficient and production-ready Solidity code.
- Unit tests cover all contracts with Hardhat, ethers.js, and chai.

3. Getting Started
Prerequisites
- Node.js v16 or higher  
- npm  
- Git
  
4.Installation

1. Clone the repository or create a new project folder and add the contract files.
2. Install dependencies:``bash
npm install
`
Compilation:
npx hardhat compile

Deployment
The deployment script (/scripts/deploy.js) deploys all contracts, sets the TokenStore address in the GameToken, and sets the API Gateway address in PlayGame.
To deploy on a local Hardhat node or a testnet:
bash: npx hardhat node



deploy :npx hardhat run scripts/deploy.js --network localhost

Usage Overview
Buying GT tokens:
Users approve USDT spending for TokenStore and buy GT tokens at a fixed 1:1 rate.
Creating a match:
Player stakes GT tokens and creates a match.
Joining a match:
Another player joins by staking the same GT amount.
Submitting result:
A trusted API Gateway submits the match result and declares the winner.
Payout:
Winner automatically receives the total staked amount from both players.


Security Considerations
The API Gateway is fully trusted to submit accurate match results. In production, consider decentralized or multi-sig oracles.
Emergency cancel function is only callable by owner for refunding open matches.
Tokens and contracts assume standard 18 decimals for simplicity. Adjust if needed.
Use SafeERC20 and ReentrancyGuard for additional security if integrating with external tokens

