// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import { IDrawBeacon } from "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import { IDrawBuffer } from "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import { ICrossChainRelayer } from "./interfaces/ICrossChainRelayer.sol";

contract DrawRelayer is Manageable {
    event DrawBridged(ICrossChainRelayer relayer, address drawExecutor, IDrawBeacon.Draw draw);

    event DrawsBridged(ICrossChainRelayer relayer, address drawExecutor, IDrawBeacon.Draw[] draws);

    IDrawBuffer public immutable drawBuffer;

    constructor(address _owner, IDrawBuffer _drawBuffer) Ownable(_owner) {
        require(_owner != address(0), "DR/owner-not-zero-address");
        require(address(_drawBuffer) != address(0), "DR/drawBuffer-not-zero-address");

        drawBuffer = _drawBuffer;
    }

    function bridgeNewestDraw(ICrossChainRelayer _relayer, address _drawExecutor)
        external
        onlyManager
    {
        IDrawBeacon.Draw memory _newestDraw = drawBuffer.getNewestDraw();
        _bridgeDraw(_newestDraw, _relayer, _drawExecutor);
    }

    function bridgeDraw(
        uint32 _drawId,
        ICrossChainRelayer _relayer,
        address _drawExecutor
    ) external onlyManager {
        require(_drawId > 0, "DR/drawId-gt-zero");

        IDrawBeacon.Draw memory _draw = drawBuffer.getDraw(_drawId);
        _bridgeDraw(_draw, _relayer, _drawExecutor);
    }

    /**
     * @dev `_drawIds` must be sorted in ascending order.
     */
    function bridgeDraws(
        uint32[] calldata _drawIds,
        ICrossChainRelayer _relayer,
        address _drawExecutor,
        uint256 _gasLimit
    ) external onlyManager {
        IDrawBeacon.Draw[] memory _draws = drawBuffer.getDraws(_drawIds);

        _relayCalls(
            abi.encodeWithSignature("pushDraws((uint256,uint32,uint64,uint64,uint32)[])", _draws),
            _relayer,
            _drawExecutor,
            _gasLimit
        );

        emit DrawsBridged(_relayer, _drawExecutor, _draws);
    }

    function _bridgeDraw(
        IDrawBeacon.Draw memory _draw,
        ICrossChainRelayer _relayer,
        address _drawExecutor
    ) internal {
        _relayCalls(
            abi.encodeWithSignature("pushDraw((uint256,uint32,uint64,uint64,uint32))", _draw),
            _relayer,
            _drawExecutor,
            500000
        );

        emit DrawBridged(_relayer, _drawExecutor, _draw);
    }

    function _relayCalls(
        bytes memory _data,
        ICrossChainRelayer _relayer,
        address _drawExecutor,
        uint256 _gasLimit
    ) internal {
        require(address(_relayer) != address(0), "DR/relayer-not-zero-address");
        require(_drawExecutor != address(0), "DR/drawExecutor-not-zero-address");
        require(_gasLimit > 0, "DR/gasLimit-gt-zero");

        ICrossChainRelayer.Call[] memory _calls = new ICrossChainRelayer.Call[](1);

        _calls[0] = ICrossChainRelayer.Call({ target: _drawExecutor, data: _data });

        _relayer.relayCalls(_calls, _gasLimit);
    }
}
