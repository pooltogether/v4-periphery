// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 IDBinarySearch
 * @author PoolTogether Inc Team
 * @notice IDBinarySearch creates a binary search tree for ID values in ordered list
           Developed as a prototype for simple lookups using just a Draw ID
 */

contract IDBinarySearch {
    uint32[] internal idHistory;

    /**
     * @notice constructor
     @ @dev When initializing the IDBinarySearch, a ID history can be injected into the contract state.
            Injecting history allows the protocol to stay modular in case of updates to the ID history instance in other contracts.
     * @param _idHistoryInject uint32[] - Inject a historical DrawID reference history
     */
    constructor(uint32[] memory _idHistoryInject) {
        idHistory = _idHistoryInject;
    }

    function push(uint32 drawId) public {
        idHistory.push(drawId);
    }

    function getNewestIndex() external view returns (uint32) {
        return _getNewestIndex(idHistory);
    }

    /* =================================================== */
    /* Internal ========================================== */
    /* =================================================== */

    function _getIndexForDrawId(uint32 _drawId) internal view returns (uint256) {
        return _binarySearchWithRangeChecks(_drawId, idHistory);
    }

    function _getNewestIndex(uint32[] memory _idHistory) internal pure returns (uint32) {
        return _idHistory[_idHistory.length - 1];
    }

    function _binarySearchWithRangeChecks(uint32 _drawId, uint32[] memory _history)
        internal
        view
        returns (uint32)
    {
        uint32[] memory _idHistory = _history;

        uint32 cardinality = uint32(_idHistory.length);
        require(cardinality > 0, "IDBinarySearch/no-prize-tiers");

        uint32 leftSide = 0;
        uint32 rightSide = cardinality - 1;
        uint32 oldestDrawId = _idHistory[leftSide];
        uint32 newestDrawId = _idHistory[rightSide];

        require(_drawId >= oldestDrawId, "IDBinarySearch/draw-id-out-of-range");
        if (_drawId >= newestDrawId) return _idHistory[rightSide];
        if (_drawId == oldestDrawId) return _idHistory[leftSide];
        return _binarySearch(_drawId, leftSide, rightSide, _idHistory);
    }

    function _binarySearch(
        uint32 _drawId,
        uint32 leftSide,
        uint32 rightSide,
        uint32[] memory _history
    ) internal view returns (uint32) {
        return idHistory[_binarySearchIndex(_drawId, leftSide, rightSide, _history)];
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
