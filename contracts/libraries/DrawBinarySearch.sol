// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 DrawBinarySearch
 * @author PoolTogether Inc Team
 * @notice DrawBinarySearch handles finding a historical Draw ID references
 */

abstract contract DrawBinarySearch {

    function getNewestIndex() internal view virtual returns (uint32);

    function getDrawIdForIndex(uint index) internal view virtual returns (uint32);

    function _binarySearch(uint32 _drawId) internal view returns (uint32) {
        uint32 index;
        uint32 leftSide = 0;
        uint32 rightSide = getNewestIndex();
        while (true) {
            uint32 center = leftSide + (rightSide - leftSide) / 2;
            uint32 centerID = getDrawIdForIndex(center);

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
