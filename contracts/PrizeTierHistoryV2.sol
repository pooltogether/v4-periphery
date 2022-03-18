// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "./abstract/IdBinarySearch.sol";

contract PrizeTierHistoryV2 is IdBinarySearch, Manageable {

    struct PrizeTier {
        uint8 bitRangeSize;
        uint32 drawId;
        uint32 maxPicksPerUser;
        uint32 expiryDuration;
        uint32 endTimestampOffset;
        uint256 prize;
        uint32[16] tiers;
    }

    uint32[] internal history;
    mapping(uint32 => PrizeTier) internal prizeTiers;

    /**
     * @notice Emit when new PrizeTier is added to history
     * @param drawId    Draw ID
     * @param prizeTier PrizeTier parameters
     */
    event PrizeTierPushed(uint32 indexed drawId, PrizeTier prizeTier);

    /**
     * @notice Emit when existing PrizeTier is updated in history
     * @param drawId    Draw ID
     * @param prizeTier PrizeTier parameters
     */
    event PrizeTierSet(uint32 indexed drawId, PrizeTier prizeTier);

    constructor(address owner, PrizeTier[] memory _history) Ownable(owner) {
        if (_history.length > 0) {
            inject(_history);
        }
    }

    // @inheritdoc DrawIDBinarySearch
    function getNewestIndex() internal view override returns (uint32) {
        return uint32(history.length - 1);
    }

    // @inheritdoc DrawIDBinarySearch
    function getIdForIndex(uint256 index) internal view override returns (uint32) {
        return history[index];
    }

    function getPrizeTier(uint32 drawId) external view returns (PrizeTier memory) {
        require(drawId > 0, "PrizeTierHistoryV2/draw-id-not-zero");
        return prizeTiers[history[_binarySearch(drawId)]];
    }

    function getPrizeTierList(uint32[] calldata _drawIds) external view returns (PrizeTier[] memory) {
        PrizeTier[] memory _data = new PrizeTier[](_drawIds.length);
        for (uint256 index = 0; index < _drawIds.length; index++) {
            _data[index] = prizeTiers[history[_binarySearch(_drawIds[index])]];
        }
        return _data;
    }

    function push(PrizeTier calldata nextPrizeTier) external onlyManagerOrOwner {
        _push(nextPrizeTier);
    }
    
    function popAndPush(PrizeTier calldata newPrizeTier) external onlyManagerOrOwner {
        uint length = history.length;
        require(length > 0, "PrizeTierHistoryV2/history-empty");
        require(history[length - 1] == newPrizeTier.drawId, "PrizeTierHistoryV2/invalid-draw-id");
        _replace(newPrizeTier);
    }

    function replace(PrizeTier calldata newPrizeTier) external onlyOwner {
        _replace(newPrizeTier);
    }

    function inject(PrizeTier[] memory timeline) public onlyOwner {
        require(history.length == 0, "PrizeTierHistoryV2/history-not-empty");
        require(timeline.length > 0, "PrizeTierHistoryV2/timeline-empty");
        for (uint256 i = 0; i < timeline.length; i++) {
            _push(timeline[i]);
        }
    }

    function _push(PrizeTier memory _prizeTier) internal {
        if (history.length > 0) {
            uint32 _id = history[history.length - 1];
            require(
                _prizeTier.drawId > _id,
                "PrizeTierHistoryV2/non-sequential-dpr"
            );
        }
        history.push(_prizeTier.drawId);
        prizeTiers[_prizeTier.drawId] = _prizeTier;
        emit PrizeTierPushed(_prizeTier.drawId, _prizeTier);
    }

    function _replace(PrizeTier calldata _prizeTier) internal {
        uint256 cardinality = history.length;
        require(cardinality > 0, "PrizeTierHistoryV2/no-prize-tiers");
        uint32 oldestDrawId = history[0];
        require(_prizeTier.drawId >= oldestDrawId, "PrizeTierHistoryV2/draw-id-out-of-range");
        uint32 index = _binarySearch(_prizeTier.drawId);
        require(history[index] == _prizeTier.drawId, "PrizeTierHistoryV2/draw-id-must-match");
        prizeTiers[_prizeTier.drawId] = _prizeTier;
        emit PrizeTierSet(_prizeTier.drawId, _prizeTier);
    }
}
