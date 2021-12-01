// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/v4-core/contracts/interfaces/ITicket.sol";

import "./interfaces/ITwabRewards.sol";

/**
 * @title PoolTogether V4 TwabRewards
 * @author PoolTogether Inc Team
 * @notice Contract to distribute rewards to depositors in a pool.
 */
contract TwabRewards is ITwabRewards {
    using SafeERC20 for IERC20;

    /* ============ Global Variables ============ */

    /// @notice Settings of each promotion.
    mapping(uint256 => Promotion) internal _promotions;

    /// @notice Latest promotion id.
    uint256 internal _latestPromotionId;

    /// @notice Keeps track of claimed rewards per user.
    /// @dev _claimedEpochs[promotionId][user] => claimedEpochs
    /// @dev We pack epochs claimed by a user into a uint256. So we can't store more than 256 epochs.
    mapping(uint256 => mapping(address => uint256)) internal _claimedEpochs;

    /* ============ Events ============ */

    /**
        @notice Emmited when a promotion is created.
        @param promotionId Id of the newly created promotion
    */
    event PromotionCreated(uint256 indexed promotionId);

    /**
        @notice Emmited when a promotion is cancelled.
        @param promotionId Id of the promotion being cancelled
        @param amount Amount of tokens transferred to the promotion creator
    */
    event PromotionCancelled(uint256 indexed promotionId, uint256 amount);

    /**
        @notice Emmited when a promotion is extended.
        @param promotionId Id of the promotion being extended
        @param amount Amount of tokens transferred to the recipient address
        @param numberOfEpochs New number of epochs after extending the promotion
    */
    event PromotionExtended(uint256 indexed promotionId, uint256 amount, uint256 numberOfEpochs);

    /**
        @notice Emmited when rewards have been claimed.
        @param promotionId Id of the promotion in which epoch rewards were claimed
        @param epochId Id of the epoch being claimed
        @param amount Amount of tokens transferred to the recipient address
    */
    event RewardsClaimed(uint256 indexed promotionId, uint256 indexed epochId, uint256 amount);

    /* ============ Modifiers ============ */

    /// @dev Ensure that the caller is the creator of the currently active promotion.
    /// @param _promotionId Id of the promotion to check
    modifier onlyPromotionCreator(uint256 _promotionId) {
        require(
            msg.sender == _getPromotion(_promotionId).creator,
            "TwabRewards/only-promotion-creator"
        );
        _;
    }

    /* ============ External Functions ============ */

    /// @inheritdoc ITwabRewards
    function createPromotion(
        address _ticket,
        address _token,
        uint216 _tokensPerEpoch,
        uint32 _startTimestamp,
        uint32 _epochDuration,
        uint8 _numberOfEpochs
    ) external override returns (uint256) {
        _requireTicket(_ticket);
        _requireEpochLimit(_numberOfEpochs);

        uint256 _nextPromotionId = _latestPromotionId + 1;
        _latestPromotionId = _nextPromotionId;

        IERC20(_token).safeTransfer(address(this), _tokensPerEpoch * _numberOfEpochs);

        Promotion memory _nextPromotion = Promotion(
            msg.sender,
            _ticket,
            _token,
            _tokensPerEpoch,
            _startTimestamp,
            _epochDuration,
            _numberOfEpochs
        );

        _promotions[_nextPromotionId] = _nextPromotion;

        emit PromotionCreated(_nextPromotionId);

        return _nextPromotionId;
    }

    /// @inheritdoc ITwabRewards
    function cancelPromotion(uint256 _promotionId, address _to)
        external
        override
        onlyPromotionCreator(_promotionId)
        returns (bool)
    {
        require(_isPromotionActive(_promotionId) == true, "TwabRewards/promotion-not-active");
        require(_to != address(0), "TwabRewards/recipient-not-zero-address");

        Promotion memory _promotion = _getPromotion(_promotionId);

        IERC20 _token = IERC20(_promotion.token);
        uint256 _remainingRewards = _getRemainingRewards(_promotionId);

        if (_remainingRewards > 0) {
            _token.safeTransfer(_to, _remainingRewards);
        }

        delete _promotions[_promotionId];

        emit PromotionCancelled(_promotionId, _remainingRewards);

        return true;
    }

    /// @inheritdoc ITwabRewards
    function extendPromotion(uint256 _promotionId, uint8 _numberOfEpochs)
        external
        override
        returns (bool)
    {
        require(_isPromotionActive(_promotionId) == true, "TwabRewards/promotion-not-active");

        Promotion memory _promotion = _getPromotion(_promotionId);
        uint8 _extendedNumberOfEpochs = _promotion.numberOfEpochs + _numberOfEpochs;

        _requireEpochLimit(_extendedNumberOfEpochs);

        IERC20 _token = IERC20(_promotion.token);
        uint256 _amount = _numberOfEpochs * _promotion.tokensPerEpoch;

        _token.safeTransfer(address(this), _amount);
        _promotions[_promotionId].numberOfEpochs = _extendedNumberOfEpochs;

        emit PromotionExtended(_promotionId, _amount, _extendedNumberOfEpochs);

        return true;
    }

    /// @inheritdoc ITwabRewards
    function getPromotion(uint256 _promotionId) external view override returns (Promotion memory) {
        return _getPromotion(_promotionId);
    }

    /// @inheritdoc ITwabRewards
    function getRemainingRewards(uint256 _promotionId) external view override returns (uint256) {
        return _getRemainingRewards(_promotionId);
    }

    /// @inheritdoc ITwabRewards
    function getCurrentEpochId(uint256 _promotionId) external view override returns (uint256) {
        return _getCurrentEpochId(_promotionId);
    }

    /// @inheritdoc ITwabRewards
    function getRewardAmount(
        address _user,
        uint256 _promotionId,
        uint256 _epochId
    ) external view override returns (uint256) {
        return _calculateRewardAmount(_user, _promotionId, _epochId);
    }

    /// @inheritdoc ITwabRewards
    function claimRewards(
        address _user,
        uint256 _promotionId,
        uint256 _epochId
    ) external override returns (uint256) {
        require(_epochId < _getCurrentEpochId(_promotionId), "TwabRewards/epoch-not-over");
        require(
            !_isClaimedEpoch(_user, _promotionId, _epochId),
            "TwabRewards/rewards-already-claimed"
        );

        uint256 _rewardAmount = _calculateRewardAmount(_user, _promotionId, _epochId);

        IERC20 _token = IERC20(_getPromotion(_promotionId).token);
        _token.safeTransferFrom(address(this), _user, _rewardAmount);

        _setClaimedEpoch(_claimedEpochs[_promotionId][_user], _epochId, true);

        emit RewardsClaimed(_promotionId, _epochId, _rewardAmount);

        return _rewardAmount;
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
        @notice Determine if the number of epochs passed exceeds the maximum number of epochs.
        @param _numberOfEpochs Number of epochs to check
    */
    function _requireEpochLimit(uint256 _numberOfEpochs) internal pure {
        require(_numberOfEpochs < type(uint8).max, "TwabRewards/exceeds-256-epochs-limit");
    }

    /**
        @notice Get settings for a specific promotion.
        @dev Will revert if the promotion does not exist.
        @param _promotionId Promotion id to get settings for
        @return Promotion settings
     */
    function _getPromotion(uint256 _promotionId) internal view returns (Promotion memory) {
        return _promotions[_promotionId];
    }

    /**
        @notice Get the current epoch id of a promotion.
        @dev Epoch ids and their boolean values are tightly packed and stored in a uint256, so epoch id starts at 0.
        @param _promotionId Id of the promotion to get current epoch for
        @return Epoch id
     */
    function _getCurrentEpochId(uint256 _promotionId) internal view returns (uint256) {
        Promotion memory _promotion = _getPromotion(_promotionId);
        uint256 _numberOfEpochs = _promotion.numberOfEpochs;

        // (_numberOfEpochs * block.timestamp) / promotionEndTimestamp
        return
            (_numberOfEpochs * block.timestamp) /
            (_promotion.startTimestamp + (_promotion.epochDuration * _numberOfEpochs));
    }

    /**
        @notice Get reward amount for a specific user.
        @dev Rewards can only be claimed once the epoch is over.
        @param _user User to get reward amount for
        @param _promotionId Promotion id from which the epoch is
        @param _epochId Epoch id to get reward amount for
        @return Reward amount
     */
    function _calculateRewardAmount(
        address _user,
        uint256 _promotionId,
        uint256 _epochId
    ) internal view returns (uint256) {
        Promotion memory _promotion = _getPromotion(_promotionId);

        uint256 _epochDuration = _promotion.epochDuration;
        uint256 _epochStartTimestamp = _promotion.startTimestamp + (_epochDuration * _epochId);
        uint256 _epochEndTimestamp = _epochStartTimestamp + _epochDuration;

        require(
            block.timestamp >= _epochStartTimestamp && block.timestamp <= _epochEndTimestamp,
            "TwabRewards/epoch-not-over"
        );

        ITicket _ticket = ITicket(_promotion.ticket);

        uint256 _averageBalance = _ticket.getAverageBalanceBetween(
            _user,
            uint64(_epochStartTimestamp),
            uint64(_epochEndTimestamp)
        );

        uint64[] memory _epochStartTimestamps = new uint64[](1);
        _epochStartTimestamps[0] = uint64(_epochStartTimestamp);

        uint64[] memory _epochEndTimestamps = new uint64[](1);
        _epochEndTimestamps[0] = uint64(_epochEndTimestamp);

        uint256[] memory _averageTotalSupplies = _ticket.getAverageTotalSuppliesBetween(
            _epochStartTimestamps,
            _epochEndTimestamps
        );

        return (_promotion.tokensPerEpoch * _averageBalance) / _averageTotalSupplies[0];
    }

    /**
        @notice Get the total amount of tokens left to be rewarded.
        @param _promotionId Promotion id to get the total amount of tokens left to be rewarded for
        @return Amount of tokens left to be rewarded
     */
    function _getRemainingRewards(uint256 _promotionId) internal view returns (uint256) {
        Promotion memory _promotion = _getPromotion(_promotionId);
        uint256 _numberOfEpochs = _promotion.numberOfEpochs;
        uint256 _tokensPerEpoch = _promotion.tokensPerEpoch;
        uint256 _currentEpochId = _getCurrentEpochId(_promotionId);

        if (_currentEpochId == 0) {
            return _tokensPerEpoch * _numberOfEpochs;
        } else if (_numberOfEpochs <= _currentEpochId + 1) {
            return 0;
        } else {
            // _tokensPerEpoch * _numberOfEpochsLeft
            return _tokensPerEpoch * (_numberOfEpochs - (_currentEpochId + 1));
        }
    }

    /**
        @notice Set boolean value for a specific epoch.
        @dev Bits are stored in a uint256 from right to left.
        Let's take the example of the following 8 bits word. 0110 0111
        To set the boolean value to 0 for the epoch id 2, we need to create a mask by shifting 1 to the left by 2 bits.
        We get: 0000 0001 << 2 = 0000 0100
        We then OR the mask with the word to set the value.
        We get: 0110 0111 | 0000 0100 = 0110 0111
        To set the boolean value to 0 for the epoch id 2, we need to create a mask by shifting 1 to the left by 2 bits and then inverting it.
        We get: 0000 0001 << 2 = ~(0000 0100) = 1111 1011
        We then AND the mask with the word to clear the value.
        We get: 0110 0111 & 1111 1011 = 0110 0011
        @param _epochs Tightly packed epoch ids with their boolean values
        @param _epochId Id of the epoch to set the boolean for
        @param _value Boolean value to set
        @return Tightly packed epoch ids with the newly boolean value set
    */
    function _setClaimedEpoch(
        uint256 _epochs,
        uint256 _epochId,
        bool _value
    ) public pure returns (uint256) {
        if (_value) {
            return _epochs | (uint256(1) << _epochId);
        } else {
            return _epochs & ~(uint256(1) << _epochId);
        }
    }

    /**
        @notice Get boolean for a specific epoch id.
        @dev Bits are stored in a uint256 from right to left.
        Let's take the example of the following 8 bits word. 0110 0111
        To retrieve the boolean value for the epoch id 2, we need to shift the word to the right by 2 bits.
        We get: 0110 0111 >> 2 = 0001 1001
        We then get the value of the last bit by masking with 1.
        We get: 0001 1001 & 0000 0001 = 0000 0001 = 1
        We then return the boolean value true since the last bit is 1.
        @param _epochs Tightly packed epoch ids with their boolean values
        @param _epochId Id of the epoch to get the boolean for
        @return true if the epoch has been claimed, false otherwise
    */
    function _getClaimedEpoch(uint256 _epochs, uint256 _epochId) internal pure returns (bool) {
        uint256 flag = (_epochs >> _epochId) & uint256(1);
        return (flag == 1 ? true : false);
    }

    /**
        @notice Check if rewards of an epoch for a given promotion have already been claimed by the user.
        @param _user Address of the user to check
        @param _promotionId Promotion id to check
        @param _epochId Epoch id to check
        @return true if the rewards have already been claimed for the given epoch, false otherwise
     */
    function _isClaimedEpoch(
        address _user,
        uint256 _promotionId,
        uint256 _epochId
    ) internal view returns (bool) {
        return _getClaimedEpoch(_claimedEpochs[_promotionId][_user], _epochId);
    }

    /**
        @notice Determine if current promotion is active.
        @param _promotionId Id of the promotion to check
        @return True if promotion is active, false otherwise
    */
    function _isPromotionActive(uint256 _promotionId) internal view returns (bool) {
        Promotion memory _promotion = _getPromotion(_promotionId);

        uint256 _promotionEndTimestamp = _promotion.startTimestamp +
            (_promotion.epochDuration * _promotion.numberOfEpochs);

        return _promotionEndTimestamp > 0 && _promotionEndTimestamp >= block.timestamp;
    }
}
