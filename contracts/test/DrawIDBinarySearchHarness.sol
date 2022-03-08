// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../DrawIDBinarySearch.sol";

contract DrawIDBinarySearchHarness is DrawIDBinarySearch {

    struct Draw {
        uint32 drawId;
    }

    Draw[] internal history;

    constructor(Draw[] memory _history) {
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

    function binarySearch(uint32 _drawId) internal view returns (Draw memory) {
        return history[_binarySearch(_drawId)];
    }

    function _injectTimeline(Draw[] memory _timeline) internal {
        require(history.length == 0, "DrawIDBinarySearchHarness/history-not-empty");
        require(_timeline.length > 0, "DrawIDBinarySearchHarness/timeline-empty");
        for (uint256 i = 0; i < _timeline.length; i++) {
            _push(_timeline[i]);
        }
    }

    function _push(Draw memory _draw) internal {
        Draw[] memory _history = history;
        if (_history.length > 0) {
            Draw memory _newestDpr = history[history.length - 1];
            require(_draw.drawId > _newestDpr.drawId, "DrawIDBinarySearchHarness/non-sequential-dpr");
        }
        history.push(_draw);
    }

}