// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "hardhat/console.sol";
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/ITicket.sol";
import "./interfaces/IPrizeTierHistory.sol";

/**
 * @title  PoolTogether V4 DrawPercentageRate
 * @author PoolTogether Inc Team
 * @notice DrawPercentageRate calculates a PrizePool distributions using a static draw percentage rate
 */
contract DrawPercentageRate {
    // Constants
    uint32 public constant RATE_NORMALIZATION = 1e9;

    // Immutable (Set by constructor)
    uint256 public immutable minPickCost;

    // Mutable
    uint256 public dpr;
    ITicket public ticket;
    IDrawBuffer public drawBuffer;
    IPrizeTierHistory public prizeTierHistory;

    struct DPRHistory {
        uint32 drawId;
        uint256 dpr;
    }

    DPRHistory[] internal history;

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
    /* Core ============================================== */
    /* =================================================== */

    function getDpr(uint32 _drawId) external view returns (DPRHistory memory) {
        require(_drawId > 0, "DrawPercentageRate/draw-id-not-zero");
        return _getDpr(_drawId);
    }

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
    /* Internal ========================================== */
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
        DPRHistory memory _history = _getDpr(_drawId);
        return _calculatePrizeDistribution(_drawId, _history.dpr);
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
        IPrizeTierHistory.PrizeTier memory prizeTier = prizeTierHistory.getPrizeTier(_drawId);
        IDrawBeacon.Draw memory draw = drawBuffer.getDraw(_drawId);
        (uint64[] memory start, uint64[] memory end) = _calculateDrawPeriodTimestampOffsets(
            draw.timestamp,
            draw.beaconPeriodSeconds,
            prizeTier.endTimestampOffset
        );
        uint256[] memory _totalSupplies = ticket.getAverageTotalSuppliesBetween(start, end);
        (uint8 _cardinality, uint104 _numberOfPicks) = _calculateCardinalityAndNumberOfPicks(
            _totalSupplies[0],
            prizeTier.prize,
            prizeTier.bitRangeSize,
            _dpr,
            minPickCost
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
        uint256 _totalSupply,
        uint256 _prize,
        uint32 _bitRangeSize,
        uint256 _dpr,
        uint256 _minPickCost
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
        uint256 _totalSupply,
        uint256 _prize,
        uint32 _bitRangeSize,
        uint256 _dpr,
        uint256 _minPickCost
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
        uint256 _totalSupply,
        uint256 _prize,
        uint32 _bitRangeSize,
        uint256 _dpr,
        uint256 _minPickCost
    ) internal pure returns (uint8 cardinality, uint104 numberOfPicks) {
        cardinality = _calculateCardinality(
            _totalSupply,
            _prize,
            _bitRangeSize,
            _dpr,
            _minPickCost
        );
        numberOfPicks = _calculateNumberOfPicks(
            _totalSupply,
            _prize,
            _bitRangeSize,
            _dpr,
            _minPickCost
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

    function _getDpr(uint32 _drawId) internal view returns (DPRHistory memory) {
        uint256 cardinality = history.length;
        require(cardinality > 0, "DrawPercentageRate/no-prize-tiers");

        uint256 leftSide = 0;
        uint256 rightSide = cardinality - 1;
        uint32 oldestDrawId = history[leftSide].drawId;
        uint32 newestDrawId = history[rightSide].drawId;

        require(_drawId >= oldestDrawId, "DrawPercentageRate/draw-id-out-of-range");
        if (_drawId >= newestDrawId) return history[rightSide];
        if (_drawId == oldestDrawId) return history[leftSide];

        return _binarySearch(_drawId, leftSide, rightSide, history);
    }

    function _binarySearch(
        uint32 _drawId,
        uint256 leftSide,
        uint256 rightSide,
        DPRHistory[] storage _history
    ) internal view returns (DPRHistory memory) {
        return _history[_binarySearchIndex(_drawId, leftSide, rightSide, _history)];
    }

    function _binarySearchIndex(
        uint32 _drawId,
        uint256 _leftSide,
        uint256 _rightSide,
        DPRHistory[] storage _history
    ) internal view returns (uint256) {
        uint256 index;
        uint256 leftSide = _leftSide;
        uint256 rightSide = _rightSide;
        while (true) {
            uint256 center = leftSide + (rightSide - leftSide) / 2;
            uint32 centerID = _history[center].drawId;

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

    function getDpr() external view returns (uint256) {
        return dpr;
    }

    function getMinPickCost() external view returns (uint256) {
        return minPickCost;
    }

    function getTicket() external view returns (ITicket) {
        return ticket;
    }

    function getDrawBuffer() external view returns (IDrawBuffer) {
        return drawBuffer;
    }

    function getPrizeTierHistory() external view returns (IPrizeTierHistory) {
        return prizeTierHistory;
    }

    /* =================================================== */
    /* Setter ============================================ */
    /* =================================================== */

    function setDpr(uint256 _dpr) external {
        dpr = _dpr;
    }

    function setTicket(ITicket _ticket) external {
        ticket = _ticket;
    }

    function setDrawBuffer(IDrawBuffer _drawBuffer) external {
        drawBuffer = _drawBuffer;
    }

    function setPrizeTierHistory(IPrizeTierHistory _prizeTierHistory) external {
        prizeTierHistory = _prizeTierHistory;
    }

    function push(DPRHistory calldata _nextDpr) external {
        DPRHistory[] memory _history = history;
        if (_history.length > 0) {
            DPRHistory memory _newestDpr = history[history.length - 1];
            require(_nextDpr.drawId > _newestDpr.drawId, "DrawPercentageRate/non-sequential-dpr");
        }
        history.push(_nextDpr);
    }

    function replace(DPRHistory calldata _nextDpr) external {
        uint256 cardinality = history.length;
        require(cardinality > 0, "DrawPercentageRate/no-prize-tiers");
        uint256 leftSide = 0;
        uint256 rightSide = cardinality - 1;
        uint32 oldestDrawId = history[leftSide].drawId;
        require(_nextDpr.drawId >= oldestDrawId, "DrawPercentageRate/draw-id-out-of-range");
        uint256 index = _binarySearchIndex(_nextDpr.drawId, leftSide, rightSide, history);
        require(history[index].drawId == _nextDpr.drawId, "DrawPercentageRate/draw-id-must-match");
        history[index] = _nextDpr;
    }
}
