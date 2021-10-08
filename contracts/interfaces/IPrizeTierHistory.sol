// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/DrawBeacon.sol";

/**
  * @title  PoolTogether V4 IPrizeTierHistory
  * @author PoolTogether Inc Team
  * @notice IPrizeTierHistory is the base contract for PrizeTierHistory
*/
interface IPrizeTierHistory {

    struct DrawPrizeDistribution {
      uint8  drawId;
      uint256 prize;
      uint32 validityDuration;
      uint32 drawStart;
    }

    struct PrizeTierDefaults {
      uint8 bitRangeSize;
      uint32 maxPicksPerUser;
      uint32[16] tiers;
      uint32 prizeExpirationSeconds;
    }

    struct PrizeTier {
      uint8 bitRangeSize;
      uint32 drawId;
      uint32 maxPicksPerUser;
      uint32[16] tiers;
      uint32 validityDuration;
      uint256 prize;
    }

    event PrizeTierPushed(
      uint32 indexed drawId,
      PrizeTier prizeTier
    );
    
    event PrizeTierSet(
      uint32 indexed drawId,
      uint32 idx,
      PrizeTier prizeTier
    );

    event PrizeTierDefaultsSet (
      PrizeTierDefaults defaults
    );

    /**
      * @notice Push PrizeTierHistory struct onto history array.
      * @dev    Callable only by owner or manager,
      * @param drawPrizeDistribution New PrizeTierHistory struct
      * @return drawId Draw ID linked to PrizeTierHistory
    */
    function push(DrawPrizeDistribution calldata drawPrizeDistribution) external returns (uint32 drawId);
    
    /**
      * @notice Read PrizeTierHistory struct from history array.
      * @param drawId Draw ID
      * @return prizeTier
    */
    function getPrizeTier(uint32 drawId) external view returns (PrizeTier memory prizeTier);

    function getDefaults() external view returns (PrizeTierDefaults memory);

    function getStartingDrawId() external view returns (uint32);
    
    /**
      * @notice Read PrizeTierHistory struct from history array.
      * @param drawIds Draw ID array
      * @return prizeTierList
    */
    function getPrizeTierList(uint32[] calldata drawIds) external view returns (PrizeTier[] memory prizeTierList);

    /**
      * @notice Push PrizeTierHistory struct onto history array.
      * @dev    Callable only by owner.
      * @param prizeTier Updated PrizeTierHistory struct
      * @return drawId Draw ID linked to PrizeTierHistory
    */
    function setPrizeTier(PrizeTier calldata prizeTier) external returns (uint32 drawId);

    /**
      * @notice Set PrizeTierDefaults parameters
      * @param defaults Defaults for PrizeTier
    */
    function setDefaults(PrizeTierDefaults calldata defaults) external;

}