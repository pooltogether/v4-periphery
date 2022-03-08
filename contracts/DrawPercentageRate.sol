// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "hardhat/console.sol";
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/ITicket.sol";
import "./interfaces/IPrizeTierHistoryV2.sol";

/**
 * @title  PoolTogether V4 DrawPercentageRate
 * @author PoolTogether Inc Team
 * @notice DrawPercentageRate calculates a PrizePool distributions using a static draw percentage rate
 */
contract DrawPercentageRate {
    uint32 public constant RATE_NORMALIZATION = 1e9;

    // Immutable (Set by constructor)
    uint256 public immutable minPickCost;

    // Mutable (Set by constructor and setters)
    ITicket public ticket;
    IDrawBuffer public drawBuffer;
    IPrizeTierHistoryV2 public prizeTierHistory;

    /**
     * Constructor
     * @param _ticket - ITicket
     * @param _drawBuffer - IDrawBuffer
     * @param _prizeTierHistory - IPrizeTierHistoryV2
     * @param _minPickCost - uint256
     */
    constructor(
        ITicket _ticket,
        IPrizeTierHistoryV2 _prizeTierHistory,
        IDrawBuffer _drawBuffer,
        uint256 _minPickCost
    ) {
        ticket = _ticket;
        prizeTierHistory = _prizeTierHistory;
        drawBuffer = _drawBuffer;
        minPickCost = _minPickCost;
    }

    /* =================================================== */
    /* Core ============================================== */
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
        return _calculatePrizeDistribution(drawId);
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
            _prizeDistributions[index] = _calculatePrizeDistribution(drawIds[index]);
        }
        return _prizeDistributions;
    }

    /* =================================================== */
    /* Internal ========================================== */
    /* =================================================== */

    /**
     * @notice Calculate a PrizeDistribution using Draw, PrizeTier and DrawPercentageRate parameters
     * @param _drawId - uint32
     * @return prizeDistribution
     */
    function _calculatePrizeDistribution(uint32 _drawId)
        internal
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        IPrizeTierHistoryV2.PrizeTierV2 memory prizeTier = prizeTierHistory.getPrizeTier(_drawId);
        IDrawBeacon.Draw memory draw = drawBuffer.getDraw(_drawId);
        (uint64[] memory start, uint64[] memory end) = _calculateDrawPeriodTimestampOffsets(
            draw.timestamp,
            draw.beaconPeriodSeconds,
            prizeTier.endTimestampOffset
        );
        uint256[] memory _totalSupplies = ticket.getAverageTotalSuppliesBetween(start, end);
        (uint8 _cardinality, uint104 _numberOfPicks) = _calculateCardinalityAndNumberOfPicks(
            prizeTier.bitRangeSize,
            prizeTier.prize,
            prizeTier.dpr,
            minPickCost,
            _totalSupplies[0]
        );
        IPrizeDistributionBuffer.PrizeDistribution
            memory prizeDistribution = IPrizeDistributionBuffer.PrizeDistribution({
                bitRangeSize: prizeTier.bitRangeSize,
                matchCardinality: _cardinality,
                startTimestampOffset: draw.beaconPeriodSeconds,
                endTimestampOffset: prizeTier.endTimestampOffset,
                maxPicksPerUser: prizeTier.maxPicksPerUser,
                expiryDuration: prizeTier.expiryDuration,
                numberOfPicks: _numberOfPicks,
                tiers: prizeTier.tiers,
                prize: prizeTier.prize
            });
        return prizeDistribution;
    }

    function _calculateCardinality(
        uint32 _bitRangeSize,
        uint256 _prize,
        uint256 _dpr,
        uint256 _minPickCost,
        uint256 _totalSupply
    ) internal pure returns (uint8 cardinality) {
        uint256 _maxPicks = _normalizePicks(_totalSupply, _minPickCost);
        uint256 _fractionOfOdds = _calculateFractionOfOdds(_dpr, _totalSupply, _prize);
        uint256 _maxPicksWithFracionOfOdds = _normalizePicks(
            _maxPicks * RATE_NORMALIZATION,
            _fractionOfOdds
        );
        cardinality = _calculateCardinalityCeiling(_bitRangeSize, _maxPicksWithFracionOfOdds);
    }

    function _calculateNumberOfPicks(
        uint32 _bitRangeSize,
        uint256 _prize,
        uint256 _dpr,
        uint256 _minPickCost,
        uint256 _totalSupply
    ) internal pure returns (uint104) {
        uint256 _maxPicks = _normalizePicks(_totalSupply, _minPickCost);
        uint256 _fractionOfOdds = _calculateFractionOfOdds(_dpr, _totalSupply, _prize);
        uint256 _maxPicksWithFracionOfOdds = _normalizePicks(
            (_maxPicks * RATE_NORMALIZATION),
            _fractionOfOdds
        );
        uint8 _cardinality = _calculateCardinalityCeiling(
            _bitRangeSize,
            _maxPicksWithFracionOfOdds
        );
        uint256 _totalPicks = uint256((2**_bitRangeSize)**_cardinality); // .toUint104(); - TODO: Convert to uint104 and optimize stoarge/loading
        uint256 numberOfPicks = (_totalPicks * _fractionOfOdds) / RATE_NORMALIZATION;
        return uint104(numberOfPicks);
    }

    function _calculateNumberOfPicksWithCardinalityAndFraction(
        uint32 _bitRangeSize,
        uint256 _cardinality,
        uint256 _fractionOfOdds
    ) internal pure returns (uint256 numberOfPicks) {
        uint256 _totalPicks = uint256((2**_bitRangeSize)**_cardinality);
        numberOfPicks = (_totalPicks * _fractionOfOdds) / RATE_NORMALIZATION;
    }

    function _calculateCardinalityAndNumberOfPicks(
        uint32 _bitRangeSize,
        uint256 _prize,
        uint256 _dpr,
        uint256 _minPickCost,
        uint256 _totalSupply
    ) internal pure returns (uint8 cardinality, uint104 numberOfPicks) {
        cardinality = _calculateCardinality(
            _bitRangeSize,
            _prize,
            _dpr,
            _minPickCost,
            _totalSupply
        );
        numberOfPicks = _calculateNumberOfPicks(
            _bitRangeSize,
            _prize,
            _dpr,
            _minPickCost,
            _totalSupply
        );
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

    function _calculateCardinalityCeiling(uint32 _bitRangeSize, uint256 _maxPicks)
        internal
        pure
        returns (uint8 cardinality)
    {
        while ((2**_bitRangeSize)**(cardinality) < _maxPicks) {
            cardinality++;
        }
    }

    function _calculateFractionOfOdds(
        uint256 _dpr,
        uint256 _totalSupply,
        uint256 _prize
    ) internal pure returns (uint256) {
        // TODO: Normalize things and do math
        return (_dpr * _totalSupply) / _prize;
    }

    function _normalizePicks(uint256 _dividend, uint256 _denomintor)
        internal
        pure
        returns (uint256 normalizedPicks)
    {
        normalizedPicks = _dividend / _denomintor;
    }

    /* =================================================== */
    /* Getter ============================================ */
    /* =================================================== */

    function getMinPickCost() external view returns (uint256) {
        return minPickCost;
    }

    function getTicket() external view returns (ITicket) {
        return ticket;
    }

    function getDrawBuffer() external view returns (IDrawBuffer) {
        return drawBuffer;
    }

    function getPrizeTierHistory() external view returns (IPrizeTierHistoryV2) {
        return prizeTierHistory;
    }

    /* =================================================== */
    /* Setter ============================================ */
    /* =================================================== */

    // @TODO: We probably don't need this setter. What good reason is there to change a ticket and the totalSupply history !?!?!?
    function setTicket(ITicket _ticket) external {
        ticket = _ticket;
    }

    function setDrawBuffer(IDrawBuffer _drawBuffer) external {
        drawBuffer = _drawBuffer;
    }

    function setPrizeTierHistory(IPrizeTierHistoryV2 _prizeTierHistory) external {
        prizeTierHistory = _prizeTierHistory;
    }
}
