// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts Validator: primarily serve data integrity
contract Validator {

    // Get a message hash for comparison
    function getMessageHash(
        uint256 _amount,
        address _wallet,
        bytes32 _commitment
    ) public pure returns (bytes32) {
        // Check if commitments are valid before proceeding
        require(validateCommitment(_commitment), "Invalid commitment.");
        return
            keccak256(
                abi.encodePacked(_amount, _wallet, _commitment)
            );
    }

    //Get commitment first
    function getCommitment() public view returns (bytes32) {
        bytes32 commitment = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, block.prevrandao)
        );
        return commitment;
    }

    // Validate commitment (only valid if not equal to bytes32(0))
    function validateCommitment(bytes32 _commitment)
        internal
        pure
        returns (bool)
    {
        return _commitment != bytes32(0);
    }

    // Validate private key by calling checkPrivateKey function
    function validatePrivateKey(string memory _privateKeyHash)
        internal
        pure
        returns (bool)
    {
        // Return result from checkPrivateKey
        return checkPrivateKey(_privateKeyHash);
    }

    // Check the format of the private key
    function checkPrivateKey(string memory input) private pure returns (bool) {
        bytes memory strBytes = bytes(input);
        int256 lastDash = -1;
        uint256 strLength = strBytes.length;

        // Iterate to find the last dash ('-') in the input string
        for (uint256 i = 0; i < strLength; ++i) {
            if (strBytes[i] == "-") {
                lastDash = int256(i);
            }
        }

        // Return false if no dash found
        if (lastDash == -1) {
            return false;
        }

        // Process characters after the last dash to validate
        uint256 start = uint256(lastDash) + 1;
        bytes memory tempResult = new bytes(128); // Temporary result array
        uint256 j = 0;

        // Loop through the characters and store valid ones
        for (uint256 i = start; i < strLength && j < 128; ++i) {
            bytes1 tempChar = strBytes[i];
            // Allow only alphanumeric characters (0-9, A-Z, a-z)
            if (
                (tempChar >= 0x30 && tempChar <= 0x39) || // Numbers 0-9
                (tempChar >= 0x41 && tempChar <= 0x5A) || // Uppercase A-Z
                (tempChar >= 0x61 && tempChar <= 0x7A) // Lowercase a-z
            ) {
                tempResult[j] = tempChar;
                ++j;
            }
        }

        // If the length is not exactly 128 characters, return false
        if (j != 128) {
            return false;
        }
        // Return true if the private key is valid
        return true;
    }
}
