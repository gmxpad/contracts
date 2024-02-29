// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TGame } from "./Structs.sol";

library LibGame {
    bytes32 internal constant STORAGE_SLOT = keccak256('storage.games.gamexpad.io');
    uint256 constant DIFFERENCE_AMOUNT = 1 ether;
    
    struct Layout {
        uint256[] gameIds;

        mapping(uint256 => TGame) game;
        mapping(uint256 => mapping(uint256 => bool)) user;
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