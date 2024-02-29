// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;



/**
 * @dev Revert with an error when an account being called as an assumed
 *      contract does not have code and returns no data.
 * @param account The account that should contain code.
 */
  error Address_Is_A_Contract(address account);
  error Address_Is_A_Not_Contract(address account);


  error Array_Lengths_Not_Match();
  error Overflow_0x11();
  error Address_Cannot_Be_Zero();
  error Invalid_Action();
  error Insufficient_Balance();
  error Insufficient_Allowance();
  error Invalid_Price();
  error Invalid_Proof();
  error TokenID_Not_Found();
  error Paused_Actions();
  error Unregistered_Member();
  error Address_Is_Blacklist();
  error User_No_Receivable();
  error User_Not_Stake();
  error User_Not_Expired();
  error Paused();
  error Insufficient_Lock_Time();
  error Insufficient_Stake_Amount();
  error User_Already_Staked();
  error User_Already_Claimed();
  error User_Already_requested();
  error Invalid_Address();
  error Claim_Not_Started();
  error User_Refunded();
  error Sale_End();
  error Wait_For_Deposit_Times();
  error User_Already_Registered();
  error Not_Started_Registration();
  error End_Registration();