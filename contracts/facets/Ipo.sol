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

    function deposit(
        uint256 _id,
        uint256 _amount
    ) 
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        uint256 gameId = _id;
        uint256 amount = _amount;
        uint256 blockTime = block.timestamp;
        address user = msg.sender;

        LibGame.Layout storage gs = LibGame.layout();

        if(!gs.game[gameId].isExist){ revert Invalid_Action(); }
        if(!gs.game[gameId].isIPO){ revert Invalid_Action(); }
        if(gs.gameUser[user][gameId][gs.game[gameId].round].isInvestmentor) { revert User_Not_Expired(); }
        if(!gs.gameUser[user][gameId][gs.game[gameId].round].isRegister) { revert Unregistered_Member(); }

        if(amount < gs.game[gameId].minInvestment) { revert Invalid_Price(); }
        if(amount > gs.game[gameId].maxInvestment) { revert Invalid_Price(); }

        if(gs.game[gameId].collectedInvestment == gs.game[gameId].toBeCollectedInvestment){ revert Sale_End(); }
        uint256 remainingTokenAmount = 0;
        unchecked {
            remainingTokenAmount = gs.game[gameId].toBeCollectedInvestment - gs.game[gameId].collectedInvestment;
        }
        if(amount > remainingTokenAmount){ revert Overflow_0x11(); }

        (uint256 allocation) = calculateAllocation(_id, user);
        if(allocation == 0){ revert User_Not_Expired(); }
        if(_amount > allocation){ revert Invalid_Price(); }

        if(blockTime < gs.game[gameId].guaranteedInvestmentStart) { revert Wait_For_Deposit_Times(); }
        if(blockTime > gs.game[gameId].guaranteedInvestmentEnd) { revert Wait_For_Deposit_Round(); }

        _deposit(gameId,amount,user);
    }

    function _deposit(
        uint256 _id,
        uint256 _amount,
        address _user
    )
        private 
    {
        LibGame.Layout storage gs = LibGame.layout();
        ISolidStateERC20 token = ISolidStateERC20(gs.usedTokenAddress);

        gs.gameUser[_user][_id][gs.game[_id].round].isInvestmentor = true;

        unchecked {
            gs.game[_id].userCount++;
            gs.game[_id].collectedInvestment += _amount;
            gs.gameUser[_user][_id][gs.game[_id].round].investAmount += _amount;
        }

        uint256 multipler = calculateMultipler(_id,_amount);
        if(multipler == 0) { revert Overflow_0x11(); }
        if(token.balanceOf(_user) < _amount){ revert Insufficient_Balance(); }
        if(token.allowance(_user, address(this)) < _amount){ revert Insufficient_Allowance(); }
        token.transferFrom(_user, gs.reserveContractAddress, _amount);
        IERC721Game(gs.game[_id].nftContract).safeMint(multipler,_user);

        emit HANDLE_DEPOSIT_IPO(_user,multipler,block.timestamp);
    }

    function register(
        uint256 _id
    )
        external 
        nonReentrant 
        whenNotContract(msg.sender) 
    {
        uint256 gameId = _id;
        uint256 blockTime = block.timestamp;
        address user = msg.sender;

        LibGame.Layout storage gs = LibGame.layout();

        if(!gs.game[gameId].isExist){ revert Invalid_Action(); }
        if(!gs.game[gameId].isIPO){ revert Invalid_Action(); }
        if(gs.gameUser[user][gameId][gs.game[gameId].round].isRegister) { revert User_Already_Registered(); }
        uint256 stakeScore = LibStake.layout().user[user].userTotalScore;
        if(stakeScore == 0){revert User_Not_Stake();}
        if(blockTime < gs.game[gameId].registerStart) { revert Not_Started_Registration(); }
        if(blockTime > gs.game[gameId].registerEnd) { revert End_Registration(); }

        gs.gameUser[user][gameId][gs.game[gameId].round].isRegister = true;

        unchecked {
            gs.game[gameId].roundScore += stakeScore;
            gs.gameUser[user][gameId][gs.game[gameId].round].userRoundScore += stakeScore;
        }

        emit HANDLE_REGISTER_IPO(user,gameId,blockTime);
    }

    function calculateMultipler(
        uint256 _id,
        uint256 _amount
    ) 
        public 
        view 
        returns (uint256 mul) 
    {
        uint256 sharePrice =  LibGame.layout().game[_id].perSharePrice;
        if(_amount >= sharePrice){
            uint256 decimals = (10 ** ISolidStateERC20(LibGame.layout().usedTokenAddress).decimals());
            mul = _amount.mulDiv(sharePrice,decimals);
        }
    }

    function calculateAllocation(
        uint256 _id,
        address _user
    ) 
        public 
        view 
        returns (uint256 allocation) 
    {
        LibGame.Layout storage gs = LibGame.layout();
        uint256 blockTime = block.timestamp;
        if(
            blockTime > gs.game[_id].guaranteedInvestmentStart && 
            blockTime < gs.game[_id].guaranteedInvestmentEnd &&
            !gs.gameUser[_user][_id][gs.game[_id].round].isInvestmentor && 
            gs.gameUser[_user][_id][gs.game[_id].round].userRoundScore > 0)
        {
            uint256 decimals = (10 ** ISolidStateERC20(gs.usedTokenAddress).decimals());
            uint256 weight = gs.gameUser[_user][_id][gs.game[_id].round].userRoundScore.mulDiv(1 ether,gs.game[_id].roundScore);
            uint256 allocationTokenAmount = weight.mulDiv(gs.game[_id].toBeCollectedInvestment,decimals);
            allocation = allocationTokenAmount.mulDiv(gs.game[_id].perSharePrice,1 ether);
        }
    }

}