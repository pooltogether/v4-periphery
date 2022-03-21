// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 IdBinarySearchLib
 * @author PoolTogether Inc Team
 * @notice IdBinarySearchLib uses binary search to find a parent contract struct with the drawId parameter
 * @dev    The implementing contract must provider access to a struct (i.e. PrizeTier) list with is both
 *         sorted and indexed by the drawId field for binary search to work.
 */
library IdBinarySearchLib {

    /**
     * @notice Find ID in array of ordered IDs using Binary Search.
        * @param _history uin32[] - Array of IDsq
        * @param _drawId uint32 - Draw ID to search for
        * @return uint32 - Index of ID in array
     */
    function binarySearch(uint32[] memory _history, uint32 _drawId) external pure returns (uint32) {
        uint32 index;
        uint32 leftSide = 0;
        uint32 rightSide = uint32(_history.length - 1);

        uint32 oldestDrawId = _history[0];
        uint32 newestDrawId = _history[rightSide];

        require(_drawId >= oldestDrawId, "IdBinarySearchLib/draw-id-out-of-range");
        if (_drawId >= newestDrawId) return rightSide;
        if (_drawId == oldestDrawId) return leftSide;

        while (true) {
            uint32 length = rightSide - leftSide;
            uint32 center = leftSide + (length) / 2;
            uint32 centerID = _history[center];

            if (centerID == _drawId || length == 1) {
                index = center;
                break;
            }

            if (centerID < _drawId) {
                leftSide = center;
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
