// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ISolidStateERC1155 } from "@solidstate/contracts/token/ERC1155/ISolidStateERC1155.sol";
import { ISolidStateERC721 } from "@solidstate/contracts/token/ERC721/ISolidStateERC721.sol";
import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import  "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { TGame } from "../libraries/Structs.sol";
import { Modifiers } from "../libraries/Modifiers.sol";
import { LibStake } from "../libraries/LibStake.sol";
import { LibGame } from "../libraries/LibGame.sol";
import "../libraries/Errors.sol";

contract Create is Modifiers, OwnableInternal {

    // Attention, this product is in the testing phase.

    function createGame(
        TGame memory _params
    ) 
        external 
        onlyOwner 
    {
        LibGame.Layout storage gs = LibGame.layout();

        if(gs.game[_params.projectId].isExist){ revert Invalid_Action(); }
        gs.gameIds.push(_params.projectId);
        gs.game[_params.projectId] = _params;
    }

}