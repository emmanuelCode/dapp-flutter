// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24.0;

import "contracts/storage.sol";

// add and remove from total
contract Logic is Storage {

    event Log(address sender, uint amount, string message);

    function add() public payable {

        uint amount = msg.value;
        
        // update states
        amountGiven[msg.sender] += amount;
        totalAmount += amount;

        emit Log(msg.sender,amount, "added Ether") ;
    }


    function retrieve() public payable {

        // store the amount balance from the contract
        uint retrieveAmount = amountGiven[msg.sender];

        // update states
        amountGiven[msg.sender] = 0;
        totalAmount -= retrieveAmount;
        
        // check if contract has enough balance
        require(getContractBalance() >= retrieveAmount, "Insufficient contract balance");

        // This is the current recommended method to send ether.
        (bool sent,) = payable(msg.sender).call{value: retrieveAmount}("");
        require(sent, "Failed to send Ether to User");
     
        emit Log(address(this), retrieveAmount, "retrieve Ether") ;

    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }


}