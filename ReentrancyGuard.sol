// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ReentrancyGuard {
    // Boolean values are expensive to write because Solidity compacts them into uint256 storage slots.
    // Thus, we use `uint256` instead of `bool` for more efficient storage.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // Initially set the status to _NOT_ENTERED (not in a reentrant state).
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is necessary to make those functions `private`
     * and add `external` `nonReentrant` entry points.
     */
    modifier nonReentrant() {
        // Check if the contract is in a reentrant state
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Set the status to _ENTERED to prevent reentrancy
        _status = _ENTERED;

        _; // Logic..

        // Reset the status back to _NOT_ENTERED after the function finishes execution
        _status = _NOT_ENTERED;
    }
}
