// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/v4-core/contracts/interfaces/ITicket.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/ITwabRewards.sol";

/**
 * @title PoolTogether V4 TwabRewards
 * @author PoolTogether Inc Team
 * @notice Contract to distribute rewards to depositors in a pool.
 */
contract TwabRewards is ITwabRewards, Manageable {
    using SafeERC20 for IERC20;

    /* ============ Global Variables ============ */

    /// @notice Settings of each promotion.
    mapping(uint256 => Promotion) internal _promotions;

    /// @notice Current promotion id.
    uint256 internal _latestPromotionId;

    /// @notice Keeps track of claimed rewards per user.
    /// @dev _claimedRewards[promotionId][epochId][user] => uint256
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) internal _claimedRewards;

    /* ============ Events ============ */

    /**
        @notice Emitted when contract has been deployed.
        @param owner Contract owner address
   */
    event Deployed(address owner);

    /**
        @notice Emmited when a promotion is created.
        @param id Id of the newly created promotion
    */
    event PromotionCreated(uint256 id);

    /**
        @notice Emmited when a promotion is extended.
        @param token Address of the token used in the promotion
        @param amount Amount of tokens transferred to the rewards contract
    */
    event PromotionCancelled(IERC20 token, uint256 amount);

    /**
        @notice Emmited when a promotion is extended.
        @param token Address of the token used in the promotion
        @param amount Amount of tokens transferred to the recipient address
    */
    event PromotionExtended(IERC20 token, uint256 amount);

    /* ============ Constructor ============ */

    /**
        @notice Deploy TwabRewards contract.
        @param _owner Contract owner address
    */
    constructor(address _owner) Ownable(_owner) {
        emit Deployed(_owner);
    }

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
    function createPromotion(address _ticket, PromotionParameters calldata _promotionParameters)
        external
        override
        returns (uint256)
    {
        _requireTicket(_ticket);

        uint256 _nextPromotionId = _latestPromotionId + 1;
        _latestPromotionId = _nextPromotionId;

        address _token = _promotionParameters.token;
        uint256 _tokensPerEpoch = _promotionParameters.tokensPerEpoch;
        uint256 _numberOfEpochs = _promotionParameters.numberOfEpochs;

        IERC20(_token).safeTransfer(address(this), _tokensPerEpoch * _numberOfEpochs);

        Promotion memory _nextPromotion = Promotion(
            uint32(_nextPromotionId),
            msg.sender,
            _ticket,
            _token,
            _tokensPerEpoch,
            _promotionParameters.startTimestamp,
            _promotionParameters.epochDuration,
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

        delete _promotions[_promotion.id];

        emit PromotionCancelled(_token, _remainingRewards);

        return true;
    }

    /// @inheritdoc ITwabRewards
    function extendPromotion(uint256 _promotionId, uint256 _numberOfEpochs)
        external
        override
        onlyPromotionCreator(_promotionId)
        returns (bool)
    {
        require(_isPromotionActive(_promotionId) == true, "TwabRewards/promotion-not-active");

        Promotion memory _promotion = _getPromotion(_promotionId);
        IERC20 _token = IERC20(_promotion.token);
        uint256 _amount = _numberOfEpochs * _promotion.tokensPerEpoch;

        _token.safeTransfer(address(this), _amount);

        emit PromotionExtended(_token, _amount);

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
    function getCurrentEpoch(uint256 _promotionId) external view override returns (Epoch memory) {
        return _getCurrentEpoch(_promotionId);
    }

    /// @inheritdoc ITwabRewards
    function getEpoch(uint256 _epochId, uint256 _promotionId)
        external
        view
        override
        returns (Epoch memory)
    {
        Promotion memory _promotion = _getPromotion(_promotionId);

        return _getEpoch(_epochId, _promotion);
    }

    /// @inheritdoc ITwabRewards
    function getRewardAmount(
        address _user,
        uint256 _promotionId,
        uint256 _epochId
    ) external view override returns (uint256) {
        return _getRewardAmount(_user, _promotionId, _epochId);
    }

    /// @inheritdoc ITwabRewards
    function claimRewards(
        address _user,
        uint256 _promotionId,
        uint256 _epochId,
        uint256 _amount
    ) external override returns (uint256) {
        uint256 _rewardAmount = _getRewardAmount(_user, _promotionId, _epochId);

        require(_amount <= _rewardAmount, "TwabRewards/rewards-claim-too-high");

        IERC20(_getPromotion(_promotionId).token).safeTransferFrom(address(this), _user, _amount);

        return _amount;
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
        @notice Get settings for a specific promotion.
        @dev Will revert if the promotion does not exist.
        @param _promotionId Promotion id to get settings for
        @return Promotion settings
     */
    function _getPromotion(uint256 _promotionId) internal view returns (Promotion memory) {
        return _promotions[_promotionId];
    }

    /**
        @notice Get settings for a specific epoch.
        @param _epochId Epoch id to get settings for
        @param _promotion Promotion settings
        @return Epoch settings
     */
    function _getEpoch(uint256 _epochId, Promotion memory _promotion)
        internal
        pure
        returns (Epoch memory)
    {
        uint256 _epochDuration = _promotion.epochDuration;

        return
            Epoch({
                id: uint32(_epochId),
                startTimestamp: uint32(_promotion.startTimestamp + (_epochDuration * _epochId)),
                duration: uint32(_epochDuration)
            });
    }

    /**
        @notice Get current epoch settings.
        @param _promotionId Id of the promotion to get current epoch for
        @return Epoch settings
     */
    function _getCurrentEpoch(uint256 _promotionId) internal view returns (Epoch memory) {
        Promotion memory _promotion = _getPromotion(_promotionId);
        uint256 _numberOfEpochs = _promotion.numberOfEpochs;

        uint256 _promotionEndTimestamp = _promotion.startTimestamp +
            (_promotion.epochDuration * _numberOfEpochs);
        uint256 _currentEpochId = (_numberOfEpochs / block.timestamp) * _promotionEndTimestamp;

        return _getEpoch(_currentEpochId, _promotion);
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
        Epoch memory _epoch = _getEpoch(_epochId, _promotion);

        uint256 _epochDuration = _epoch.duration;
        uint256 _epochStartTimestamp = _epoch.startTimestamp;
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

        uint256 _averageTotalSupply = _averageTotalSupplies[0];

        return (_promotion.tokensPerEpoch * _averageBalance) / _averageTotalSupply;
    }

    /**
        @notice Get the total amount of tokens left to be rewarded.
        @param _promotionId Promotion id to get the total amount of tokens left to be rewarded for
        @return Amount of tokens left to be rewarded
     */
    function _getRemainingRewards(uint256 _promotionId) internal view returns (uint256) {
        return IERC20(_getPromotion(_promotionId).token).balanceOf(address(this));
    }

    /**
        @notice Get the amount of rewards already claimed by the user for a given promotion and epoch.
        @param _user Address of the user to check claimed rewards for
        @param _promotionId Epoch id to check claimed rewards for
        @param _epochId Epoch id to check claimed rewards for
        @return Amount of tokens already claimed by the user
     */
    function _getClaimedRewards(
        address _user,
        uint256 _promotionId,
        uint256 _epochId
    ) internal view returns (uint256) {
        return _claimedRewards[_promotionId][_epochId][_user];
    }

    /**
        @notice Get amount of tokens to be rewarded for a given epoch.
        @dev Will be 0 if user has already claimed rewards for the epoch.
        @param _user Address of the user to get amount of rewards for
        @param _promotionId Promotion id from which the epoch is
        @param _epochId Epoch id to get amount of rewards for
        @return Amount of tokens to be rewarded
     */
    function _getRewardAmount(
        address _user,
        uint256 _promotionId,
        uint256 _epochId
    ) internal view returns (uint256) {
        return
            _calculateRewardAmount(_user, _promotionId, _epochId) -
            _getClaimedRewards(_user, _promotionId, _epochId);
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
