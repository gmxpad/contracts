// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { SolidStateDiamond } from "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";
import {ISolidStateERC1155} from '@solidstate/contracts/token/ERC1155/ISolidStateERC1155.sol';
import {ISolidStateERC721} from "@solidstate/contracts/token/ERC721/ISolidStateERC721.sol";
import {ISolidStateERC20} from  "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";

import '@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol';

contract GameXPad is SolidStateDiamond {

    // Attention, this product is in the testing phase.
    
    constructor() {

        ERC165Base.supportsInterface(type(ISolidStateERC1155).interfaceId);
        ERC165Base.supportsInterface(type(ISolidStateERC721).interfaceId);
        ERC165Base.supportsInterface(type(ISolidStateERC20).interfaceId);

    }
}
