// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library LibMerkleProof {

    function verify(
        bytes32[] calldata proof, 
        bytes32 root, 
        bytes32 leaf
    ) 
        internal 
        pure 
        returns (bool) 
    {
        bytes32 computedHash = leaf;
        uint256 proofLength = proof.length;
        
        for (uint256 i; i < proofLength;) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            
            unchecked {
                i++;
            }
        }
        return computedHash == root;
    }

}