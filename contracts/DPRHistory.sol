// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "./libraries/IDBinarySearch.sol";

/**
 * @title  PoolTogether V4 DPRHistory
 * @author PoolTogether Inc Team
 * @notice DPRHistory stores a list of historical draw percentage rate checkpoints.
 */

contract DPRHistory is IDBinarySearch {
    uint256[] internal history;

    /**
     * @dev Constructor
     */
    constructor(uint32[] memory _history) IDBinarySearch(_history) {
        history = new uint256[](0);
    }

    function getDpr(uint32 drawId) external view returns (uint256) {
        require(drawId > 0, "DPRHistory/draw-id-not-zero");
        return history[_getIndexForDrawId(drawId)];
    }

    /**
     * @notice Push a new draw percentage rate checkpoint to the history.
     * @param drawId uint32 - The draw id
     * @param nextDpr uint256 - The draw percentage rate
     */
    function push(uint32 drawId, uint256 nextDpr) external {
        history.push(nextDpr);
        super.push(drawId);
    }
}
