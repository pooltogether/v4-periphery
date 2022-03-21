// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "./interfaces/IPrizeTierHistory.sol";
import "./abstract/IdBinarySearchLib.sol";

contract PrizeTierHistory is IPrizeTierHistory, Manageable {

    using IdBinarySearchLib for uint32[];

    uint32[] internal history;
    mapping(uint32 => PrizeTier) internal prizeTiers;

    constructor(address owner, PrizeTier[] memory _history) Ownable(owner) {
        if (_history.length > 0) {
            inject(_history);
        }
    }

    function getOldestDrawId() external view override returns (uint32) {
        return history[0];
    }

    function getNewestDrawId() external view override returns (uint32) {
        return prizeTiers[uint32(history.length - 1)].drawId;
    }

    function getPrizeTier(uint32 drawId) override external view returns (PrizeTier memory) {
        require(drawId > 0, "PrizeTierHistory/draw-id-not-zero");
        return prizeTiers[history[history.binarySearch(drawId)]];
    }

    function getPrizeTierList(uint32[] calldata _drawIds) override external view returns (PrizeTier[] memory) {
        PrizeTier[] memory _data = new PrizeTier[](_drawIds.length);
        for (uint256 index = 0; index < _drawIds.length; index++) {
            _data[index] = prizeTiers[history[history.binarySearch(_drawIds[index])]];
        }
        return _data;
    }

    function push(PrizeTier calldata nextPrizeTier) override external onlyManagerOrOwner {
        _push(nextPrizeTier);
    }
    
    function popAndPush(PrizeTier calldata newPrizeTier) override external onlyOwner returns (uint32) {
        uint length = history.length;
        require(length > 0, "PrizeTierHistory/history-empty");
        require(history[length - 1] == newPrizeTier.drawId, "PrizeTierHistory/invalid-draw-id");
        _replace(newPrizeTier);
        return newPrizeTier.drawId;
    }

    function replace(PrizeTier calldata newPrizeTier) override external onlyOwner {
        _replace(newPrizeTier);
    }

    function inject(PrizeTier[] memory timeline) public onlyOwner {
        require(history.length == 0, "PrizeTierHistory/history-not-empty");
        require(timeline.length > 0, "PrizeTierHistory/timeline-empty");
        for (uint256 i = 0; i < timeline.length; i++) {
            _push(timeline[i]);
        }
    }

    function getPrizeTierAtIndex(uint256 index) external view override returns (PrizeTier memory) {
        return prizeTiers[history[index]];
    }

    function count() external view override returns (uint256) {
        return history.length;
    }

    function _push(PrizeTier memory _prizeTier) internal {
        if (history.length > 0) {
            uint32 _id = history[history.length - 1];
            require(
                _prizeTier.drawId > _id,
                "PrizeTierHistory/non-sequential-dpr"
            );
        }
        history.push(_prizeTier.drawId);
        prizeTiers[_prizeTier.drawId] = _prizeTier;
        emit PrizeTierPushed(_prizeTier.drawId, _prizeTier);
    }

    function _replace(PrizeTier calldata _prizeTier) internal {
        uint256 cardinality = history.length;
        require(cardinality > 0, "PrizeTierHistory/no-prize-tiers");
        uint32 oldestDrawId = history[0];
        require(_prizeTier.drawId >= oldestDrawId, "PrizeTierHistory/draw-id-out-of-range");
        uint32 index = history.binarySearch(_prizeTier.drawId);
        require(history[index] == _prizeTier.drawId, "PrizeTierHistory/draw-id-must-match");
        prizeTiers[_prizeTier.drawId] = _prizeTier;
        emit PrizeTierSet(_prizeTier.drawId, _prizeTier);
    }
}
