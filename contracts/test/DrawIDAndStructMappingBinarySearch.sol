// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../abstract/IdBinarySearch.sol";

contract DrawIDAndStructMappingBinarySearch is IdBinarySearch {
    struct Draw {
        uint32 drawId;
        uint256 randomNumber;
    }

    uint32[] internal history;
    mapping(uint32 => Draw) internal draws;

    constructor(Draw[] memory _history) {
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

    function get(uint32 _drawId) external view returns (Draw memory) {
        return draws[history[_binarySearch(_drawId)]];
    }

    function list(uint32[] calldata _drawIds) external view returns (Draw[] memory) {
        Draw[] memory _data = new Draw[](_drawIds.length);
        for (uint256 index = 0; index < _drawIds.length; index++) {
            _data[index] = draws[history[_binarySearch(_drawIds[index])]];
        }
        return _data;
    }

    function inject(Draw[] memory _timeline) public {
        require(history.length == 0, "DrawIDAndStructMappingBinarySearch/history-not-empty");
        require(_timeline.length > 0, "DrawIDAndStructMappingBinarySearch/timeline-empty");
        for (uint256 i = 0; i < _timeline.length; i++) {
            _push(_timeline[i]);
        }
    }

    function _push(Draw memory _draw) internal {
        if (history.length > 0) {
            uint32 _id = history[history.length - 1];
            require(
                _draw.drawId > _id,
                "DrawIDAndStructMappingBinarySearch/non-sequential-dpr"
            );
        }
        history.push(_draw.drawId);
        draws[_draw.drawId] = _draw;
    }
}
