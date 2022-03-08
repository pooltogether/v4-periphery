// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "./interfaces/IPrizeTierHistoryV2.sol";
import "./DrawIDBinarySearch.sol";

/**
 * @title  PoolTogether V4 PrizeTierHistoryV2
 * @author PoolTogether Inc Team
 * @notice PrizeTierHistoryV2 manages a history of PrizeTier parameters
 * @dev    During PrizeTierHistoryV2 initialization a history can be injected into the contract.
           Injection of history allows us to mimic historical data from PrizeTierHistoryV1 while
           tightly packing the DPR parameter into the PrizeTierV2 struct.
 */
contract PrizeTierHistoryV2 is IPrizeTierHistoryV2, DrawIDBinarySearch, Manageable {
    PrizeTierV2[] internal history;

    constructor(address _owner, PrizeTierV2[] memory _history) Ownable(_owner) {
        if (_history.length > 0) {
            _injectTimeline(_history);
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

    // @inheritdoc IPrizeTierHistoryV2
    function getOldestDrawId() external view override returns (uint32) {
        return history[0].drawId;
    }

    // @inheritdoc IPrizeTierHistoryV2
    function getNewestDrawId() external view override returns (uint32) {
        return history[history.length - 1].drawId;
    }

    // @inheritdoc IPrizeTierHistoryV2
    function getPrizeTier(uint32 drawId)
        external
        view
        override
        returns (PrizeTierV2 memory prizeTier)
    {
        require(drawId > 0, "PrizeTierHistoryV2/draw-id-not-zero");
        return _getPrizeTier(drawId);
    }

    // @inheritdoc IPrizeTierHistoryV2
    function getPrizeTierList(uint32[] calldata _drawIds)
        external
        view
        override
        returns (PrizeTierV2[] memory)
    {
        PrizeTierV2[] memory _data = new PrizeTierV2[](_drawIds.length);
        for (uint256 index = 0; index < _drawIds.length; index++) {
            _data[index] = _getPrizeTier(_drawIds[index]);
        }
        return _data;
    }

    function getPrizeTierAtIndex(uint256 index) external view returns (PrizeTierV2 memory) {
        return history[index];
    }

    /* =================================================== */
    /* Setters =========================================== */
    /* =================================================== */

    function push(PrizeTierV2 calldata nextPrizeTier) external onlyManagerOrOwner returns (bool) {
        _push(nextPrizeTier);
        return true;
    }

    function replace(PrizeTierV2 calldata newPrizeTier) external onlyOwner returns (bool) {
        _replace(newPrizeTier);
        return true;
    }

    function injectTimeline(PrizeTierV2[] calldata prizeTierTimeline)
        external
        onlyOwner
        returns (bool)
    {
        _injectTimeline(prizeTierTimeline);
        return true;
    }

    /* =================================================== */
    /* Internal ========================================== */
    /* =================================================== */

    function _getPrizeTier(uint32 _drawId) internal view returns (PrizeTierV2 memory) {
        return history[_binarySearch(_drawId)];
    }

    function _push(PrizeTierV2 memory _prizeTier) internal {
        PrizeTierV2[] memory _history = history;
        if (_history.length > 0) {
            PrizeTierV2 memory _newestDpr = history[history.length - 1];
            require(_prizeTier.drawId > _newestDpr.drawId, "PrizeTierHistoryV2/non-sequential-dpr");
        }
        history.push(_prizeTier);
        emit PrizeTierPushed(_prizeTier.drawId, _prizeTier);
    }

    function _replace(PrizeTierV2 calldata _prizeTier) internal {
        uint256 cardinality = history.length;
        require(cardinality > 0, "PrizeTierHistoryV2/no-prize-tiers");
        uint32 oldestDrawId = history[0].drawId;
        require(_prizeTier.drawId >= oldestDrawId, "PrizeTierHistoryV2/draw-id-out-of-range");
        uint256 index = _binarySearch(_prizeTier.drawId);
        require(
            history[index].drawId == _prizeTier.drawId,
            "PrizeTierHistoryV2/draw-id-must-match"
        );
        history[index] = _prizeTier;
        emit PrizeTierSet(_prizeTier.drawId, _prizeTier);
    }

    function _injectTimeline(PrizeTierV2[] memory _timeline) internal {
        require(history.length == 0, "PrizeTierHistoryV2/history-not-empty");
        require(_timeline.length > 0, "PrizeTierHistoryV2/timeline-empty");
        for (uint256 i = 0; i < _timeline.length; i++) {
            _push(_timeline[i]);
        }
    }
}
