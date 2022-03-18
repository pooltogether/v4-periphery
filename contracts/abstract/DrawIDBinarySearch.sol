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
}
