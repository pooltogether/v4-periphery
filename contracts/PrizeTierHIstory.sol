// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IPrizeTierHistory.sol";

import "hardhat/console.sol";

/**
 * @title  PoolTogether V4 IPrizeTierHistory
 * @author PoolTogether Inc Team
 * @notice IPrizeTierHistory is the base contract for PrizeTierHistory
 */
contract PrizeTierHistory is IPrizeTierHistory, Manageable {
    /* ============ Global Variables ============ */
    /**
      * @notice The Draw ID used to initialize the history.
      * @dev    Start Draw ID is SSTOREd and used as a reference for searches/lookups.
                The start Draw ID can be used to calculate the relative position of any PrizeTier
                using a Draw ID if the starting Draw ID is known.
     */
    uint32 internal startDrawId;

    /**
     * @notice Default PrizeTiers
     */
    // PrizeTierDefaults internal defaults;

    /**
     * @notice History of PrizeTier updates
     */
    PrizeTier[] internal history;

    /* ============ Constructor ============ */

    constructor(address _owner) Ownable(_owner) {}

    /* ============ External Functions ============ */

    // @inheritdoc IPrizeTierHistory
    function push(PrizeTier calldata _nextPrizeTier)
        external
        override
        onlyManagerOrOwner
        returns (uint32)
    {
        PrizeTier[] memory _history = history;

        if (_history.length > 0) {
            // READ the newest PrizeTier struct
            PrizeTier memory _newestPrizeTier = history[history.length - 1];
            // New PrizeTier ID must only be 1 greater than the last PrizeTier ID.
            require(
                _nextPrizeTier.drawId > _newestPrizeTier.drawId,
                "PrizeTierHistory/non-sequential-prize-tier"
            );
        }

        history.push(_nextPrizeTier);

        emit PrizeTierPushed(_nextPrizeTier.drawId, _nextPrizeTier);
    }

    /* ============ Setter Functions ============ */

    // @inheritdoc IPrizeTierHistory
    // function setPrizeTier(PrizeTier calldata _prizeTier) external override onlyOwner returns (uint32) {
    //   require(startDrawId > 0, "PrizeTierHistory/history-empty");
    //   uint32 _idx = _prizeTier.drawId - startDrawId;
    //   history[_idx] = _prizeTier;
    //   emit PrizeTierSet(_prizeTier.drawId, _prizeTier);
    // }

    /* ============ Getter Functions ============ */

    // @inheritdoc IPrizeTierHistory
    function getPrizeTier(uint32 _drawId) external view override returns (PrizeTier memory) {
        uint256 cardinality = history.length;
        uint256 leftSide = 0;
        uint256 rightSide = cardinality - 1;

        uint32 oldestDrawId = history[leftSide].drawId;
        uint32 newestDrawId = history[rightSide].drawId;

        require(_drawId >= oldestDrawId, "PrizeTierHistory/draw-id-out-of-range");

        if (_drawId >= newestDrawId) {
            // TODO: optimistic return or revert?
            return history[rightSide];
        }

        while (true) {
            uint256 center = leftSide + (rightSide - leftSide) / 2;
            uint32 centerPrizeTierID = history[center].drawId;

            if (centerPrizeTierID == _drawId) {
                return history[center];
            }

            if (centerPrizeTierID < _drawId) {
                leftSide = center + 1;
            } else if (centerPrizeTierID > _drawId) {
                rightSide = center - 1;
            }

            if (leftSide == rightSide) {
                if (centerPrizeTierID >= _drawId) {
                    return history[center - 1];
                } else {
                    return history[center];
                }
            }
        }
    }

    // @inheritdoc IPrizeTierHistory
    function getOldestDrawId() external view override returns (uint32) {
        return history[0].drawId;
    }

    // @inheritdoc IPrizeTierHistory
    function getNewestDrawId() external view override returns (uint32) {
        return history[history.length - 1].drawId;
    }

    // @inheritdoc IPrizeTierHistory
    function getPrizeTierList(uint32[] calldata _drawIds)
        external
        view
        override
        returns (PrizeTier[] memory)
    {
        // PrizeTier[] memory _data = new PrizeTier[](_drawIds.length) ;
        // uint32 _startDrawId = startDrawId;
        // for (uint256 index = 0; index < _drawIds.length; index++) {
        //   _data[index] = history[_drawIds[index] - _startDrawId]; // SLOAD each struct instead of the whole array before the FOR loop.
        // }
        // return _data;
    }
}
