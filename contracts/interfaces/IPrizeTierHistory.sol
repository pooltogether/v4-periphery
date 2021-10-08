// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/DrawBeacon.sol";

/**
 * @title  PoolTogether V4 IPrizeTierHistory
 * @author PoolTogether Inc Team
 * @notice IPrizeTierHistory is the base contract for PrizeTierHistory
 */
interface IPrizeTierHistory {
    /**
     * @notice Linked Draw and PrizeDistribution parameters storage schema
     */
    struct PrizeTier {
        uint8 bitRangeSize;
        uint32 drawId;
        uint32 maxPicksPerUser;
        uint256 prize;
        uint32[16] tiers;
        uint32 validityDuration;
    }

    /**
     * @notice Emit when new PrizeTier is added to history
     * @param drawId    Draw ID
     * @param prizeTier PrizeTier parameters
     */
    event PrizeTierPushed(uint32 indexed drawId, PrizeTier prizeTier);

    /**
     * @notice Emit when existing PrizeTier is updated in history
     * @param drawId    Draw ID
     * @param prizeTier PrizeTier parameters
     */
    event PrizeTierSet(uint32 indexed drawId, PrizeTier prizeTier);

    /**
     * @notice Push PrizeTierHistory struct onto history array.
     * @dev    Callable only by owner or manager,
     * @param drawPrizeDistribution New PrizeTierHistory struct
     * @return drawId Draw ID linked to PrizeTierHistory
     */
    function push(PrizeTier calldata drawPrizeDistribution) external returns (uint32 drawId);

    /**
     * @notice Read PrizeTierHistory struct from history array.
     * @param drawId Draw ID
     * @return prizeTier
     */
    function getPrizeTier(uint32 drawId) external view returns (PrizeTier memory prizeTier);

    /**
     * @notice Read first Draw ID used to initialize history
     * @return Draw ID of first PrizeTier record
     */
    function getOldestDrawId() external view returns (uint32);

    function getNewestDrawId() external view returns (uint32);

    /**
     * @notice Read PrizeTierHistory List from history array.
     * @param drawIds Draw ID array
     * @return prizeTierList
     */
    function getPrizeTierList(uint32[] calldata drawIds)
        external
        view
        returns (PrizeTier[] memory prizeTierList);

    /**
     * @notice Push PrizeTierHistory struct onto history array.
     * @dev    Callable only by owner.
     * @param prizeTier Updated PrizeTierHistory struct
     * @return drawId Draw ID linked to PrizeTierHistory
     */
    // function setPrizeTier(PrizeTier calldata prizeTier) external returns (uint32 drawId);
}
