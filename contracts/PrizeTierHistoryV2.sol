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

    function getPrizeTier(uint32 _drawId) external view returns (PrizeTier memory) {
        require(_drawId > 0, "PrizeTierHistory/draw-id-not-zero");
        return _getPrizeTier(_drawId);
    }

    function _getPrizeTier(uint32 _drawId) internal view returns (PrizeTier memory) {
        return history[0];
    }
}

/**
 * @title  PoolTogether V4 PrizeTierHistoryUsingLibV2
 * @author PoolTogether Inc Team
 * @notice PrizeTierHistoryV2 manages a history of PrizeTier parameters
 */
 contract PrizeTierHistoryUsingLibV2 {
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

    function getPrizeTier(uint32 _drawId) external view returns (PrizeTier memory) {
        require(_drawId > 0, "PrizeTierHistory/draw-id-not-zero");
        return _getPrizeTier(_drawId);
    }

    function _getPrizeTier(uint32 _drawId) internal view returns (PrizeTier memory) {
        uint32 cardinality = uint32(history.length);
        require(cardinality > 0, "PrizeTierHistory/no-prize-tiers");

        uint32 leftSide = 0;
        uint32 rightSide = cardinality - 1;
        uint32 oldestDrawId = history[leftSide].drawId;
        uint32 newestDrawId = history[rightSide].drawId;

        require(_drawId >= oldestDrawId, "PrizeTierHistory/draw-id-out-of-range");
        if (_drawId >= newestDrawId) return history[rightSide];
        if (_drawId == oldestDrawId) return history[leftSide];

        uint32[] memory _history = new uint32[](cardinality);
        
        for (uint256 index = 0; index < _history.length; index++) {
            _history[index] = history[index].drawId;
        }

        uint32 i = BinarySearchLib._binarySearch(_drawId, leftSide, rightSide, _history);
        return history[i];
    }
}
