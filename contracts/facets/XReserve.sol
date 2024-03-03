// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Insufficient_Balance();

contract XReserve is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdrawal(address indexed from, address indexed to, uint256 value);

    function withdrawToken(
        uint256 _amount,
        address _to,
        address _token
    ) 
        external 
        onlyOwner 
    {
        IERC20 token = IERC20(_token);
        if(token.balanceOf(address(this)) < _amount)revert Insufficient_Balance();
        token.transfer(_to,_amount);
        emit Transfer(address(this),_to,_amount);
    }

    function withdrawNative(
        address _user
    ) 
        external 
        onlyOwner 
    {
        uint256 amount = address(this).balance;
        if(amount > 0){
            address to = _user;
            (bool success, ) = to.call{value: amount}(new bytes(0));
            require(success);
        }
        emit Withdrawal(address(this),_user,amount);
    }

    receive() external payable {}

}