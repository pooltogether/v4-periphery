// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

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
        @param epochDuration Duration of one epoch in seconds
     */
    struct Epoch {
        uint32 id;
        uint32 startTimestamp;
        uint32 epochDuration;
    }

    /**
        @notice Struct to keep track of each promotion's settings.
        @param id Promotion id to keep track of each promotion
        @param creator Addresss of the promotion creator
        @param token Address of the token to be distributed
        @param startTimestamp Timestamp at which the promotion starts
        @param epochDuration Duration of one epoch in seconds
        @param tokensPerEpoch Number of tokens to be distributed per epoch
        @param numberOfEpochs Number of epochs the promotion will last for
     */
    struct Promotion {
        uint32 id;
        address creator;
        address token;
        uint32 startTimestamp;
        uint32 epochDuration;
        uint256 tokensPerEpoch;
        uint256 numberOfEpochs;
    }

    /**
        @notice Parameters needed to create a promotion.
        @param token Address of the token to be distributed
        @param startTimestamp Timestamp at which the promotion starts
        @param epochDuration Duration of one epoch in seconds
        @param tokensPerEpoch Number of tokens to be distributed per epoch
        @param numberOfEpochs Number of epochs the promotion will last for
     */
    struct PromotionParameters {
        address token;
        uint32 startTimestamp;
        uint32 epochDuration;
        uint256 tokensPerEpoch;
        uint256 numberOfEpochs;
    }

    /**
        @notice Create a new promotion.
        @dev Will revert if a promotion is already active.
        @param _ticket Prize Pool ticket address for which the promotion is created
        @param _promotion Promotion parameters
        @return true if the creation was successful
    */
    function createPromotion(
        address _ticket,
        PromotionParameters calldata _promotion
    ) external returns (bool);

    /**
        @notice Cancel currently active promotion and send promotion tokens back to the creator.
        @return true if cancelation was successful
     */
    function cancelPromotion() external returns (bool);

    /**
        @notice Extend promotion by adding more epochs.
        @param _numberOfEpochs Number of epochs to add
        @return true if the operation was successful
     */
    function extendPromotion(uint256 _numberOfEpochs) external returns (bool);

    /**
        @notice Claim rewards for a given epoch.
        @dev Rewards can be claimed on behalf of a user
        @param _user Address of the user to claim rewards for
        @param _epochId Epoch number to claim rewards for
        @return Amount of rewards claimed
     */
    function claimReward(address _user, uint32 _epochId) external returns (uint256);

    /**
        @notice Claim rewards from all epochs for a user.
        @dev Rewards can be claimed on behalf of a user
        @param _user Address of the user to claim rewards for
        @return Amount of rewards claimed
     */
    function claimAllRewards(address _user) external returns (uint256);

    /**
        @notice Check if a user has claimed rewards for a given epoch.
        @param _user Address of the user to check claim for
        @param _epochId Epoch number to check claim for
        @return true if the user has claimed rewards for the given epoch
     */
    function isClaimed(address _user, uint32 _epochId) external view returns (bool);

    /**
        @notice Get the total amount of tokens left to be rewarded.
        @return Amount of tokens left to be rewarded
     */
    function getRemainingBalance() external view returns (uint256);

    /**
        @notice Get the duration of an epoch in seconds.
        @return Duration of an epoch in seconds
     */
    function getEpochDuration() external view returns (uint32);

    /**
        @notice Get the current promotion settings.
        @return Promotion settings
     */
    function getCurrentPromotion() external view returns (Promotion calldata);

    /**
        @notice Get settings for a specific promotion.
        @param _promotionId Promotion number to get settings for
        @return Promotion settings
     */
    function getPromotion(uint32 _promotionId) external view returns (Promotion calldata);

    /**
        @notice Get the current epoch settings.
        @return Epoch settings
     */
    function getCurrentEpoch() external view returns (Epoch calldata);

    /**
        @notice Get settings for a specific epoch.
        @param _epochId Epoch number to get settings for
        @return Epoch settings
     */
    function getEpoch(uint32 _epochId) external view returns (Epoch calldata);

    /**
        @notice Get amount of tokens to be rewarded for a given epoch.
        @param _user Address of the user to get information about a reward for
        @param _epochId Epoch number to get information for
        @return Amount of tokens to be rewarded
     */
    function getRewardInfo(address _user, uint32 _epochId) external view returns (uint256);

    /**
        @notice Get amount of tokens to be rewarded for all past epochs.
        @param _user Address of the user to get information about rewards for
        @return Amount of tokens to be rewarded
     */
    function getAllRewardsInfo(address _user) external view returns (uint256);
}
