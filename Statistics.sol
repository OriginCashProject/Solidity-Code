// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Statistics {
    uint256 private totalTransactions;

    function setTotalTransactions() internal virtual {
        totalTransactions = totalTransactions + 1;
    }

    function getTotalTransactions() public view returns (uint256) {
        return totalTransactions;
    }
}
