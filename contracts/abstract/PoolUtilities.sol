// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";

/**
 * @title  PoolTogether V4 PoolUtilities
 * @author PoolTogether Inc Team
 * @notice DrawIDBinarySearch uses binary search to find a parent contract struct with the drawId parameter
 * @dev    The implementing contract must provider access to a struct (i.e. PrizeTier) list with is both
 *         sorted and indexed by the drawId field for binary search to work.
 */
contract PoolUtilities {
    uint32 public constant RATE_NORMALIZATION = 1e9;

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
}
