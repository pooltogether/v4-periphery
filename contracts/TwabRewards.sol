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
    uint256 internal _currentPromotionId;

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
    modifier onlyPromotionCreator() {
        require(msg.sender == _getCurrentPromotion().creator, "TwabRewards/only-promotion-creator");
        _;
    }

    /* ============ External Functions ============ */

    /// @inheritdoc ITwabRewards
    function createPromotion(address _ticket, PromotionParameters calldata _promotionParameters)
        external
        override
        returns (uint256)
    {
        require(_isPromotionActive() == false, "TwabRewards/promotion-already-active");

        _requireTicket(_ticket);

        uint256 _nextPromotionId = _currentPromotionId + 1;
        _currentPromotionId = _nextPromotionId;

        address _token = _promotionParameters.token;
        uint256 _tokensPerEpoch = _promotionParameters.tokensPerEpoch;
        uint256 _numberOfEpochs = _promotionParameters.numberOfEpochs;

        IERC20(_token).safeTransfer(address(this), _tokensPerEpoch * _numberOfEpochs);

        Promotion memory _nextPromotion = Promotion(
            uint32(_nextPromotionId),
            false,
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
    function cancelPromotion(address _to) external override onlyPromotionCreator returns (bool) {
        require(_isPromotionActive() == true, "TwabRewards/no-active-promotion");
        require(_to != address(0), "TwabRewards/recipient-not-zero-address");

        Promotion memory _currentPromotion = _getCurrentPromotion();

        IERC20 _token = IERC20(_currentPromotion.token);
        uint256 _remainingRewards = _getRemainingRewards(_token);

        if (_remainingRewards > 0) {
            _token.safeTransfer(_to, _remainingRewards);
        }

        _promotions[_currentPromotion.id].cancelled = true;

        return true;
    }

    /// @inheritdoc ITwabRewards
    function extendPromotion(uint256 _numberOfEpochs) external override onlyPromotionCreator returns (bool) {
        require(_isPromotionActive() == true, "TwabRewards/no-active-promotion");

        Promotion memory _currentPromotion = _getCurrentPromotion();

        IERC20(_currentPromotion.token).safeTransfer(
            address(this),
            _numberOfEpochs * _currentPromotion.tokensPerEpoch
        );

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

    /// @inheritdoc ITwabRewards
    function getRemainingRewards() external view override returns (uint256) {
        return _getRemainingRewards(IERC20(_getCurrentPromotion().token));
    }

    /// @inheritdoc ITwabRewards
    function getCurrentEpoch() external view override returns (Epoch memory) {
        return _getCurrentEpoch();
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
        @param _promotionId Promotion id to get settings for
        @return Promotion settings
     */
    function _getPromotion(uint256 _promotionId) internal view returns (Promotion memory) {
        return _promotions[_promotionId];
    }

    /**
        @notice Get current promotion settings.
        @dev This promotion can be inactive if the promotion period is over.
        @return Promotion settings
     */
    function _getCurrentPromotion() internal view returns (Promotion memory) {
        return _getPromotion(_currentPromotionId);
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
        @return Epoch settings
     */
    function _getCurrentEpoch() internal view returns (Epoch memory) {
        Promotion memory _currentPromotion = _getCurrentPromotion();
        uint256 _numberOfEpochs = _currentPromotion.numberOfEpochs;

        uint256 _promotionEndTimestamp = _currentPromotion.startTimestamp +
            (_currentPromotion.epochDuration * _numberOfEpochs);
        uint256 _currentEpochId = (_numberOfEpochs / block.timestamp) * _promotionEndTimestamp;

        return _getEpoch(_currentEpochId, _currentPromotion);
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

        /// User's share of tickets expressed in percentage
        uint256 shareOfTickets = (_averageBalance * 100) / _averageTotalSupply;

        return (_promotion.tokensPerEpoch * shareOfTickets) / 100;
    }

    /**
        @notice Get the total amount of tokens left to be rewarded.
        @param _token Address of the token distributed as reward
        @return Amount of tokens left to be rewarded
     */
    function _getRemainingRewards(IERC20 _token) internal view returns (uint256) {
        return _token.balanceOf(address(this));
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
        @return True if promotion is active, false otherwise
    */
    function _isPromotionActive() internal view returns (bool) {
        Promotion memory _currentPromotion = _getCurrentPromotion();

        uint256 _promotionEndTimestamp = _currentPromotion.startTimestamp +
            (_currentPromotion.epochDuration * _currentPromotion.numberOfEpochs);

        return
            !_currentPromotion.cancelled &&
            _promotionEndTimestamp > 0 &&
            _promotionEndTimestamp >= block.timestamp;
    }
}