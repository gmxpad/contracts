// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Delegate is Ownable {
    address public targetContract;
    
    constructor(
        address _targetContract
    ) Ownable(msg.sender) 
    {
        targetContract = _targetContract;
    }
    
    function triggerCall(
        string memory _functionName
    ) 
        public 
        onlyOwner 
    {
        (bool success, ) = targetContract.delegatecall(
            abi.encodeWithSignature(_functionName)
        );
        require(success, "Delegated call failed");
    }
}