// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Errors.sol";

abstract contract Modifiers {


    modifier whenNotContract(
        address _contractAddress
    )
    {
        if(msg.sender != tx.origin) revert Address_Is_A_Contract(_contractAddress);
        if(_contractAddress != tx.origin) revert Address_Is_A_Contract(_contractAddress);
        if(_contractAddress == address(this)) revert Address_Is_A_Contract(_contractAddress);
        if(_contractAddress == address(0)) revert Address_Cannot_Be_Zero();
        if(isAddressContract(_contractAddress)) revert Address_Is_A_Contract(_contractAddress);
        if(isAddressContract(msg.sender)) revert Address_Is_A_Contract(_contractAddress);

        uint256 size;
        assembly {
            size := extcodesize(_contractAddress)
        }
        if(size > 0)revert Address_Is_A_Contract(_contractAddress);
        _;
    }

    function isAddressContract(
        address account
    ) 
        internal 
        view 
        returns (bool) 
    {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    modifier isValidContract(
        address _contractAddress
    )
    {
        if(_contractAddress == address(0)) revert Address_Cannot_Be_Zero();
        uint256 size;
        assembly {
            size := extcodesize(_contractAddress)
        }
        bool isContract = size > 0;
        if(!isContract) revert Address_Is_A_Not_Contract(_contractAddress);
        _;
    }
    
}