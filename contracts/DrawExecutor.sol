// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";

import { ExecutorAware } from "./abstract/ExecutorAware.sol";

contract DrawExecutor is ExecutorAware {
    event DrawPushed(IDrawBeacon.Draw draw);

    event DrawsPushed(IDrawBeacon.Draw[] draws);

    address public immutable drawRelayer;

    IDrawBuffer public immutable drawBuffer;

    constructor(
        address _executor,
        address _drawRelayer,
        IDrawBuffer _drawBuffer
    ) ExecutorAware(_executor) {
        require(address(_drawRelayer) != address(0), "DE/drawRelayer-not-zero-address");
        require(address(_drawBuffer) != address(0), "DE/drawBuffer-not-zero-address");

        drawRelayer = _drawRelayer;
        drawBuffer = _drawBuffer;
    }

    function pushDraw(IDrawBeacon.Draw calldata _draw) external {
        _checkSender();

        drawBuffer.pushDraw(_draw);

        emit DrawPushed(_draw);
    }

    function pushDraws(IDrawBeacon.Draw[] calldata _draws) external {
        _checkSender();

        uint256 _drawsLength = _draws.length;

        for (uint256 i; i < _drawsLength; i++) {
            drawBuffer.pushDraw(_draws[i]);
        }

        emit DrawsPushed(_draws);
    }

    function _checkSender() internal view {
        require(isTrustedExecutor(msg.sender), "DE/l2-sender-not-executor");
        require(_msgSender() == address(drawRelayer), "DE/l1-sender-not-relayer");
    }
}
