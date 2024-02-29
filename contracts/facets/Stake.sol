// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TStakePoolInfo, TStakeTierSection, TUser } from "../libraries/Structs.sol";
import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { Modifiers } from "../libraries/Modifiers.sol";
import { LibStake } from "../libraries/LibStake.sol";
import "../libraries/Errors.sol";

contract Stake is Modifiers, ReentrancyGuard, OwnableInternal{
    using Math for uint256;

    // Attention, this product is in the testing phase.

    uint256 constant MINUTE_IN_SECONDS       = 60;
    uint256 constant FIVE_MINUTES            = 300;
    uint256 constant FIFTEEN_MINUTES         = 900;
    uint256 constant HOUR_IN_SECONDS         = 3600;
    uint256 constant DAY_IN_SECONDS          = 86400;
    uint256 constant SEVEN_DAY_IN_SECONDS    = 604800;
    uint256 constant FIFTEEN_DAYS_IN_SECONDS = 1296000;
    uint256 constant ONE_MONTH_IN_SECONDS    = 2592000;
    uint256 constant YEAR_IN_SECONDS         = 31536000;
    uint256 constant FIVE_YEAR_IN_SECONDS    = 157680000;
    
    // uint256 constant MINIMUM_LOCK_TIME       = 2678400;
    uint256 constant MINIMUM_LOCK_TIME       = 300;
    uint256 constant MAXIMUM_LOCK_TIME       = 155606400;

    uint256 constant DIFFERENCE_AMOUNT       = 1 ether;
    uint256 constant MINIMUM_STAKE_AMOUNT    = 4e22;
    uint256 constant MAXIMUM_STAKE_AMOUNT    = 1e25;

    event HANDLE_STAKE(address indexed, address indexed, uint256);
    event HANDLE_REQUEST(address indexed, address indexed, uint256);
    event HANDLE_UNSTAKE(address indexed, address indexed, uint256);
    event HANDLE_HARVEST(address indexed, address indexed, uint256);
    event FORCED_HARVEST(address indexed, address indexed, uint256);
    event HANDLE_ADD_LIQUIDITY(address indexed,address indexed,uint256);

    function stake(
        uint256 _amount,
        uint256 _lockTime
    ) 
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibStake.Layout storage ss = LibStake.layout();
        ISolidStateERC20 token0 = ISolidStateERC20(ss.stakePoolInfo.token0);
        address user = msg.sender;

        if(!ss.stakePoolInfo.isActive){revert Paused();}
        if(ss.blacklist[user]){revert Address_Is_Blacklist();}
        if(token0.balanceOf(user) < _amount){revert Insufficient_Balance();}
        if(token0.allowance(user, address(this)) < _amount){revert Insufficient_Allowance();}
        if(_lockTime < MINIMUM_LOCK_TIME || _lockTime > MAXIMUM_LOCK_TIME){revert Insufficient_Lock_Time();}
        if(_amount < MINIMUM_STAKE_AMOUNT || _amount > MAXIMUM_STAKE_AMOUNT){revert Insufficient_Stake_Amount();}

        (uint256 score,uint256 multipler) = calculateScore(_amount,_lockTime);
        ss.user[user].userStakeTierCount = ss.user[user].userStakeTierCount + 1;
        uint256 stakeCount = ss.user[user].userStakeTierCount;

        ss.userTierSection[user][stakeCount] = TStakeTierSection({
            receivable    : false,
            indexID       : stakeCount,
            enterTime     : block.timestamp,
            exitTime      : 0,
            stakeAmount   : _amount,
            userScore     : score,
            endTime       : block.timestamp + _lockTime,
            tierMultipler : multipler
        });

        unchecked {
            ss.stakePoolInfo.totalStakedToken += _amount;
            ss.user[user].userTotalStakeAmount += _amount;
            ss.user[user].userTotalScore  += score;
            ss.stakePoolInfo.poolTotalScore += score;
        }
        ss.user[user].userStakeTierSections.push(stakeCount);

        bool userIsStakeBefore = ss.user[user].staker;
        if(!userIsStakeBefore){
            ss.user[user].staker = true;
            unchecked {
                ss.stakePoolInfo.numberOfStakers += 1;
            }
        }
        
        if(userIsStakeBefore){ _safeClaim(user); }

        _updateChc(user);

        token0.transferFrom(user, address(this), _amount);

        emit HANDLE_STAKE(user,address(this),block.timestamp);
    }

    function withdraw(
        uint256 _index
    )
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibStake.Layout storage ss = LibStake.layout();
        address user = msg.sender;

        if(!ss.stakePoolInfo.isActive){revert Paused();}
        if(ss.blacklist[user]){revert Address_Is_Blacklist();}
        if(ss.userTierSection[user][_index].exitTime >= block.timestamp){revert User_Not_Expired();}
        if(!ss.userTierSection[user][_index].receivable){revert User_No_Receivable();}

        uint256 userStakeAmountBefore = ss.userTierSection[user][_index].stakeAmount;
        
        unchecked {
            ss.user[user].userTotalStakeAmount -= userStakeAmountBefore;
        }

        _removeIndexValue(_index,user);

        ISolidStateERC20 token0 = ISolidStateERC20(ss.stakePoolInfo.token0);
        token0.transfer(user,userStakeAmountBefore);
        
        emit HANDLE_UNSTAKE(address(this),msg.sender,block.timestamp);
    }

    function claimRewards(
    )
        external 
        whenNotContract(msg.sender) 
        nonReentrant
    {
        LibStake.Layout storage ss = LibStake.layout();
        if(!ss.stakePoolInfo.isActive){revert Paused();}
        if(ss.blacklist[msg.sender]){revert Address_Is_Blacklist();}
        if(!ss.user[msg.sender].staker){revert Invalid_Action();}

        bool claim = _safeClaim(msg.sender);

        if(claim){
            _updateChc(msg.sender);

            emit HANDLE_HARVEST(msg.sender,address(this),block.timestamp);
        }else{
            revert Invalid_Action();
        }
    }

    function withdrawRequest(
        uint256 _index 
    ) 
        external 
        whenNotContract(msg.sender) 
        nonReentrant 
    {
        LibStake.Layout storage ss = LibStake.layout();
        address user = msg.sender;

        if(!ss.stakePoolInfo.isActive){revert Paused();}
        if(ss.blacklist[user]){revert Address_Is_Blacklist();}
        if(!ss.user[user].staker){revert Invalid_Action();}
        if(ss.userTierSection[user][_index].receivable){revert User_Already_requested();}
        if(ss.userTierSection[user][_index].endTime >= block.timestamp){revert User_Not_Expired();}
        // ss.userTierSection[user][_index].exitTime   = block.timestamp + FIFTEEN_DAYS_IN_SECONDS;
        ss.userTierSection[user][_index].exitTime   = block.timestamp + FIVE_MINUTES;

        ss.userTierSection[user][_index].receivable = true;

        unchecked {
            ss.stakePoolInfo.totalStakedToken -= ss.userTierSection[user][_index].stakeAmount;
            ss.stakePoolInfo.poolTotalScore -= ss.userTierSection[user][_index].userScore;
            ss.user[user].userTotalScore -= ss.userTierSection[user][_index].userScore;
        }

        _safeClaim(user);

        _updateChc(user); 

        if(ss.user[user].userTotalScore == 0){
            ss.user[user].staker = false;
            unchecked {
                ss.stakePoolInfo.numberOfStakers -= 1;
            }
        }
        emit HANDLE_REQUEST(user,address(this),block.timestamp);
    }

    function calculateScore(
        uint256 _amount,
        uint256 _time
    ) 
        public 
        view 
        returns(uint256 score,uint256 multipler)
    {
        LibStake.Layout storage ss = LibStake.layout();

        if(_amount >= ss.amounts[0] && _time >= ss.times[0]){
            uint256 amountMultipler = _amountMultipler(_amount);
            uint256 timeMultipler = _timeMultipler(_time);

            multipler = (amountMultipler * timeMultipler);
            score = (_amount / DIFFERENCE_AMOUNT) * multipler;
        }
    }

    function _timeMultipler(
        uint256 _time
    ) 
        internal 
        view 
        returns(uint256 multipler)
    {
        LibStake.Layout storage ss = LibStake.layout();
        uint256[] memory times = ss.times;

        for(uint256 i = 0; i < times.length;){
            uint256 currentTime = times[i];
            uint256 nextTime = (i < times.length - 1) ? times[i + 1] : type(uint256).max;

            if (_time >= currentTime && _time < nextTime) {
                multipler = ss.timesMultipler[currentTime];
                break;
            }

            unchecked { 
                i++; 
            }
        }
    }

    function _amountMultipler(
        uint256 _amount
    ) 
        internal 
        view 
        returns(uint256 multipler) 
    {
        LibStake.Layout storage ss = LibStake.layout();
        uint256[] memory amounts = ss.amounts;

        for(uint256 i = 0; i < amounts.length;){
            uint256 currentAmount = amounts[i];
            uint256 nextAmount = (i < amounts.length - 1) ? amounts[i + 1] : type(uint256).max;

            if (_amount >= currentAmount && _amount < nextAmount) {
                multipler = ss.amountMultipler[currentAmount];
                break;
            }

            unchecked { 
                i++; 
            }
        }
    }

    function calculateRewards(
        address _user
    ) 
        public 
        view 
        returns(uint256,uint256) 
    {
        uint256 token0Reward = 0;
        uint256 token1Reward = 0;
        address user = _user;
        LibStake.Layout storage ss = LibStake.layout();

        if(ss.user[user].staker){
            uint256 userCCIndex = ss.user[user].userChangeCountIndex;
            uint256 poolCCIndex = ss.stakePoolInfo.lastCHCIndex;
            uint256 blockTime = block.timestamp;
            uint256 diff = 1 ether;
            for(uint256 i = userCCIndex; i <= poolCCIndex;) {
                uint256 userWeight = ss.user[user].userTotalScore.mulDiv(diff,ss.chc[i].chcTotalPoolScore);
                uint256 reward0 = ss.chc[i].chcToken0RewardPerTime.mulDiv(userWeight,diff);
                uint256 reward1 = ss.chc[i].chcToken1RewardPerTime.mulDiv(userWeight,diff);

                if(ss.chc[i].canWinPrizesToken0) {
                    uint256 userActiveTimeForToken0 = 0;

                    if(i == poolCCIndex && blockTime > ss.chc[i].chcToken0DistributionEndTime) {
                        unchecked {
                            userActiveTimeForToken0 = ss.chc[i].chcToken0DistributionEndTime - ss.chc[i].chcStartTime;
                        }
                    }else {
                        if(i == poolCCIndex) {
                            unchecked {
                                userActiveTimeForToken0 = blockTime - ss.chc[i].chcStartTime;
                            }
                        }else {
                            unchecked {
                                userActiveTimeForToken0 = ss.chc[i].chcEndTime - ss.chc[i].chcStartTime;
                            }
                        }
                    }
                    unchecked {
                        token0Reward = token0Reward + (reward0 * userActiveTimeForToken0);
                    }
                }

                if(ss.chc[i].canWinPrizesToken1) {
                    uint256 userActiveTimeForToken1 = 0;

                    if(i == poolCCIndex && blockTime > ss.chc[i].chcToken1DistributionEndTime) {
                        unchecked {
                            userActiveTimeForToken1 = ss.chc[i].chcToken1DistributionEndTime - ss.chc[i].chcStartTime;
                        }
                    }else {
                        if(i == poolCCIndex) {
                            unchecked {
                                userActiveTimeForToken1 = blockTime - ss.chc[i].chcStartTime;
                            }
                        }else {
                            unchecked {
                                userActiveTimeForToken1 = ss.chc[i].chcEndTime - ss.chc[i].chcStartTime;
                            }
                        }
                    }
                    unchecked {
                        token1Reward = token1Reward + (reward1 * userActiveTimeForToken1);
                    }
                }
                unchecked {
                    i++;
                }
            }
        }
        return (token0Reward, token1Reward);
    }

    function _updateChc(
        address _address
    )
        private
    {
        LibStake.Layout storage ss = LibStake.layout();

        uint256 blockTime                      = block.timestamp;
        uint256 currentCHCIndex                = ss.stakePoolInfo.lastCHCIndex;
        uint256 nextCHCIndex                   = currentCHCIndex + 1;
        ss.chc[currentCHCIndex].chcEndTime     = blockTime;
        ss.stakePoolInfo.lastCHCIndex          = nextCHCIndex;
        ss.user[_address].userChangeCountIndex = nextCHCIndex;

        ss.chc[nextCHCIndex].chcStartTime                   = blockTime;
        ss.chc[nextCHCIndex].chcTotalPoolScore              = ss.stakePoolInfo.poolTotalScore;
        ss.chc[nextCHCIndex].chcToken0RewardPerTime         = ss.stakePoolInfo.poolToken0RewardPerTime;
        ss.chc[nextCHCIndex].chcToken1RewardPerTime         = ss.stakePoolInfo.poolToken1RewardPerTime;
        ss.chc[nextCHCIndex].chcToken0DistributionEndTime   = ss.stakePoolInfo.poolToken0DistributionEndTime;
        ss.chc[nextCHCIndex].chcToken1DistributionEndTime   = ss.stakePoolInfo.poolToken1DistributionEndTime;
        ss.chc[nextCHCIndex].canWinPrizesToken0 = blockTime < ss.chc[nextCHCIndex].chcToken0DistributionEndTime;
        ss.chc[nextCHCIndex].canWinPrizesToken1 = blockTime < ss.chc[nextCHCIndex].chcToken1DistributionEndTime;
    }

    function _safeClaim(
        address to
    ) 
        private
        returns(bool claimed)
    {
        LibStake.Layout storage ss = LibStake.layout();

        (uint256 token0Reward, uint256 token1Reward) = calculateRewards(to);

        if(token0Reward > 0){
            ISolidStateERC20 token0 = ISolidStateERC20(ss.stakePoolInfo.token0);
            
            unchecked {
                ss.user[to].userEarnedToken0Amount += token0Reward;
                ss.stakePoolInfo.poolToken0Liquidity -= token0Reward;
                ss.stakePoolInfo.poolDistributedToken0Reward += token0Reward;
            }
            claimed = true;

            token0.transfer(to,token0Reward);

            emit FORCED_HARVEST(address(this),to,token0Reward);
        }

        if(token1Reward > 0){
            ISolidStateERC20 token1 = ISolidStateERC20(ss.stakePoolInfo.token1);
            
            unchecked {
                ss.user[to].userEarnedToken1Amount += token1Reward;
                ss.stakePoolInfo.poolToken1Liquidity -= token1Reward;
                ss.stakePoolInfo.poolDistributedToken1Reward += token1Reward;
            }
            claimed = true;

            token1.transfer(to,token1Reward);

            emit FORCED_HARVEST(address(this),to,token1Reward);
        }
    }

    function _findIndex(
        uint256 _index,
        address _user
    ) 
        internal 
        view 
        returns(uint256) 
    {
        uint256[] storage tierSections = LibStake.layout().user[_user].userStakeTierSections;

        for (uint256 i = 0; i < tierSections.length;){
            if (tierSections[i] == _index){
                return i;
            }
            unchecked{
                i++;
            }
        }
        revert Invalid_Action();
    }

    function _removeIndexValue(
        uint256 _index,
        address _user
    ) 
        private
    {
        LibStake.Layout storage ss = LibStake.layout();

        (uint256 index) = _findIndex(_index,_user);

        if(ss.user[_user].userStakeTierSections.length > 0){
            ss.user[_user].userStakeTierSections[index] = ss.user[_user].userStakeTierSections[ss.user[_user].userStakeTierSections.length - 1];
        }
        ss.user[_user].userStakeTierSections.pop();
    }

    function addToken0Liquidity(
        uint256 _amount
    ) 
        public 
        onlyOwner 
    {
        LibStake.Layout storage ss = LibStake.layout();
        ISolidStateERC20 token0 = ISolidStateERC20(ss.stakePoolInfo.token0);

        if(token0.balanceOf(msg.sender) < _amount){revert Insufficient_Balance();}
        if(token0.allowance(msg.sender, address(this)) < _amount){revert Insufficient_Allowance();}

        unchecked {
            ss.stakePoolInfo.poolToken0Liquidity += _amount;
        }

        ss.stakePoolInfo.poolToken0RewardPerTime = _amount / YEAR_IN_SECONDS;
        ss.stakePoolInfo.poolToken0DistributionEndTime = block.timestamp + YEAR_IN_SECONDS;

        _updateChc(address(0));

        token0.transferFrom(msg.sender,address(this),_amount);

        emit HANDLE_ADD_LIQUIDITY(msg.sender,ss.stakePoolInfo.token0,block.timestamp);
    }

    function addToken1Liquidity(
        uint256 _amount
    ) 
        public 
        onlyOwner 
    {
        LibStake.Layout storage ss = LibStake.layout();
        ISolidStateERC20 token1 = ISolidStateERC20(ss.stakePoolInfo.token1);

        if(token1.balanceOf(msg.sender) < _amount){revert Insufficient_Balance();}
        if(token1.allowance(msg.sender, address(this)) < _amount){revert Insufficient_Allowance();}

        unchecked {
            ss.stakePoolInfo.poolToken0Liquidity += _amount;
        }

        ss.stakePoolInfo.poolToken1RewardPerTime = _amount / YEAR_IN_SECONDS;
        ss.stakePoolInfo.poolToken1DistributionEndTime = block.timestamp + YEAR_IN_SECONDS;

        _updateChc(address(0));

        token1.transferFrom(msg.sender,address(this),_amount);
        
        emit HANDLE_ADD_LIQUIDITY(msg.sender,ss.stakePoolInfo.token1,block.timestamp);
    }

}