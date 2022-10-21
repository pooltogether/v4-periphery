// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 DrawCalculationLib
 * @author PoolTogether Inc Team
 * @notice DrawCalculationLib exposes helper functions
 *         to calculate values needed to compute results of a draw
 */
library DrawCalculationLib {
    /**
     * @notice Unit of normalization.
     * @dev The Draw Percentage Rate (DPR) being a 1e9 number,
     *      we need to normalize calculations by scaling up or down by 1e9
     */
    uint32 public constant RATE_NORMALIZATION = 1e9;

    /**
     * @notice Compute prize pool cardinality and number of picks for a draw
     * @param _bitRangeSize Bit range size
     * @param _prize Total prize amount
     * @param _dpr Draw percentage rate
     * @param _minPickCost Minimum cost for a pick
     * @param _totalSupply Prize Pool network TVL
     * @return cardinality and number of picks
     */
    function calculateCardinalityAndNumberOfPicks(
        uint32 _bitRangeSize,
        uint256 _prize,
        uint256 _dpr,
        uint256 _minPickCost,
        uint256 _totalSupply
    ) internal pure returns (uint8 cardinality, uint104 numberOfPicks) {
        uint256 _maxPicks = (_totalSupply * RATE_NORMALIZATION) / _minPickCost;
        uint256 _odds = (_dpr * _totalSupply) / _prize;

        uint256 _totalPicks;

        while ((_totalPicks = (2**_bitRangeSize)**(cardinality)) < (_maxPicks / _odds)) {
            cardinality++;
        }

        numberOfPicks = uint104((_totalPicks * _odds) / RATE_NORMALIZATION);
    }

    /**
     * @notice Calculate Draw period start and end timestamp
     * @param _timestamp Timestamp at which the draw was created by the DrawBeacon
     * @param _startOffset Draw start time offset in seconds
     * @param _endOffset Draw end time offset in seconds
     * @return Draw start and end timestamp
     */
    function calculateDrawPeriodTimestampOffsets(
        uint64 _timestamp,
        uint32 _startOffset,
        uint32 _endOffset
    ) internal pure returns (uint64[] memory, uint64[] memory) {
        uint64[] memory _startTimestamps = new uint64[](1);
        uint64[] memory _endTimestamps = new uint64[](1);

        _startTimestamps[0] = _timestamp - _startOffset;
        _endTimestamps[0] = _timestamp - _endOffset;

        return (_startTimestamps, _endTimestamps);
    }
}
