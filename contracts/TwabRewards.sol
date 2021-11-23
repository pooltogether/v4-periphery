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
    /// @notice Settings of each promotion.
    mapping(uint32 => Promotion) internal _promotions;

    /// @notice Current promotion number.
    uint32 internal _currentPromotionId;

    /// @notice Current epoch number.
    uint32 internal _currentEpochId;

    /**
        @notice Emitted when contract has been deployed.
        @param owner Contract owner address
   */
    event Deployed(address owner);

    /**
        @notice Emmited when a promotion is created.
        @param promotion Pomotion settings
    */
    event PromotionCreated(Promotion promotion);

    /**
        @notice Deploy TwabRewards contract.
        @param _owner Contract owner address
    */
    constructor(address _owner) Ownable(_owner) {
        emit Deployed(_owner);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc ITwabRewards
    function createPromotion(address _ticket, PromotionParameters calldata _promotionParameters)
        external
        override
        returns (bool)
    {
        require(_isPromotionActive() == false, "TwabRewards/promotion-already-active");

        _requireTicket(_ticket);

        uint32 _nextPromotionId = _currentPromotionId + 1;
        _currentPromotionId = _nextPromotionId;

        Promotion memory _nextPromotion = Promotion(
            _nextPromotionId,
            msg.sender,
            _ticket,
            _promotionParameters.token,
            _promotionParameters.tokensPerEpoch,
            _promotionParameters.startTimestamp,
            _promotionParameters.epochDuration,
            _promotionParameters.numberOfEpochs
        );

        _promotions[_nextPromotionId] = _nextPromotion;

        emit PromotionCreated(_nextPromotion);

        return true;
    }

    /// @inheritdoc ITwabRewards
    function getCurrentPromotion() external view override returns (Promotion memory) {
        return _getCurrentPromotion();
    }

    /// @inheritdoc ITwabRewards
    function getPromotion(uint32 _promotionId) external view override returns (Promotion memory) {
        return _promotions[_promotionId];
    }

    /* ============ Internal Functions ============ */

    /**
    @notice Determine if address passed is actually a ticket.
    @param _ticket Address to check
   */
    function _requireTicket(address _ticket) internal view {
        require(address(_ticket) != address(0), "TwabRewards/ticket-not-zero-address");

        (bool succeeded, bytes memory data) = address(_ticket).staticcall(
            abi.encodePacked(ITicket(_ticket).controller.selector)
        );

        address controllerAddress;

        if (data.length > 0) {
            controllerAddress = abi.decode(data, (address));
        }

        require(succeeded && controllerAddress != address(0), "TwabRewards/invalid-ticket");
    }

    /**
        @notice Get current promotion settings.
        @dev This promotion can be inactive if the promotion period is over.
        @return Promotion settings
     */
    function _getCurrentPromotion() internal view returns (Promotion memory) {
        return _promotions[_currentPromotionId];
    }

    /**
        @notice Determine if current promotion is active.
        @dev When no
        @return True if promotion is active, false otherwise
    */
    function _isPromotionActive() internal view returns (bool) {
        Promotion memory _currentPromotion = _getCurrentPromotion();

        uint256 _promotionEndTimestamp = _currentPromotion.startTimestamp +
            (_currentPromotion.epochDuration * _currentPromotion.numberOfEpochs);

        return _promotionEndTimestamp > 0 && _promotionEndTimestamp >= block.timestamp;
    }
}
