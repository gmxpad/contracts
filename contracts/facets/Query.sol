// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TStakePoolInfo, TStakeTierSection, TUser,TGame } from "../libraries/Structs.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { LibGame } from "../libraries/LibGame.sol";

contract Query {

    // Attention, this product is in the testing phase.
    
    function getPoolInfo(
    ) 
        public 
        view 
        returns (TStakePoolInfo memory poolInfo) 
    {
        poolInfo = LibStake.layout().stakePoolInfo;
    }

    function getUserInfo(
        address _address
    ) 
        public 
        view 
        returns (TUser memory userInfo) 
    {
        userInfo = LibStake.layout().user[_address];
    }

    function getUserStakeList(
        address _address
    ) 
        public 
        view 
        returns (uint256[] memory stakeList) 
    {
        stakeList = LibStake.layout().user[_address].userStakeTierSections;
    }

    function getUserStakePeriod(
        uint256 _index,
        address _address
    ) 
        public 
        view 
        returns (TStakeTierSection memory period) 
    {
        period = LibStake.layout().userTierSection[_address][_index];
    }

    function getStakeEndTime(
        uint256 _index,
        address _address
    ) 
        public 
        view 
        returns (uint256 endTime) 
    {
        uint256 stakeEndTime = LibStake.layout().userTierSection[_address][_index].endTime;
        if(stakeEndTime > block.timestamp){ endTime = stakeEndTime - block.timestamp; }
    }

    function getRequestEndTime(
        uint256 _index, 
        address _address
    ) 
        public 
        view 
        returns (uint256 endTime) 
    {
        uint256 requestEndTime = LibStake.layout().userTierSection[_address][_index].exitTime;
        if(requestEndTime > block.timestamp){ endTime = requestEndTime - block.timestamp; }
    }

    function getAmounts(
    ) 
        public 
        view 
        returns (uint256[] memory amounts) 
    {
        amounts = LibStake.layout().amounts;
    }

    function getTimes(
    ) 
        public 
        view 
        returns (uint256[] memory times) 
    {
        times = LibStake.layout().times;
    } 


    function getAllGames(
    )
        public 
        view 
        returns (TGame[] memory) 
    {
        LibGame.Layout storage gs = LibGame.layout();
        uint256[] memory ids = gs.gameIds;
        uint256 idsLength = ids.length;
        TGame[] memory games = new TGame[](idsLength);

        for (uint256 i = 0; i < idsLength;) {
            games[i] = gs.game[ids[i]];

            unchecked{
                i++;
            }
        }
        return games;
    }
   

}