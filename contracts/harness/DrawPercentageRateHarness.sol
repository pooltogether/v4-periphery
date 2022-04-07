// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../PrizeDistributionAdapter.sol";

contract PrizeDistributionAdapterHarness is PrizeDistributionAdapter {
    constructor(ITicket _ticket, IDrawBuffer _drawBuffer)
        PrizeDistributionAdapter(_ticket, _drawBuffer)
    {}

    function calculatePrizeDistribution(uint32 _drawId)
        external
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return _calculatePrizeDistribution(_drawId);
    }

    function calculateDrawPeriodTimestampOffsets(
        uint64 _timestamp,
        uint32 _startOffset,
        uint32 _endOffset
    ) public pure returns (uint64[] memory startTimestamps, uint64[] memory endTimestamps) {
        return _calculateDrawPeriodTimestampOffsets(_timestamp, _startOffset, _endOffset);
    }

    function calculateCardinality(
        uint32 _bitRangeSize,
        uint256 _prize,
        uint256 _dpr,
        uint256 _minPickCost,
        uint256 _totalSupply
    ) public pure returns (uint8 cardinality) {
        return _calculateCardinality(_bitRangeSize, _prize, _dpr, _minPickCost, _totalSupply);
    }

    function calculateNumberOfPicks(
        uint32 _bitRangeSize,
        uint256 _prize,
        uint256 _dpr,
        uint256 _minPickCost,
        uint256 _totalSupply
    ) public pure returns (uint256 numberOfPicks) {
        return _calculateNumberOfPicks(_bitRangeSize, _prize, _dpr, _minPickCost, _totalSupply);
    }

    function calculateNumberOfPicksWithCardinalityAndFraction(
        uint32 _bitRangeSize,
        uint256 _cardinality,
        uint256 _fractionOfOdds
    ) public pure returns (uint256 cardinality) {
        return
            _calculateNumberOfPicksWithCardinalityAndFraction(
                _bitRangeSize,
                _cardinality,
                _fractionOfOdds
            );
    }

    function calculateCardinalityCeiling(uint32 _bitRangeSize, uint256 _maxPicks)
        public
        pure
        returns (uint8 cardinality)
    {
        return _calculateCardinalityCeiling(_bitRangeSize, _maxPicks);
    }

    function calculateFractionOfOdds(
        uint256 _dpr,
        uint256 _totalSupply,
        uint256 _prize
    ) public pure returns (uint256) {
        return _calculateFractionOfOdds(_dpr, _totalSupply, _prize);
    }

    function calculateCardinalityAndNumberOfPicks(
        uint32 _bitRangeSize,
        uint256 _prize,
        uint256 _dpr,
        uint256 _minPickCost,
        uint256 _totalSupply
    ) public pure returns (uint8 cardinality, uint256 numberOfPicks) {
        return
            _calculateCardinalityAndNumberOfPicks(
                _bitRangeSize,
                _prize,
                _dpr,
                _minPickCost,
                _totalSupply
            );
    }
}
