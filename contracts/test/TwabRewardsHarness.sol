// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../TwabRewards.sol";

contract TwabRewardsHarness is TwabRewards {
    function requireTicket(address _ticket) external view {
        return _requireTicket(_ticket);
    }
}
