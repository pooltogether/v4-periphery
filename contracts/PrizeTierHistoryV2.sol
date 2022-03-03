// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "./libraries/BinarySearchLib.sol";
import "./libraries/DrawBinarySearch.sol";

/**
 * @title  PoolTogether V4 PrizeTierHistoryV2
 * @author PoolTogether Inc Team
 * @notice PrizeTierHistoryV2 manages a history of PrizeTier parameters
 */
contract PrizeTierHistoryV2 is DrawBinarySearch {

    struct PrizeTier {
        uint8 bitRangeSize;
        uint32 drawId;
        uint32 maxPicksPerUser;
        uint32 expiryDuration;
        uint32 endTimestampOffset;
        uint256 prize;
        uint32[16] tiers;
        uint32 dpr;
    }

    PrizeTier[] internal history;

    function getNewestIndex() internal view override returns (uint32) {
        return uint32(history.length - 1);
    }

    function getDrawIdForIndex(uint index) internal view override returns (uint32) {
        return history[index].drawId;
    }

    function getPrizeTier(uint32 _drawId) external view returns (PrizeTier memory) {
        require(_drawId > 0, "PrizeTierHistory/draw-id-not-zero");
        return _getPrizeTier(_drawId);
    }

    function _getPrizeTier(uint32 _drawId) internal view returns (PrizeTier memory) {
        return history[_binarySearch(_drawId)];
    }
}
