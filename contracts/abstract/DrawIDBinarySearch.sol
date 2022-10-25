// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 DrawIDBinarySearch
 * @author PoolTogether Inc Team
 * @notice DrawIDBinarySearch uses binary search to find a parent contract struct with the drawId parameter
 * @dev    The implementing contract must provider access to a struct (i.e. PrizeTier) list with is both
 *         sorted and indexed by the drawId field for binary search to work.
 */
abstract contract DrawIDBinarySearch {
    /**
     * @notice Get newest index in array
     */
    function getNewestIndex() internal view virtual returns (uint32);

    /**
     * @notice Get Draw ID for using an index position
     * @param index uint256 - Index of element in array
     */
    function getDrawIdForIndex(uint256 index) internal view virtual returns (uint32);

    function _binarySearch(uint32 _drawId) internal view returns (uint32) {
        uint32 index;
        uint32 leftSide = 0;
        uint32 rightSide = getNewestIndex();

        uint32 oldestDrawId = getDrawIdForIndex(leftSide);
        uint32 newestDrawId = getDrawIdForIndex(rightSide);

        require(_drawId >= oldestDrawId, "PrizeTierHistoryV2/draw-id-out-of-range");
        if (_drawId >= newestDrawId) return rightSide;
        if (_drawId == oldestDrawId) return leftSide;

        while (true) {
            uint32 length = rightSide - leftSide;
            uint32 center = leftSide + (length) / 2;
            uint32 centerID = getDrawIdForIndex(center);

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
