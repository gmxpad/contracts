// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TStakePoolInfo, TStakeTierSection, TUser,TGame, TUserIpo,TGameIpo } from "../libraries/Structs.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { LibGame } from "../libraries/LibGame.sol";
import { IERC721Game } from "../interfaces/IERC721Game.sol";

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

    function getGames(
        uint256 _id
    ) 
        public 
        view 
        returns (TGame memory) 
    {
        return LibGame.layout().game[_id];
    }

    function getIpo(
        uint256 _id,
        uint256 _round
    ) 
        public 
        view 
        returns (TGameIpo memory) 
    {
        return LibGame.layout().gameIpo[_id][_round];
    }

    function getIpoForUser(
        uint256 _id,
        uint256 _round,
        address _user
    ) 
        public 
        view 
        returns (TUserIpo memory) 
    {
        return LibGame.layout().userIpo[_user][_id][_round];
    }

    struct SupportedCheckNFTs {
        uint256 gameId;
        uint256[] tokenIds;
    }

    function checkUserNFTs(
        address _user
    )
        public 
        view 
        returns(SupportedCheckNFTs[] memory) 
    {
        LibGame.Layout storage gs = LibGame.layout();
        uint256[] memory ids = gs.gameIds;
        uint256 idsLength = ids.length;

        SupportedCheckNFTs[] memory ownedNFTs = new SupportedCheckNFTs[](idsLength);

        for(uint256 i = 0; i < idsLength;){
            uint256 roundCount = gs.game[i].roundCount;
            IERC721Game nft = IERC721Game(gs.game[i].nftContract);
            
            for(uint256 j = 0; j < roundCount;){

                ownedNFTs[i].push({
                    gameId: i,
                    tokenIds: [j]
                });
                unchecked {
                    j++;
                }
            }

            unchecked {
                i++;
            }
        }
    }
   
}