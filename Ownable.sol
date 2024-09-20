// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
   
    address public owner;
    address public immutable originCash; //originCash value, cannot be changed

    constructor(address _originCash) {
        owner = msg.sender;
        originCash = _originCash;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyOriginCash() {
        require(msg.sender == originCash, "Caller is not OriginCash");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero");
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}
