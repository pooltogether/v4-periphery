// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/DrawBeacon.sol";

/**
 * @title  PoolTogether V4 IPrizeTierHistoryV2
 * @author PoolTogether Inc Team
 * @notice IPrizeTierHistoryV2 is the base contract for PrizeTierHistoryV2
 */
interface IPrizeTierHistoryV2 {
    /**
     * @notice PrizeTierV2 struct
     * @dev    Adds the DPR paramater to the PrizeTierStructV1
    */
    struct PrizeTierV2 {
        uint8 bitRangeSize;
        uint32 drawId;
        uint32 maxPicksPerUser;
        uint32 expiryDuration;
        uint32 endTimestampOffset;
        uint256 prize;
        uint32[16] tiers;
        uint32 dpr;
        // @TODO add minPickCost to the new PrizeTierHistoryV2? Semi-linked to DPR
    }

    /* =================================================== */
    /* Events ============================================ */
    /* =================================================== */

    /**
     * @notice Emit when new PrizeTierV2 is added to history
     * @param drawId    Draw ID
     * @param prizeTier PrizeTierV2 parameters
     */
     event PrizeTierPushed(uint32 indexed drawId, PrizeTierV2 prizeTier);

     /**
      * @notice Emit when existing PrizeTierV2 is updated in history
      * @param drawId    Draw ID
      * @param prizeTier PrizeTierV2 parameters
      */
     event PrizeTierSet(uint32 indexed drawId, PrizeTierV2 prizeTier);

    /* =================================================== */
    /* Functions ========================================= */
    /* =================================================== */

    /**
     * @notice Read oldest Draw ID in history array
     */
    function getOldestDrawId() external view returns (uint32);

    /**
     * @notice Read newest Draw ID in history array
     */
    function getNewestDrawId() external view returns (uint32);

    /**
     * @notice Read PrizeTierV2 struct using Draw ID as the input
     * @param drawId uint32 - Draw ID
     * @return prizeTier PrizeTierV2 - Parameters to calculate PrizeDistrubtion
     */
    function getPrizeTier(uint32 drawId) external view returns (PrizeTierV2 memory prizeTier);

    /**
     * @notice Read PrizeTierV2 struct using Draw ID as the input
     * @param drawIds uint32[] - Draw ID
     * @return prizeTierList PrizeTierV2[] - Parameters to calculate PrizeDistrubtion
     */
    function getPrizeTierList(uint32[] calldata drawIds)
        external
        view
        returns (PrizeTierV2[] memory prizeTierList);
}