// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/Base64.sol";

error Invalid_Action();
error Invalid_Minter();
error Invalid_Creator();

contract XGameCard1155 is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {
    using Strings for uint256;

    string private _name;
    string private _symbol;

    struct TNFTMetadata {
        uint256 multipler;
        string name;
        string website;
        string twitter;
        string telegram;
        string github;
    }

    struct TNFT {
        bool isExist;
        uint256 nextTokenId;
    }
    
    //      projectId;
    mapping(uint256 => TNFT) nftInfo;
    //      tokenId : (projectId * 1e18 ++);
    mapping(uint256 => TNFTMetadata) nftMetadata;

    mapping(address => bool) minters;
    mapping(address => bool) creators;

    constructor(
        string memory name_, 
        string memory symbol_, 
        address initialOwner_ 
    ) 
        ERC1155("") 
        Ownable(initialOwner_) 
    {
        _name = name_;
        _symbol = symbol_;
        minters[initialOwner_] = true;
        creators[initialOwner_] = true;
    }

    function name(
    ) 
        public 
        view 
        virtual 
        returns (string memory) 
    {
        return _name;
    }

    function symbol(
    ) 
        public 
        view 
        virtual 
        returns (string memory) 
    {
        return _symbol;
    }

    function createProject(
        uint256 _projectId
    ) 
        external 
        onlyCreators(msg.sender) 
    {
        if(nftInfo[_projectId].isExist) { revert Invalid_Action(); }
        uint256 writeTokenId = _projectId * 1e18;
        nftInfo[_projectId] = TNFT({
            isExist: true,
            nextTokenId: writeTokenId
        });
    }

    function mint(
        uint256 _projectId,
        TNFTMetadata memory _params,
        address account, 
        bytes memory data
    ) 
        public 
        onlyMinters(msg.sender) 
    {
        if(!nftInfo[_projectId].isExist) { revert Invalid_Action(); }
        nftInfo[_projectId].nextTokenId++;
        uint256 projectNextTokenId = nftInfo[_projectId].nextTokenId;

        nftMetadata[projectNextTokenId] = _params;

        _mint(account, projectNextTokenId, 1, data);
    }

    function mintBatch(
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data 
    ) 
        public 
        onlyOwner 
    {
        _mintBatch(to, ids, amounts, data);
    }

    function uri(
        uint256 tokenId
    ) 
        public 
        view 
        override 
        returns (string memory) 
    {
        TNFTMetadata memory tokenInfo = nftMetadata[tokenId];
        return metadata(tokenInfo);
    }

    function metadata(
        TNFTMetadata memory tokenInfo
    ) 
        public 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', tokenInfo.name,
                            '", "description":"The proof of equity for web2 games on the GameXPad platform.", "attributes":', 
                            getCardAttributes(tokenInfo),
                            ', "image": "',
                            'ipfs://bafybeigqkzhusnmjmhgszzhvsnpdxyfbocknpd2ldpvmdo34ld4twyu4ey',
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function getCardAttributes(
        TNFTMetadata memory _params
    ) 
        internal 
        pure 
        returns(string memory attributes) 
    {
        attributes = generateTag("NAME","",_params.name,0,true);
        attributes = string(abi.encodePacked(attributes,generateTag("MULTIPER","",Strings.toString(_params.multipler),0,true)));
        attributes = string(abi.encodePacked(attributes,generateTag("WEBSITE","",_params.website,0,true)));
        attributes = string(abi.encodePacked(attributes,generateTag("TWITTER","",_params.twitter,0,true)));
        attributes = string(abi.encodePacked(attributes,generateTag("TELEGRAM","",_params.telegram,0,true)));
        attributes = string(abi.encodePacked(attributes,generateTag("GITHUB","",_params.github,0,false)));
        attributes = string(abi.encodePacked("[",attributes,"]"));
    }

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

    function getNFTMetadata(
        uint256 _tokenId
    ) 
        public 
        view 
        returns (TNFTMetadata memory) 
    {
        return nftMetadata[_tokenId];
    }

    function getProject(
        uint256 _projectId
    ) 
        public 
        view 
        returns (TNFT memory) 
    {
        return nftInfo[_projectId];
    }

    function setMinters(
        bool _status,
        address _minter
    ) 
        external 
        onlyOwner 
    {
        minters[_minter] = _status;
    }

    function setCreators(
        bool _status,
        address _creator
    ) 
        external 
        onlyOwner 
    {
        creators[_creator] = _status;
    }

    modifier onlyMinters(
        address user
    ) 
    {
        if(!minters[user]){ revert Invalid_Minter(); }
        _;
    }

    modifier onlyCreators(
        address user
    ) 
    {
        if(!creators[user]){ revert Invalid_Creator(); }
        _;
    }

    function _update(
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory values
    )
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}