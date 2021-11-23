// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/ITwabRewards.sol";

/**
  * @title PoolTogether V4 TwabRewards
  * @author PoolTogether Inc Team
  * @notice Contract to distribute rewards to depositors in a pool.
 */
contract TwabRewards is ITwabRewards, Manageable {

  /// @notice Current epoch number
  uint32 internal epochId;

  /**
    @notice Emitted when contract has been deployed.
    @param owner Contract owner address
   */
  event Deployed(
    address owner
  );

  constructor(
    address _owner
  ) Ownable(_owner) {
    emit Deployed(_owner);
  }
}
