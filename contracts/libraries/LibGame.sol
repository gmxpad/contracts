// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TGame, TUserIpo, TGameIpo,TUserIpo } from "./Structs.sol";

library LibGame {
    bytes32 internal constant STORAGE_SLOT = keccak256('storage.games.gamexpad.io');
    uint256 constant DIFFERENCE_AMOUNT = 1 ether;
    
    struct Layout {
        uint256[] gameIds;

        //      gameId
        mapping(uint256 => TGame) game;

        //      gameId            roundId
        mapping(uint256 => mapping(uint256 => TGameIpo)) gameIpo;
        //      user address       gameId            roundId
        mapping(address => mapping(uint256 => mapping(uint256 => TUserIpo))) userIpo;

        address usedTokenAddress;
        address reserveContractAddress;
    }

    function layout(
    ) 
        internal 
        pure 
        returns (Layout storage l) 
    {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}