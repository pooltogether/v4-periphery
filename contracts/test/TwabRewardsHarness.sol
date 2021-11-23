// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../TwabRewards.sol";

contract TwabRewardsHarness is TwabRewards {
    constructor(address _owner) TwabRewards(_owner) {
        emit Deployed(_owner);
    }

    function requireTicket(ITicket _ticket) external {
        return _requireTicket(_ticket);
    }
}
