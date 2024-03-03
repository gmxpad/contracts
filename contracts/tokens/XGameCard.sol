// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract XGameCard is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {

    // Attention, this product is in the testing phase.

    uint256 private _nextTokenId;

    mapping(uint256 => uint256) private multipler;

    constructor(
        address initialOwner
    )
        ERC721("XGame", "XG")
        Ownable(initialOwner)
    {
        _nextTokenId = 1e6;
    }

    function safeMint(
        uint256 _multipler,
        address to
    ) 
        public 
        onlyOwner 
    {
        uint256 tokenId = _nextTokenId++;
        multipler[tokenId] = _multipler;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _createTokenURI(_multipler));
    }

    function _createTokenURI(
        uint256 _multipler
    ) 
        internal 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"XGame '," ", Strings.toString(_multipler),"x",'",',
                            '"description":"XPAD MEMBER CARD.",',
                            '"image":"ipfs://bafybeigqkzhusnmjmhgszzhvsnpdxyfbocknpd2ldpvmdo34ld4twyu4ey",',
                            '"attributes": ['
                            '{"trait_type":"Multipler","value":"', Strings.toString(_multipler),"x",'"},',
                            '{"trait_type":"Website","value":"gamexpad.io"},',
                            '{"trait_type":"Telegram","value":"@gamexpad"},',
                            '{"trait_type":"Twitter","value":"@gmxpad.io"},',
                            '{"trait_type":"Github","value":"@gmxpad"}',
                            ']}'
                        )
                    )
                )
            )
        );
    }

    function getMultipler(
        uint256 tokenId
    ) 
        public 
        view 
        returns (uint256 mul) 
    {
        mul = multipler[tokenId];
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
}