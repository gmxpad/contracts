// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

error InvalidMinter();

contract XGameCard is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Strings for uint256;

    // Attention, this product is in the testing phase.

    uint256 private _nextTokenId;

    mapping(uint256 => bool) private isClaimed;
    mapping(uint256 => uint256) private multipler;
    mapping(address => bool) private minters;

    constructor(
        address _initialOwner
    )
        ERC721("XGame", "XG")
        Ownable(_initialOwner)
    {
        _nextTokenId = 1e6;
        minters[_initialOwner] = true;
    }

    function safeMint(
        uint256 _multipler,
        address to
    ) 
        public 
        onlyMinters(msg.sender) 
    {
        uint256 tokenId = _nextTokenId++;
        multipler[tokenId] = _multipler;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _createTokenURI(_multipler));
    }

    // function getCardAttributes(
    //     TokenInfo memory _params
    // ) 
    //     internal 
    //     pure 
    //     returns(string memory attributes)
    // {
    //     attributes = generateTag("NAME","",_params.name,0,true);
    //     attributes = string(abi.encodePacked(attributes,generateTag("SYMBOL","",_params.symbol,0,true)));
    //     attributes = string(abi.encodePacked(attributes,generateTag("DECIMALS","number",_params.decimals.toString(),0,true)));
    //     attributes = string(abi.encodePacked(attributes,generateTag("TOKEN ID","number",_params.tokenId.toString(),0,true)));
    //     attributes = string(abi.encodePacked(attributes,generateTag("CONTRACT","",(uint256(uint160(_params.token))).toHexString(20),0,true)));
    //     attributes = string(abi.encodePacked(attributes,generateTag("VERIFIED","",_params.verified ? "YES" : "NO",0,true)));
    //     attributes = string(abi.encodePacked(attributes,generateTag("WEB","","https://imon.ai",0,false)));
    //     attributes = string(abi.encodePacked("[",attributes,"]"));
    // }

    function generateTag(
        string memory _key, 
        string memory _display_type,
        string memory _value,
        uint256 _max_value, 
        bool _comma
    ) 
        internal 
        pure 
        returns(string memory tag)
    {
        tag = string(abi.encodePacked('{"trait_type":"',_key,'",'));
        if (keccak256(abi.encodePacked(_display_type)) != keccak256(abi.encodePacked(""))) {
            tag = string(abi.encodePacked(tag,'"display_type":"',_display_type,'",'));
        }
        tag = string(abi.encodePacked(tag, '"value":"',_value,'"'));
        if (_max_value > 0) {
            tag = string(abi.encodePacked(tag,',"max_value":"',_max_value.toString(),'"'));
        }
        tag = string(abi.encodePacked(tag,_comma? "},":"}"));
        return tag;
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
                            '{"trait_type":"Round","value":"#1"},',
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

    function getNFTClaimed(
        uint256 tokenId
    )
        public 
        view 
        returns (bool claimed) 
    {
        claimed = isClaimed[tokenId];
    }

    function setNFTClaimed(
        uint256 tokenId
    ) 
        public 
        onlyMinters(msg.sender) 
    {
        isClaimed[tokenId] = true;
    }

    function setMinter(
        bool _status,
        address _address
    ) 
        external 
        onlyOwner 
    {
        minters[_address] = _status;
    }

    modifier onlyMinters(
        address _user
    ) 
    {
        if(!minters[_user]){ revert InvalidMinter(); }
        _;
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