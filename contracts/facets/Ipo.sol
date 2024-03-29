// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC721Game } from "../interfaces/IERC721Game.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { LibGame } from "../libraries/LibGame.sol";
import "../libraries/Errors.sol";

contract Ipo is Modifiers, ReentrancyGuard{
    using Math for uint256;

    // Attention, this product is in the testing phase.

    event HANDLE_DEPOSIT_IPO(address indexed from,uint256 multipler,uint256 time);
    event HANDLE_REGISTER_IPO(address indexed from,uint256 ipoId,uint256 time);
    event HANDLE_STAKE_IPO(address indexed from,uint256 ipoId,uint256 tokenId,uint256 time);
    event HANDLE_UNSTAKE_IPO(address indexed from,uint256 ipoId,uint256 time);
    event HANDLE_CLAIM_IPO(address indexed from,uint256 ipoId,uint256 time);

    function deposit(
        uint256 _id,
        uint256 _round,
        uint256 _amount
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        uint256 gameId = _id;
        uint256 round = _round;
        uint256 amount = _amount;
        uint256 blockTime = block.timestamp;
        address user = msg.sender;

        LibGame.Layout storage gs = LibGame.layout();

        if(!gs.game[gameId].isExist){ revert Invalid_Action(); }
        if(!gs.game[gameId].isIPO){ revert Invalid_Action(); }
        if(!gs.gameIpo[gameId][round].isExist){ revert Invalid_Input(); }
        if(gs.userIpo[user][gameId][round].isInvestmentor) { revert User_Not_Expired(); }
        if(!gs.userIpo[user][gameId][round].isRegister) { revert Unregistered_Member(); }

        if(amount < gs.gameIpo[gameId][round].minInvestment) { revert Invalid_Price(); }
        if(amount > gs.gameIpo[gameId][round].maxInvestment) { revert Invalid_Price(); }

        if(gs.gameIpo[gameId][round].collectedInvestment == gs.gameIpo[gameId][round].toBeCollectedInvestment){ revert Sale_End(); }
        uint256 remainingTokenAmount = 0;
        unchecked {
            remainingTokenAmount = gs.gameIpo[gameId][round].toBeCollectedInvestment - gs.gameIpo[gameId][round].collectedInvestment;
        }
        if(amount > remainingTokenAmount){ revert Overflow_0x11(); }

        (uint256 allocation) = calculateAllocation(_id,round, user);
        if(allocation == 0){ revert User_Not_Expired(); }
        if(_amount > allocation){ revert Invalid_Price(); }

        if(blockTime < gs.gameIpo[gameId][round].guaranteedInvestmentStart) { revert Wait_For_Deposit_Times(); }
        if(blockTime > gs.gameIpo[gameId][round].guaranteedInvestmentEnd) { revert Wait_For_Deposit_Round(); }

        _deposit(gameId,round,amount,user);
    }

    function _deposit(
        uint256 _id,
        uint256 _round,
        uint256 _amount,
        address _user
    )
        private 
    {
        LibGame.Layout storage gs = LibGame.layout();
        ISolidStateERC20 token = ISolidStateERC20(gs.usedTokenAddress);

        gs.userIpo[_user][_id][_round].isInvestmentor = true;

        unchecked {
            gs.gameIpo[_id][_round].roundUserCount++;
            gs.gameIpo[_id][_round].collectedInvestment += _amount;
        }

        uint256 multipler = calculateMultipler(_id,_round,_amount);
        if(multipler == 0) { revert Overflow_0x11(); }
        if(token.balanceOf(_user) < _amount){ revert Insufficient_Balance(); }
        if(token.allowance(_user, address(this)) < _amount){ revert Insufficient_Allowance(); }
        token.transferFrom(_user, gs.reserveContractAddress, _amount);
        IERC721Game(gs.game[_id].nftContract).safeMint(multipler,_user);

        emit HANDLE_DEPOSIT_IPO(_user,multipler,block.timestamp);
    }

    function register(
        uint256 _id,
        uint256 _round
    )
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        uint256 gameId = _id;
        uint256 round = _round;
        uint256 blockTime = block.timestamp;
        address user = msg.sender;

        LibGame.Layout storage gs = LibGame.layout();

        if(!gs.game[gameId].isExist){ revert Invalid_Action(); }
        if(!gs.game[gameId].isIPO){ revert Invalid_Action(); }
        if(gs.userIpo[user][gameId][round].isRegister) { revert User_Already_Registered(); }
        if(blockTime < gs.gameIpo[gameId][round].registerStart) { revert Not_Started_Registration(); }
        if(blockTime > gs.gameIpo[gameId][round].registerEnd) { revert End_Registration(); }
        uint256 stakeScore = LibStake.layout().user[user].userTotalScore;
        if(stakeScore == 0){revert User_Not_Stake();}
        gs.userIpo[user][gameId][round].isRegister = true;

        unchecked {
            gs.gameIpo[gameId][round].roundScore += stakeScore;
            gs.userIpo[user][gameId][round].userRoundScore += stakeScore;
        }

        emit HANDLE_REGISTER_IPO(user,gameId,blockTime);
    }

    function calculateMultipler(
        uint256 _id,
        uint256 _round,
        uint256 _amount
    ) 
        public 
        view 
        returns (uint256 mul) 
    {
        uint256 sharePrice =  LibGame.layout().gameIpo[_id][_round].perSharePrice;
        if(_amount >= sharePrice) {
            uint256 decimals = (10 ** ISolidStateERC20(LibGame.layout().usedTokenAddress).decimals());
            mul = _amount.mulDiv(sharePrice,decimals);
        }
    }

    function calculateAllocation(
        uint256 _id,
        uint256 _round,
        address _user
    ) 
        public 
        view 
        returns (uint256 allocation) 
    {
        LibGame.Layout storage gs = LibGame.layout();
        uint256 blockTime = block.timestamp;
        if(
            blockTime > gs.gameIpo[_id][_round].guaranteedInvestmentStart && 
            blockTime < gs.gameIpo[_id][_round].guaranteedInvestmentEnd &&
            !gs.userIpo[_user][_id][_round].isInvestmentor && 
            gs.userIpo[_user][_id][_round].userRoundScore > 0)
        {
            uint256 decimals = (10 ** ISolidStateERC20(gs.usedTokenAddress).decimals());
            uint256 weight = gs.userIpo[_user][_id][_round].userRoundScore.mulDiv(1 ether,gs.gameIpo[_id][_round].roundScore);
            uint256 allocationTokenAmount = weight.mulDiv(gs.gameIpo[_id][_round].toBeCollectedInvestment,decimals);
            allocation = allocationTokenAmount.mulDiv(gs.gameIpo[_id][_round].perSharePrice,1 ether);
        }
    }

    function claimInvestmentShare(
        uint256 _id,
        uint256 _round,
        uint256 _tokenId
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        uint256 gameId = _id;
        uint256 round = _round;
        uint256 tokenId = _tokenId;
        address user = msg.sender;
        LibGame.Layout storage gs = LibGame.layout();

        IERC721Game nft = IERC721Game(gs.game[gameId].nftContract);
        if(user != nft.ownerOf(tokenId)) { revert Insufficient_Balance(); }
        if(!nft.isApprovedForAll(user,address(this))) { revert Insufficient_Allowance(); }

        uint256 claimableAmount = calculateInvestmentShare(gameId,round,tokenId);
        if(claimableAmount == 0) { revert Overflow_0x11(); }
        nft.setNFTClaimed(tokenId);
        nft.burn(tokenId);
        ISolidStateERC20(gs.usedTokenAddress).transfer(user,claimableAmount);

        emit HANDLE_CLAIM_IPO(user,gameId,block.timestamp);
    }

    function calculateInvestmentShare(
        uint256 _id,
        uint256 _round,
        uint256 _tokenId
    ) 
        public 
        view 
        returns (uint256) 
    {
        uint256 gameId = _id;
        uint256 round = _round;
        uint256 tokenId = _tokenId;
        uint256 investmentShare = 0;

        LibGame.Layout storage gs = LibGame.layout();
        IERC721Game nft = IERC721Game(gs.game[gameId].nftContract);

        uint256 nftMultipler = nft.getMultipler(tokenId);
        if(nftMultipler == 0) { return investmentShare; }
        if(nft.getNFTClaimed(tokenId)) { return investmentShare; }
        if(gs.gameIpo[gameId][round].dividendValue == 0) { return investmentShare; }
        investmentShare = (nftMultipler * gs.gameIpo[gameId][round].dividendValue) / gs.gameIpo[gameId][round].roundScore;
        return investmentShare;
    }

}