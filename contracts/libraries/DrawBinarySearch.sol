// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 DrawBinarySearch
 * @author PoolTogether Inc Team
 * @notice DrawBinarySearch handles finding a historical Draw ID references
 */

contract DrawBinarySearch {
    
    function _binarySearch(
        uint32 _drawId,
        uint32 leftSide,
        uint32 rightSide,
        uint32[] memory _history
    ) internal pure returns (uint32) {
        return _history[_binarySearchIndex(_drawId, leftSide, rightSide, _history)];
    }

    function _binarySearchIndex(
        uint32 _drawId,
        uint32 _leftSide,
        uint32 _rightSide,
        uint32[] memory _history
    ) internal pure returns (uint32) {
        uint32 index;
        uint32 leftSide = _leftSide;
        uint32 rightSide = _rightSide;
        while (true) {
            uint32 center = leftSide + (rightSide - leftSide) / 2;
            uint32 centerID = _history[center];

            if (centerID == _drawId) {
                index = center;
                break;
            }

            if (centerID < _drawId) {
                leftSide = center + 1;
            } else if (centerID > _drawId) {
                rightSide = center - 1;
            }

            if (leftSide == rightSide) {
                if (centerID >= _drawId) {
                    index = center - 1;
                    break;
                } else {
                    index = center;
                    break;
                }
            }
        }
        return index;
    }
}
