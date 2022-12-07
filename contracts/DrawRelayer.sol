// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import { IDrawBeacon } from "@pooltogether/v4-core/contracts/interfaces/IDrawBeacon.sol";
import { IDrawBuffer } from "@pooltogether/v4-core/contracts/interfaces/IDrawBuffer.sol";

import { ICrossChainRelayer } from "./interfaces/ICrossChainRelayer.sol";

/**
 * @title PoolTogether V4 DrawRelayer
 * @author PoolTogether Inc Team
 * @notice The DrawRelayer smart contract relies on ERC-5164 to bridge draws from Ethereum to another L1 or L2
 *         where Chainlink VRF 2.0 may not be available to compute draws.
 */
contract DrawRelayer {
    /**
     * @notice Emit when the `draw` has been bridged.
     * @param relayer Address of the relayer on Ethereum that bridged the draw
     * @param drawExecutor Address of the DrawExecutor on the receiving chain that will push the draw onto the DrawBuffer
     * @param draw Draw that was bridged
     */
    event DrawBridged(ICrossChainRelayer relayer, address drawExecutor, IDrawBeacon.Draw draw);

    /**
     * @notice Emit when the `draws` have been bridged.
     * @param relayer Address of the relayer on Ethereum that bridged the draws
     * @param drawExecutor Address of the DrawExecutor on the receiving chain that will push the draws onto the DrawBuffer
     * @param draws Draws that were bridged
     */
    event DrawsBridged(ICrossChainRelayer relayer, address drawExecutor, IDrawBeacon.Draw[] draws);

    /// @notice DrawBuffer from which draws are retrieved.
    IDrawBuffer public immutable drawBuffer;

    /**
     * @notice DrawRelayer constructor.
     * @param _drawBuffer Address of the DrawBuffer from which draws are retrieved
     */
    constructor(IDrawBuffer _drawBuffer) {
        require(address(_drawBuffer) != address(0), "DR/drawBuffer-not-zero-address");

        drawBuffer = _drawBuffer;
    }

    /**
     * @notice Retrieves and bridge the newest recorded draw.
     * @param _relayer Address of the relayer on Ethereum that will be used to bridge the draw
     * @param _drawExecutor Address of the DrawExecutor on the receiving chain that will push the draw onto the DrawBuffer
     */
    function bridgeNewestDraw(ICrossChainRelayer _relayer, address _drawExecutor) external {
        IDrawBeacon.Draw memory _newestDraw = drawBuffer.getNewestDraw();
        _bridgeDraw(_newestDraw, _relayer, _drawExecutor);
    }

    /**
     * @notice Retrieves and bridge draw.
     * @dev Will revert if the draw does not exist.
     * @param _drawId Id of the draw to bridge
     * @param _relayer Address of the relayer on Ethereum that will be used to bridge the draw
     * @param _drawExecutor Address of the DrawExecutor on the receiving chain that will push the draw onto the DrawBuffer
     */
    function bridgeDraw(
        uint32 _drawId,
        ICrossChainRelayer _relayer,
        address _drawExecutor
    ) external {
        require(_drawId > 0, "DR/drawId-gt-zero");

        IDrawBeacon.Draw memory _draw = drawBuffer.getDraw(_drawId);
        _bridgeDraw(_draw, _relayer, _drawExecutor);
    }

    /**
     * @notice Retrieves and bridge draws.
     * @dev `_drawIds` must be ordered in ascending and contiguous order.
     * @dev Will revert if one of the draw does not exist.
     * @param _drawIds Array of draw ids to bridge
     * @param _relayer Address of the relayer on Ethereum that will be used to bridge the draw
     * @param _drawExecutor Address of the DrawExecutor on the receiving chain that will push the draw onto the DrawBuffer
     * @param _gasLimit Gas limit required for the `pushDraws` transaction to execute on the receiving chain
     */
    function bridgeDraws(
        uint32[] calldata _drawIds,
        ICrossChainRelayer _relayer,
        address _drawExecutor,
        uint256 _gasLimit
    ) external {
        IDrawBeacon.Draw[] memory _draws = drawBuffer.getDraws(_drawIds);

        _relayCalls(
            abi.encodeWithSignature("pushDraws((uint256,uint32,uint64,uint64,uint32)[])", _draws),
            _relayer,
            _drawExecutor,
            _gasLimit
        );

        emit DrawsBridged(_relayer, _drawExecutor, _draws);
    }

    /**
     * @notice Bridge the passed `draw`.
     * @param _draw Draw to bridge
     * @param _relayer Address of the relayer on Ethereum that will be used to bridge the draw
     * @param _drawExecutor Address of the DrawExecutor on the receiving chain that will push the draw onto the DrawBuffer
     */
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

    /**
     * @notice Relay encoded call.
     * @param _data Calldata to relay
     * @param _relayer Address of the relayer on Ethereum that will relay the call
     * @param _drawExecutor Address of the DrawExecutor on the receiving chain that will receive the call
     * @param _gasLimit Gas limit required for the call to execute on the receiving chain
     */
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
