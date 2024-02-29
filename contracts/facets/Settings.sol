// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import { TStakePoolInfo, TStakeTierSection, TUser } from "../libraries/Structs.sol";
import '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { Modifiers } from "../libraries/Modifiers.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { LibGame } from "../libraries/LibGame.sol";
import "../libraries/Errors.sol";

contract Settings is Modifiers, OwnableInternal {

    // Attention, this product is in the testing phase.
    
    function addAmounts(
        uint256[] memory _amounts, 
        uint256[] memory _multipliers
    ) 
        external 
        onlyOwner 
    {
        uint256[] memory amounts = _amounts;
        uint256[] memory multipliers = _multipliers;
        if(amounts.length != multipliers.length){ revert Array_Lengths_Not_Match();}

        LibStake.Layout storage ss = LibStake.layout();

        for (uint256 i = 0; i < amounts.length;) {
            ss.amountMultipler[amounts[i]] = multipliers[i];
            ss.amounts.push(amounts[i]);
            unchecked{
                i++;
            }
        }
    }

    function addTimes(
        uint256[] memory _times,
        uint256[] memory _multipliers
    ) 
        external 
        onlyOwner 
    {
        uint256[] memory times = _times;
        uint256[] memory multipliers = _multipliers;
        if(times.length != multipliers.length){ revert Array_Lengths_Not_Match();}

        LibStake.Layout storage ss = LibStake.layout();

        for (uint256 i = 0; i < times.length;){
            ss.timesMultipler[times[i]] = multipliers[i];
            ss.times.push(times[i]);
            unchecked{
                i++;
            }
        }
    }

    function setToken0(
        address _address
    )
        external
        onlyOwner
        isValidContract(_address)
    {
        LibStake.layout().stakePoolInfo.token0 = _address;
    }

    function setToken1(
        address _address
    ) 
        external 
        onlyOwner 
        isValidContract(_address) 
    {
        LibStake.layout().stakePoolInfo.token1 = _address;
    }

    function setPoolActive(
        bool _status
    ) 
        external 
        onlyOwner 
    {
        LibStake.layout().stakePoolInfo.isActive = _status;
    }

    function setPoolStatus(
        bool _status
    ) 
        external 
        onlyOwner 
    {
        LibStake.layout().stakePoolInfo.isActive = _status;
    }

}