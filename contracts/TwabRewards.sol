// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/ITwabRewards.sol";

/**
 * @title PoolTogether V4 TwabRewards
 * @author PoolTogether Inc Team
 * @notice Contract to distribute rewards to depositors in a pool.
 */
contract TwabRewards is ITwabRewards, Manageable {
    /// @notice Current epoch number
    uint32 internal epochId;

    /**
    @notice Emitted when contract has been deployed.
    @param owner Contract owner address
   */
    event Deployed(address owner);

    /**
        @notice Deploy TwabRewards contract.
        @param _owner Contract owner address
    */
    constructor(address _owner) Ownable(_owner) {
        emit Deployed(_owner);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc ITwabRewards
    function createPromotion(ITicket _ticket, PromotionParameters calldata _promotion)
        external
        override
        returns (bool)
    {
        return true;
    }

    /* ============ Internal Functions ============ */

    /**
    @notice Determine if address passed is actually a ticket.
    @param _ticket Address to check
   */
    function _requireTicket(ITicket _ticket) internal {
        require(address(_ticket) != address(0), "TwabRewards/ticket-not-zero-address");

        (bool succeeded, bytes memory data) = address(_ticket).staticcall(
            abi.encodePacked(_ticket.controller.selector)
        );

        address controllerAddress;

        if (data.length > 0) {
            controllerAddress = abi.decode(data, (address));
        }

        require(succeeded && controllerAddress != address(0), "TwabRewards/invalid-ticket");
    }
}
