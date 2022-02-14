// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/ITicket.sol";
import "./interfaces/IPrizeTierHistory.sol";

contract DrawPercentageRate {
    uint256 public dpr;
    uint256 public immutable minPickCost;

    ITicket public ticket;
    IDrawBuffer public drawBuffer;
    IPrizeTierHistory public prizeTierHistory;

    /* =================================================== */
    /* Constructor ======================================= */
    /* =================================================== */

    /**
    * Constructor
    * @param _ticket - ITicket
    * @param _drawBuffer - IDrawBuffer
    * @param _prizeTierHistory - IPrizeTierHistory
    * @param _dpr - uint256
    * @param _minPickCost - uint256
     */
    constructor(
        ITicket _ticket,
        IPrizeTierHistory _prizeTierHistory,
        IDrawBuffer _drawBuffer,
        uint256 _minPickCost,
        uint256 _dpr
    ) {
        ticket = _ticket;
        prizeTierHistory = _prizeTierHistory;
        drawBuffer = _drawBuffer;
        minPickCost = _minPickCost;
        dpr = _dpr;
    }

    /* =================================================== */
    /* Core Functions ==================================== */
    /* =================================================== */

    /**
     * @notice Get a PrizeDistribution using a historical Draw ID
     * @param drawId - uint32
     * @return prizeDistribution
     */
    function getPrizeDistribution(uint32 drawId)
        external
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return _getPrizeDistribution(drawId);
    }

    /**
     * @notice Get a list of PrizeDistributions using historical Draw IDs
     * @param drawIds - uint32[]
     * @return prizeDistribution
     */
    function getPrizeDistributionList(uint32[] calldata drawIds)
        external
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution[] memory)
    {
        IPrizeDistributionBuffer.PrizeDistribution[]
            memory _prizeDistributions = new IPrizeDistributionBuffer.PrizeDistribution[](
                drawIds.length
            );
        for (uint256 index = 0; index < drawIds.length; index++) {
            _prizeDistributions[index] = _getPrizeDistribution(drawIds[index]);
        }
        return _prizeDistributions;
    }

    /* =================================================== */
    /* Getter Functions ================================== */
    /* =================================================== */

    function getDpr()
        external
        view
        returns (uint256)
    {
        return dpr;
    }

    function getMinPickCost()
        external
        view
        returns (uint256)
    {
        return minPickCost;
    }

    function getTicket()
        external
        view
        returns (ITicket)
    {
        return ticket;
    }

    function getDrawBuffer()
        external
        view
        returns (IDrawBuffer)
    {
        return drawBuffer;
    }

    function getPrizeTierHistory()
        external
        view
        returns (IPrizeTierHistory)
    {
        return prizeTierHistory;
    }

    /* =================================================== */
    /* Setter Functions ================================== */
    /* =================================================== */

    function setDpr(uint256 _dpr)
        external
    {
        dpr = _dpr;
    }

    function setTicket(ITicket _ticket)
        external
    {
        ticket = _ticket;
    }

    function setDrawBuffer(IDrawBuffer _drawBuffer)
        external
    {
        drawBuffer = _drawBuffer;
    }

    function setPrizeTierHistory(IPrizeTierHistory _prizeTierHistory)
        external
    {
        prizeTierHistory = _prizeTierHistory;
    }

    /* =================================================== */
    /* Internal Functions ================================ */
    /* =================================================== */

    /**
     * @notice Internal function to get a PrizeDistribution using a historical Draw ID
     * @param _drawId - uint32
     * @return prizeDistribution
     */
    function _getPrizeDistribution(uint32 _drawId)
        internal
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        uint256 __dpr = dpr; // Replace with ring buffer or a more simple alternative to map drawIds <> dpr over time.
        return _calculatePrizeDistribution(_drawId, __dpr);
    }

    /**
     * @notice Calculate a PrizeDistribution using Draw, PrizeTier and DrawPercentageRate parameters
     * @param _drawId - uint32
     * @param _dpr - uint256 Draw Percentage Rate associated with the Draw ID
     * @return prizeDistribution
     */
    function _calculatePrizeDistribution(uint32 _drawId, uint256 _dpr)
        internal
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        IPrizeTierHistory.PrizeTier memory PrizeTier = prizeTierHistory.getPrizeTier(_drawId);
        IDrawBeacon.Draw memory Draw = drawBuffer.getDraw(_drawId);

        (uint64[] memory start, uint64[] memory end) = _calculateDrawPeriodTimestampOffsets(
            Draw.timestamp,
            Draw.beaconPeriodSeconds,
            PrizeTier.endTimestampOffset
        );

        uint256[] memory _totalSupplies = ticket.getAverageTotalSuppliesBetween(start, end);
        uint256 _maxPicks = _totalSupplies[0] / minPickCost;
        uint8 _cardinality = _calculateCardinality(PrizeTier.bitRangeSize, _maxPicks);
        uint256 _fractionOfOdds = _caclulateFractionOfOdds(
            _dpr,
            _totalSupplies[0],
            PrizeTier.prize
        );
        uint256 _totalPicks = uint256((2**PrizeTier.bitRangeSize)**_cardinality); // .toUint104(); - TODO: Convert to uint104 and optimize stoarge/loading
        uint32 _numberOfPicks = uint32(_totalPicks) * uint32(_fractionOfOdds);

        IPrizeDistributionBuffer.PrizeDistribution
            memory prizeDistribution = IPrizeDistributionBuffer.PrizeDistribution({
                bitRangeSize: PrizeTier.bitRangeSize,
                matchCardinality: _cardinality,
                startTimestampOffset: Draw.beaconPeriodSeconds,
                endTimestampOffset: PrizeTier.endTimestampOffset,
                maxPicksPerUser: PrizeTier.maxPicksPerUser,
                expiryDuration: PrizeTier.expiryDuration,
                numberOfPicks: _numberOfPicks,
                tiers: PrizeTier.tiers,
                prize: PrizeTier.prize
            });

        return prizeDistribution;
    }

    function _calculateDrawPeriodTimestampOffsets(
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

    function _calculateCardinality(uint32 _bitRangeSize, uint256 _maxPicks)
        internal
        pure
        returns (uint8 cardinality)
    {
        do {
            cardinality++;
        } while ((2**_bitRangeSize)**(cardinality + 1) < _maxPicks);
    }

    function _caclulateFractionOfOdds(
        uint256 _dpr,
        uint256 _totalSupply,
        uint256 _prize
    ) internal pure returns (uint256) {
        // TODO: Normalize things and do math
        return (_dpr * _totalSupply) / _prize;
    }
}
