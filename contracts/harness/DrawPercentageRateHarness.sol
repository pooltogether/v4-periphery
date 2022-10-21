// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../PrizeDistributionAdapter.sol";

contract DrawPercentageRateHarness is PrizeDistributionAdapter {
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
        return
            DrawCalculationLib.calculateDrawPeriodTimestampOffsets(
                _timestamp,
                _startOffset,
                _endOffset
            );
    }

    function calculateCardinalityAndNumberOfPicks(
        uint32 _bitRangeSize,
        uint256 _prize,
        uint256 _dpr,
        uint256 _minPickCost,
        uint256 _totalSupply
    ) public pure returns (uint8 cardinality, uint256 numberOfPicks) {
        return
            DrawCalculationLib.calculateCardinalityAndNumberOfPicks(
                _bitRangeSize,
                _prize,
                _dpr,
                _minPickCost,
                _totalSupply
            );
    }
}
