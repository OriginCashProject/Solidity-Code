// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ProofMapping stores the pairs of `messageHash` and `_commitment`
 * that have already been used. When a transaction is executed with a pair
 * of proofs, it will be marked as used and cannot be reused.
 * This reduces the potential for spam calls and mitigates the risk of attacks.
 * Fundamentally, you must always remember to protect the "absolute secrecy of the private key".
 */

contract ProofMapping {
    mapping(bytes32 => mapping(bytes32 => bool)) private usedProofs;

    event ProofUsed(bytes32 indexed messageHash, bytes32 indexed commitment);

    // Function to check if a _messageHash + commitment pair has been used
    function isProofUsed(bytes32 _messageHash, bytes32 _commitment)
        internal
        view
        returns (bool)
    {
        return usedProofs[_messageHash][_commitment];
    }

    // Function to mark _messageHash + commitment pair as used
    function markProofAsUsed(bytes32 _messageHash, bytes32 _commitment)
        internal
    {
        // Load the value from state once into a local variable
        bool proofAlreadyUsed = usedProofs[_messageHash][_commitment];

        require(!proofAlreadyUsed, "Proof already used");

        // Update the state only once after verification
        usedProofs[_messageHash][_commitment] = true;

        emit ProofUsed(_messageHash, _commitment);
    }
}
