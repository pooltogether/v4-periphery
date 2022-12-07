// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";

import { ExecutorAware } from "./abstract/ExecutorAware.sol";

/**
 * @title PoolTogether V4 DrawExecutor
 * @author PoolTogether Inc Team
 * @notice The DrawExecutor smart contract relies on ERC-5164 to receive draws from Ethereum
 *         and push them onto the DrawBuffer.
 * @dev This contract does not ensure draw ordering and draws should always be bridged in ascending and contiguous order.
 */
contract DrawExecutor is ExecutorAware {
    /**
     * @notice Emit when the `draw` has been pushed.
     * @param draw Draw that was pushed
     */
    event DrawPushed(IDrawBeacon.Draw draw);

    /**
     * @notice Emit when the `draws` have been pushed.
     * @param draws Draws that were pushed
     */
    event DrawsPushed(IDrawBeacon.Draw[] draws);

    /// @notice DrawRelayer contract on Ethereum that relay the draws.
    address public immutable drawRelayer;

    /// @notice DrawBuffer onto which draws are pushed.
    IDrawBuffer public immutable drawBuffer;

    /**
     * @notice DrawExecutor constructor.
     * @param _executor Address of the ERC-5164 contract that executes the bridged calls
     * @param _drawRelayer Address of the DrawRelayer on Ethereum that relay the draws
     * @param _drawBuffer Address of the DrawBuffer onto which draws are pushed
     */
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

    /**
     * @notice Push `draw` onto the DrawBuffer.
     * @dev Only the `executor` is able to call this function.
     * @param _draw Draw to push
     */
    function pushDraw(IDrawBeacon.Draw calldata _draw) external {
        _checkSender();

        drawBuffer.pushDraw(_draw);

        emit DrawPushed(_draw);
    }

    /**
     * @notice Push `draws` onto the DrawBuffer.
     * @dev Only the `executor` is able to call this function.
     * @dev `draws` must be ordered in ascending and contiguous order.
     * @param _draws Draws to push
     */
    function pushDraws(IDrawBeacon.Draw[] calldata _draws) external {
        _checkSender();

        uint256 _drawsLength = _draws.length;

        for (uint256 i; i < _drawsLength; i++) {
            drawBuffer.pushDraw(_draws[i]);
        }

        emit DrawsPushed(_draws);
    }

    /**
     * @notice Check that the sender on the receiving chain is the executor
     *         and that the sender on the origin chain is the DrawRelayer.
     */
    function _checkSender() internal view {
        require(isTrustedExecutor(msg.sender), "DE/l2-sender-not-executor");
        require(_msgSender() == address(drawRelayer), "DE/l1-sender-not-relayer");
    }
}
