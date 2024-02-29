// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ItemType, EventType, EventRound } from "./Enums.sol";

    // Stake Structs

    struct TPoolInitParams {
        uint256 minimumStakeAmount;
        uint256 maximumStakeAmount;
        uint256 minimumLockTime;
        uint256 maximumLockTime;
        uint256 requestCliffTime;
    }
    struct TStakeTierSection{
        bool receivable;

        uint256 indexID;
        uint256 enterTime;
        uint256 exitTime; // request end time
        uint256 stakeAmount;
        uint256 userScore;
        uint256 endTime; // stake end time
        uint256 tierMultipler;
    }

    struct TChangeCountIndex{
        bool canWinPrizesToken0;
        bool canWinPrizesToken1;

        uint256 chcTotalPoolScore;

        uint256 chcStartTime;
        uint256 chcEndTime;

        uint256 chcToken0RewardPerTime;
        uint256 chcToken0DistributionEndTime;

        uint256 chcToken1RewardPerTime;
        uint256 chcToken1DistributionEndTime;        
    }

    struct TUser {
        bool staker;

        uint256 userChangeCountIndex;
        uint256 userTotalStakeAmount;
        uint256 userTotalScore;
        uint256 userStakeTierCount;
        uint256 userEarnedToken0Amount;
        uint256 userEarnedToken1Amount;

        uint256[] userStakeTierSections;
    }

    struct TStakePoolInfo {
        bool isActive;

        uint256 lastCHCIndex;
        uint256 numberOfStakers;

        uint256 totalStakedToken;
        uint256 poolTotalScore;

        uint256 poolToken0RewardPerTime;
        uint256 poolDistributedToken0Reward;
        uint256 poolToken0DistributionEndTime;
        uint256 poolToken0Liquidity;

        uint256 poolToken1RewardPerTime;
        uint256 poolDistributedToken1Reward;
        uint256 poolToken1DistributionEndTime;
        uint256 poolToken1Liquidity;

        address token0;
        address token1;
    }

    // Game Structs

    struct TGameSocials {
        string web;
        string twitter;
        string telegram;
        string discord;
        string whitepaper;
        string youtube;
    }

    struct TGamePlatforms {
        string pWeb;
        string pAndroid;
        string pWindows;
        string pMacOS;
        string pIOS;
    }

    struct TGameDetails {
        string slug;
        string name;
        string developer;
        string description;
        string imageBackground; // 4
        string imagePoster;
        string imageLogo;
        string videoTrailer;

        TGameSocials socials;
        TGamePlatforms platforms;

        string [] genres;
    }

    struct TGame {
        bool isExist;
        bool isView;
        bool isIPO;
        
        TGameDetails details;

        uint256 projectId;
        uint256 roundCount;
        uint256 totalUserCount;
        uint256 totalInvestment;

        uint256 round;

        uint256 minInvestment;
        uint256 maxInvestment; // 10

        uint256 toBeCollectedInvestment;
        uint256 collectedInvestment;

        uint256 perSharePrice;
        uint256 roundScore;
        uint256 userCount;

        uint256 registerStart; // 16
        uint256 registerEnd;

        uint256 guaranteedInvestmentStart;
        uint256 guaranteedInvestmentEnd;

        address nftContract;
    }



    

