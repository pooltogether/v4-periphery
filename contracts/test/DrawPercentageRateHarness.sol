// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../DrawPercentageRate.sol";

contract DrawPercentageRateHarness is DrawPercentageRate {

    constructor(
        ITicket _ticket,
        IPrizeTierHistory _prizeTierHistory,
        IDrawBuffer _drawBuffer,
        uint256 _minPickCost,
        uint256 _dpr
    ) DrawPercentageRate(
        _ticket,
        _prizeTierHistory,
        _drawBuffer,
        _minPickCost,
        _dpr
    ) {}

    function calculatePrizeDistribution(uint32 _drawId, uint256 _dpr)
        external
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return _calculatePrizeDistribution(_drawId, _dpr);
    }

    function calculateDrawPeriodTimestampOffsets(
        uint64 _timestamp,
        uint32 _startOffset,
        uint32 _endOffset
    ) public pure returns (uint64[] memory startTimestamps, uint64[] memory endTimestamps) {
        return _calculateDrawPeriodTimestampOffsets(_timestamp, _startOffset, _endOffset);
    }

    function calculateCardinality(uint32 _bitRangeSize, uint256 _maxPicks)
        public
        pure
        returns (uint8 cardinality)
    {
        return _calculateCardinality(_bitRangeSize, _maxPicks);
    }

    function caclulateFractionOfOdds(
        uint256 _dpr,
        uint256 _totalSupply,
        uint256 _prize
    ) public pure returns (uint256) {
        return _caclulateFractionOfOdds(_dpr, _totalSupply, _prize);
    }
}
