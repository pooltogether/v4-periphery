// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/v4-core/contracts/interfaces/ITicket.sol";

/**
 * @title  PoolTogether V4 ITwabRewards
 * @author PoolTogether Inc Team
 * @notice TwabRewards contract interface.
 */
interface ITwabRewards {
    /**
        @notice Struct to keep track of each epoch's settings.
        @param id Epoch id to keep track of each epoch
        @param startTimestamp Timestamp at which the epoch starts
        @param duration Duration of one epoch in seconds
     */
    struct Epoch {
        uint32 id;
        uint32 startTimestamp;
        uint32 duration;
    }

    /**
        @notice Struct to keep track of each promotion's settings.
        @param id Promotion id to keep track of each promotion
        @param creator Addresss of the promotion creator
        @param ticket Prize Pool ticket address for which the promotion has been created
        @param token Address of the token to be distributed as reward
        @param tokensPerEpoch Number of tokens to be distributed per epoch
        @param startTimestamp Timestamp at which the promotion starts
        @param epochDuration Duration of one epoch in seconds
        @param numberOfEpochs Number of epochs the promotion will last for
     */
    struct Promotion {
        uint32 id;
        address creator;
        address ticket;
        address token;
        uint256 tokensPerEpoch;
        uint32 startTimestamp;
        uint32 epochDuration;
        uint256 numberOfEpochs;
    }

    /**
        @notice Parameters needed to create a promotion.
        @param token Address of the token to be distributed
        @param tokensPerEpoch Number of tokens to be distributed per epoch
        @param startTimestamp Timestamp at which the promotion starts
        @param epochDuration Duration of one epoch in seconds
        @param numberOfEpochs Number of epochs the promotion will last for
     */
    struct PromotionParameters {
        address token;
        uint256 tokensPerEpoch;
        uint32 startTimestamp;
        uint32 epochDuration;
        uint256 numberOfEpochs;
    }

    /**
        @notice Create a new promotion.
        @dev Will revert if a promotion is already active.
        @dev For sake of simplicity, `msg.sender` will be the creator of the promotion.
        @param _ticket Prize Pool ticket address for which the promotion is created
        @param _promotionParameters Parameters needed to create a promotion
        @return Id of the newly created promotion
    */
    function createPromotion(address _ticket, PromotionParameters calldata _promotionParameters)
        external
        returns (uint256);

    /**
        @notice Cancel currently active promotion and send promotion tokens back to the creator.
        @param _promotionId Promotion id to cancel
        @param _to Address that will receive the remaining tokens if there are any left
        @return true if cancelation was successful
     */
    function cancelPromotion(uint256 _promotionId, address _to) external returns (bool);

    /**
        @notice Extend promotion by adding more epochs.
        @param _promotionId Promotion id to extend
        @param _numberOfEpochs Number of epochs to add
        @return true if the operation was successful
     */
    function extendPromotion(uint256 _promotionId, uint256 _numberOfEpochs) external returns (bool);

    /**
        @notice Claim rewards for a given promotion and epoch.
        @dev Rewards can be claimed on behalf of a user.
        @dev Rewards can only be claimed for a past epoch.
        @dev Caller may want to claim full or partial `amount` of rewards.
        @param _user Address of the user to claim rewards for
        @param _promotionId Promotion id to claim rewards for
        @param _epochId Epoch id to claim rewards for
        @param _amount Amount of tokens to claim
        @return Amount of rewards claimed
     */
    function claimRewards(
        address _user,
        uint256 _promotionId,
        uint256 _epochId,
        uint256 _amount
    ) external returns (uint256);

    /**
        @notice Claim rewards from all epochs for a user.
        @dev Rewards can be claimed on behalf of a user
        @param _user Address of the user to claim rewards for
        @return Amount of rewards claimed
     */
    // function claimAllRewards(address _user) external returns (uint256);

    /**
        @notice Get settings for a specific promotion.
        @param _promotionId Promotion id to get settings for
        @return Promotion settings
     */
    function getPromotion(uint256 _promotionId) external view returns (Promotion memory);

    /**
        @notice Get the total amount of tokens left to be rewarded.
        @param _promotionId Promotion id to get the total amount of tokens left to be rewarded for
        @return Amount of tokens left to be rewarded
     */
    function getRemainingRewards(uint256 _promotionId) external view returns (uint256);

    /**
        @notice Get the current epoch settings.
        @param _promotionId Promotion id to get current epoch for
        @return Epoch settings
     */
    function getCurrentEpoch(uint256 _promotionId) external view returns (Epoch memory);

    /**
        @notice Get settings for a specific epoch.
        @param _epochId Epoch id to get settings for
        @param _promotionId Promotion id from which the epoch is
        @return Epoch settings
     */
    function getEpoch(uint256 _epochId, uint256 _promotionId) external view returns (Epoch memory);

    /**
        @notice Get amount of tokens to be rewarded for a given epoch.
        @dev Will be 0 if user has already claimed rewards for the epoch.
        @param _user Address of the user to get amount of rewards for
        @param _promotionId Promotion id from which the epoch is
        @param _epochId Epoch id to get information for
        @return Amount of tokens to be rewarded
     */
    function getRewardAmount(
        address _user,
        uint256 _promotionId,
        uint256 _epochId
    ) external view returns (uint256);

    /**
        @notice Get amount of tokens to be rewarded for all past epochs.
        @param _user Address of the user to get information about rewards for
        @return Amount of tokens to be rewarded
     */
    // function getAllRewardsAmount(address _user) external view returns (uint256);
}
