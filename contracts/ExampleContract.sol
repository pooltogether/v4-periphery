// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/// @title 
/// @notice 
contract ExampleContract{

    ///@notice Emits the block time
    address public immutable owner;

    ///@notice Emits the block time
    ///@param block block number
    event ReallyCoolEvent(uint256 indexed block);


    constructor() public {
        owner = msg.sender;
    }

    ///@notice Emits the block time
    function callMe() external {
        emit ReallyCoolEvent(block.number);
    }
}
