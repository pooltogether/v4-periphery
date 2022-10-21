// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionSource.sol";
import "@pooltogether/v4-core/contracts/interfaces/IPrizeDistributionBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import "@pooltogether/v4-core/contracts/interfaces/ITicket.sol";
import "./abstract/DrawIDBinarySearch.sol";
import "./libraries/DrawCalculationLib.sol";
import "./interfaces/IPrizeTierHistoryV2.sol";

/**
 * @title  PoolTogether V4 PrizeDistributionAdapter
 * @author PoolTogether Inc Team
 * @notice PrizeDistributionAdapter dynamically calculates a PrizePool distributions using a static draw percentage rate.
 */
contract PrizeDistributionAdapter is IPrizeDistributionSource, DrawIDBinarySearch, Manageable {
    /**
     * @notice PrizeTierV2 struct
     * @dev    Adds the DPR and minPickCost paramater to the PrizeTierStructV1
     */
    struct PrizeTierV2 {
        uint8 bitRangeSize;
        uint32 drawId;
        uint32 maxPicksPerUser;
        uint32 expiryDuration;
        uint32 endTimestampOffset;
        uint256 prize;
        uint32[16] tiers;
        uint32 dpr;
        uint256 minPickCost;
    }

    ITicket internal ticket;
    IDrawBuffer internal drawBuffer;
    PrizeTierV2[] internal history;

    uint32[] internal _idhistory;

    /**
     * @notice Emit when new PrizeTierV2 is added to history
     * @param drawId    Draw ID
     * @param prizeTier PrizeTierV2 parameters
     */
    event PrizeTierPushed(uint32 indexed drawId, PrizeTierV2 prizeTier);

    /**
     * @notice Emit when existing PrizeTierV2 is updated in history
     * @param drawId    Draw ID
     * @param prizeTier PrizeTierV2 parameters
     */
    event PrizeTierSet(uint32 indexed drawId, PrizeTierV2 prizeTier);

    /**
     * @notice constructor
     * @param _ticket - ITicket
     * @param _drawBuffer - IDrawBuffer
     */
    constructor(ITicket _ticket, IDrawBuffer _drawBuffer) Ownable(msg.sender) {
        ticket = _ticket;
        drawBuffer = _drawBuffer;
    }

    /**
     * @notice Get a PrizeDistribution using a Draw ID within the current draw range
     * @param drawId - uint32
     * @return prizeDistribution
     */
    function getPrizeDistribution(uint32 drawId)
        external
        view
        returns (IPrizeDistributionSource.PrizeDistribution memory)
    {
        return _calculatePrizeDistribution(drawId);
    }

    /**
     * @notice Get an array of PrizeDistributions using array of Draw IDs within the current draw range
     * @param drawIds - uint32[]
     * @return prizeDistributions
     */
    function getPrizeDistributions(uint32[] calldata drawIds)
        external
        view
        override
        returns (IPrizeDistributionSource.PrizeDistribution[] memory prizeDistributions)
    {
        for (uint256 index = 0; index < drawIds.length; index++) {
            prizeDistributions[index] = _calculatePrizeDistribution(drawIds[index]);
        }
    }

    // @inheritdoc DrawIDBinarySearch
    function getNewestIndex() internal view override returns (uint32) {
        return uint32(history.length - 1);
    }

    // @inheritdoc DrawIDBinarySearch
    function getDrawIdForIndex(uint256 index) internal view override returns (uint32) {
        return history[index].drawId;
    }

    function getDrawBuffer() external view returns (IDrawBuffer) {
        return drawBuffer;
    }

    function getTicket() external view returns (ITicket) {
        return ticket;
    }

    function getPrizeTier(uint32 drawId) external view returns (PrizeTierV2 memory prizeTier) {
        return _getPrizeTier(drawId);
    }

    function getPrizeTiers(uint32[] calldata drawIds)
        external
        view
        returns (PrizeTierV2[] memory prizeTierList)
    {
        for (uint256 i = 0; i < drawIds.length; i++) {
            prizeTierList[i] = _getPrizeTier(drawIds[i]);
        }
    }

    function setDrawBuffer(IDrawBuffer _drawBuffer) external onlyOwner {
        drawBuffer = _drawBuffer;
    }

    /* Internal ========================================== */

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
        PrizeTierV2 memory prizeTier = _getPrizeTier(_drawId);

        IDrawBeacon.Draw memory draw = drawBuffer.getDraw(_drawId);

        (uint64[] memory start, uint64[] memory end) = DrawCalculationLib
            .calculateDrawPeriodTimestampOffsets(
                draw.timestamp,
                draw.beaconPeriodSeconds,
                prizeTier.endTimestampOffset
            );

        uint256[] memory _totalSupplies = ticket.getAverageTotalSuppliesBetween(start, end);

        (uint8 _cardinality, uint104 _numberOfPicks) = DrawCalculationLib
            .calculateCardinalityAndNumberOfPicks(
                prizeTier.bitRangeSize,
                prizeTier.prize,
                prizeTier.dpr,
                prizeTier.minPickCost,
                _totalSupplies[0]
            );

        IPrizeDistributionBuffer.PrizeDistribution
            memory prizeDistribution = IPrizeDistributionSource.PrizeDistribution({
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

    function _getPrizeTier(uint32 drawId) internal view returns (PrizeTierV2 memory prizeTier) {
        return history[_binarySearch(drawId)];
    }
}
