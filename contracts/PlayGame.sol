// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title PlayGame - PvP match staking with GT token
/// @notice Players stake GT into escrow; an API gateway submits the result and the winner receives both stakes.
contract PlayGame is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum MatchStatus { Open, Joined, Resolved, Cancelled }

    struct MatchInfo {
        address player1;
        address player2;
        uint256 stakeAmount; // per-player stake
        MatchStatus status;
    }

    IERC20 public immutable gameToken; // GT token
    address public immutable apiGateway; // trusted result submitter

    mapping(uint256 => MatchInfo) public matches; // matchId => info

    /// @notice Emitted when a new match is created by player1
    event MatchCreated(uint256 indexed matchId, address indexed player1, uint256 stakeAmount);
    /// @notice Emitted when player2 joins a match
    event MatchJoined(uint256 indexed matchId, address indexed player2);
    /// @notice Emitted when a match is resolved and payout is made
    event MatchResolved(uint256 indexed matchId, address indexed winner, uint256 payoutAmount);
    /// @notice Emitted when a match is cancelled by owner and stake returned
    event MatchCancelled(uint256 indexed matchId);

    modifier onlyApiGateway() {
        require(msg.sender == apiGateway, "not gateway");
        _;
    }

    constructor(IERC20 gameToken_, address apiGateway_) Ownable() {
        require(address(gameToken_) != address(0), "gt zero");
        require(apiGateway_ != address(0), "gw zero");
        gameToken = gameToken_;
        apiGateway = apiGateway_;
    }

    /// @notice Player1 creates a match by staking GT. Requires prior approval.
    function createMatch(uint256 matchId, uint256 stakeAmount) external nonReentrant {
        require(matchId != 0, "id zero");
        require(stakeAmount > 0, "stake zero");
        MatchInfo storage info = matches[matchId];
        require(info.status == MatchStatus(0) && info.player1 == address(0), "exists");

        // escrow tokens from player1
        gameToken.safeTransferFrom(msg.sender, address(this), stakeAmount);

        info.player1 = msg.sender;
        info.stakeAmount = stakeAmount;
        info.status = MatchStatus.Open;

        emit MatchCreated(matchId, msg.sender, stakeAmount);
    }

    /// @notice Opponent joins the match by staking the same amount. Requires prior approval.
    function joinMatch(uint256 matchId) external nonReentrant {
        MatchInfo storage info = matches[matchId];
        require(info.player1 != address(0), "no match");
        require(info.status == MatchStatus.Open, "not open");
        require(msg.sender != info.player1, "creator cannot join");
        require(info.player2 == address(0), "already joined");

        // escrow tokens from player2
        gameToken.safeTransferFrom(msg.sender, address(this), info.stakeAmount);

        info.player2 = msg.sender;
        info.status = MatchStatus.Joined;

        emit MatchJoined(matchId, msg.sender);
    }

    /// @notice API gateway submits the winner; pays out both stakes to winner.
    function submitResult(uint256 matchId, address winner) external onlyApiGateway nonReentrant {
        MatchInfo storage info = matches[matchId];
        require(info.status == MatchStatus.Joined, "not joined");
        require(winner == info.player1 || winner == info.player2, "invalid winner");

        info.status = MatchStatus.Resolved;

        uint256 payout = info.stakeAmount * 2;
        gameToken.safeTransfer(winner, payout);

        emit MatchResolved(matchId, winner, payout);
    }

    /// @notice Owner can cancel an open match and refund player1.
    function cancelMatch(uint256 matchId) external onlyOwner nonReentrant {
        MatchInfo storage info = matches[matchId];
        require(info.status == MatchStatus.Open, "cannot cancel");

        info.status = MatchStatus.Cancelled;
        gameToken.safeTransfer(info.player1, info.stakeAmount);

        emit MatchCancelled(matchId);
    }
}


