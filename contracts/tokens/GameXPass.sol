// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract GameXPass is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {

    // Attention, this product is in the testing phase.
    
    uint256 private _nextTokenId;
    mapping(address => bool) private _isMinter;
    mapping(uint256 => uint256) private _multipler;

    constructor(
        address _owner
    )
        ERC721("XPassCard", "XPASS")
        Ownable(_owner)
    {
        _nextTokenId = 1e6;
        _isMinter[_owner] = true;
        _isMinter[msg.sender] = true;
    }

    function _baseURI(
    ) 
        internal 
        pure 
        override 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"XPASS",',
                            '"description":"XPASS CARD.",',
                            '"image":"ipfs://bafybeigqkzhusnmjmhgszzhvsnpdxyfbocknpd2ldpvmdo34ld4twyu4ey",',
                            '"attributes": ['
                            '{"trait_type":"Website","value":"xx.io"},',
                            '{"trait_type":"Telegram","value":"t.me"},',
                            '{"trait_type":"Twitter","value":"x.com"},',
                            '{"trait_type":"Github","value":"github.com"}',
                            ']}'
                        )
                    )
                )
            )
        );
    }

    function safeMint(
        address to
    ) 
        public 
        onlyMinter(msg.sender) 
    {
        uint256 tokenId = _nextTokenId++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _baseURI());
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setMinter(
        bool _status,
        address _minter
    )
        external 
        onlyOwner 
    {
        _isMinter[_minter] = _status;
    }

    function setMultipler(
        uint256 _id,
        uint256 _nftMultipler
    ) 
        external 
        onlyOwner 
    {
        _multipler[_id] = _nftMultipler;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyMinter (
        address _minter
    )
    {
        if(!_isMinter[_minter]){revert ('Only Minters!');}
        _;
    }

}