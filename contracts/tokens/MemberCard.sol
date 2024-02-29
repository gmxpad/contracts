// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MemberCard is ERC721, ERC721URIStorage, Ownable {

    // Attention, this product is in the testing phase.

    uint256 private _nextTokenId;

    constructor(address initialOwner)
        ERC721("MemberCard", "MC")
        Ownable(initialOwner)
    {
        _nextTokenId = 1000;
    }

    function safeMint(
        uint256 multipler,
        address to
    ) 
        public 
        onlyOwner 
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _createTokenURI(multipler));
    }

    function _createTokenURI(
        uint256 multipler
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
                            '{"name":"XPad Membership', Strings.toString(multipler),"x",'",',
                            '"description":"XPAD MEMBER CARD.",',
                            '"image":"ipfs://bafybeigqkzhusnmjmhgszzhvsnpdxyfbocknpd2ldpvmdo34ld4twyu4ey",',
                            '"attributes": ['
                            '{"trait_type":"Multipler","value":"xx.io"},',
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


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}