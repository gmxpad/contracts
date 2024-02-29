// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { LibMerkleProof } from '../libraries/LibMerkleProof.sol';
import  "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC721 } from '../interfaces/IERC721.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

error Insufficient_Balance();
error Already_Claimed();
error Merkle_Required();
error Not_Merkle_Required();
error Event_Not_Started();
error Event_Ended();
error Could_Not_Be_Queued();

contract XPassDistribute is Ownable, ReentrancyGuard {

    // Attention, this product is in the testing phase.
    
    struct PassData {
        bool isExist;
        bool isMerkle;
        
        bytes32 merkleRoot;

        uint256 userCount;
        uint256 tokensToBeDist;
        uint256 tokensDist;
        uint256 eventStartTime;
        uint256 eventEndTime;
    }

    uint256 private _currentEventID;

    mapping(uint256 => PassData) public pass;
    mapping(address => bool) public claimed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdrawal(address indexed from, address indexed to, uint256 value);
    event HandleMint(address indexed to,uint256 time);

    address XPASSCARD = address(0);

    constructor(
        address _xPassCard
    ) 
        Ownable(msg.sender) 
    {
        XPASSCARD = _xPassCard;
    }

    function simpleClaim(
    ) 
        public 
        nonReentrant 
    {
        address user = msg.sender;
        if(pass[_currentEventID].eventStartTime > block.timestamp) { revert Event_Not_Started(); }
        if(pass[_currentEventID].eventEndTime < block.timestamp) { revert Event_Ended(); }
        if(pass[_currentEventID].tokensDist == pass[_currentEventID].tokensToBeDist){ revert Event_Ended();}
        if(pass[_currentEventID].isMerkle){ revert Merkle_Required(); }
        if(claimed[user]){ revert Already_Claimed(); }

        claimed[user] = true;

        unchecked {
            pass[_currentEventID].tokensDist++;
            pass[_currentEventID].userCount++;
        }
        
        IERC721 nft = IERC721(XPASSCARD);
        nft.safeMint(user);
        emit HandleMint(user,block.timestamp);
    }

    function merkleClaim(
        uint256 _nodeIndex, 
        uint256 _tokenId,
        bytes32[] calldata _merkleProof
    ) 
        public 
        nonReentrant 
    {
        address user = msg.sender;
        if(!pass[_currentEventID].isMerkle){ revert Not_Merkle_Required(); }
        if(pass[_currentEventID].eventStartTime > block.timestamp) { revert Event_Not_Started(); }
        if(pass[_currentEventID].eventEndTime < block.timestamp) { revert Event_Ended(); }
        if(pass[_currentEventID].tokensDist == pass[_currentEventID].tokensToBeDist){ revert Event_Ended();}

        bytes32 node = keccak256(abi.encodePacked(_nodeIndex, user, _tokenId));
        require(LibMerkleProof.verify(_merkleProof, pass[_currentEventID].merkleRoot, node), "Invalid proof.");

        if(claimed[user]){ revert Already_Claimed(); }

        claimed[user] = true;

        unchecked {
            pass[_currentEventID].tokensDist++;
            pass[_currentEventID].userCount++;
        }

        IERC721 nft = IERC721(XPASSCARD);
        nft.safeMint(user);
        emit HandleMint(user,block.timestamp);
    }

    function initPassData(
        PassData memory _params
    ) 
        external 
        onlyOwner 
    {
        if(pass[_currentEventID].isExist){
            if(pass[_currentEventID].eventEndTime > block.timestamp) { revert Could_Not_Be_Queued(); }
        }
        unchecked {
            _currentEventID++;
        }
        uint256 eventID = _currentEventID;
        pass[eventID] = _params;
    }

    function setPassCard(
        address _newAddress
    ) 
        public 
        onlyOwner 
    {
        XPASSCARD = _newAddress;
    }

    function setEventExist(
        bool _status
    ) 
        public 
        onlyOwner 
    {
        pass[_currentEventID].isExist = _status;
    }

    function getUserCurrentEventInfo(
        address _user
    ) 
        public 
        view 
        returns (bool isClaimed) 
    {
        isClaimed = claimed[_user];
    }

    function getEventId(
    ) 
        public 
        view 
        returns (uint256 id) 
    {
        id = _currentEventID;
    }

    function getEventInfo(
    ) 
        public 
        view 
        returns (PassData memory) 
    {
        return pass[_currentEventID];
    }

}