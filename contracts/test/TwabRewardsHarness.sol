// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../TwabRewards.sol";

contract TwabRewardsHarness is TwabRewards {
    function requireTicket(address _ticket) external view {
        return _requireTicket(_ticket);
    }

    function isClaimedEpoch(uint256 _userClaimedEpochs, uint8 _epochId)
        external
        pure
        returns (bool)
    {
        return _isClaimedEpoch(_userClaimedEpochs, _epochId);
    }
}
