// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract DynamicShieldWallet is ReentrancyGuard, Ownable {
    error Warning(string content);

    constructor(address _originCash) Ownable(_originCash) {}

    receive() external payable {
        require(msg.sender != address(0), "Invalid sender");
        require(msg.value != 0, "No asset sent");
    }

    fallback() external payable {
        revert Warning("Fallback triggered");
    }

    // Function to receive funds and forward them to Origin Cash
    function transferWhenUserDeposit(uint256 _amount)
        external
        payable
        nonReentrant
        onlyOriginCash
        returns (bool)
    {
        bool success = payable(originCash).send(_amount);
        require(success, "Transfer to OriginCash failed");
        return success;
    }

    // Function to send assets/fees from Origincash to user
    function transferWhenUserWithdraw(
        address payable _to,
        address payable _feeReceiptAddress,
        uint256 _amountAfterFee,
        uint256 _fee
    ) external virtual nonReentrant onlyOriginCash returns (bool) {
        require(
            address(this).balance >= _amountAfterFee + _fee,
            "Insufficient funds"
        );
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        require(size == 0, "Address is a contract");

        assembly {
            size := extcodesize(_feeReceiptAddress)
        }
        require(size == 0, "Address is a contract");

        bool successTo = _to.send(_amountAfterFee);
        if (!successTo) {
            return false;
        }

        bool successFee = _feeReceiptAddress.send(_fee);
        if (!successFee) {
            return false;
        }
        return true;
    }

    // Return Funds: If the deposit and withdrawal process fails
    function returnFunds(address payable _recipient)
        external
        nonReentrant
        onlyOriginCash
    {
        require(_recipient != address(0), "Invalid recipient address");
        uint256 balance = address(this).balance;
        (bool success, ) = _recipient.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
