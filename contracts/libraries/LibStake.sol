// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TChangeCountIndex,TStakeTierSection,TUser,TStakePoolInfo } from "./Structs.sol";

library LibStake{
    bytes32 internal constant STORAGE_SLOT = keccak256('storage.stake.gamexpad.io');

    struct Layout {
        uint256[] amounts;
        uint256[] times;
        
        mapping(uint256 => uint256) amountMultipler;
        mapping(uint256 => uint256) timesMultipler;
        
        mapping(address => bool) blacklist;
        mapping(address => TUser) user;
        
        mapping(uint256 => TChangeCountIndex) chc;
        mapping(address => mapping(uint256 => TStakeTierSection)) userTierSection;

        TStakePoolInfo stakePoolInfo;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

}