// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "./interfaces/IPrizeTierHistory.sol";
/**
  * @title  PoolTogether V4 IPrizeTierHistory
  * @author PoolTogether Inc Team
  * @notice IPrizeTierHistory is the base contract for PrizeTierHistory
*/
contract PrizeTierHistory is IPrizeTierHistory, Manageable {

    /* ============ Global Variables ============ */
    /**
      * @notice The Draw ID used to initialize the history. 
      * @dev    Start Draw ID is SSTOREd and used as a reference for searches/lookups.
                The start Draw ID can be used to calculate the relative position of any PrizeTier 
                using a Draw ID if the starting Draw ID is known.
     */
    uint32 internal startDrawId;

    /**
      * @notice Default PrizeTiers
     */
    PrizeTierDefaults internal defaults;
    
    /**
      * @notice History of PrizeTier updates
     */
    PrizeTier[] internal history;

    /* ============ Constructor ============ */

    constructor(
      address _owner,
      uint8 _bitRangeSize,
      uint32 _maxPicksPerUser,
      uint32[16] memory _tiers
    ) Ownable(_owner) {
      PrizeTierDefaults memory _defaults = defaults;

      // UPDATE PrizeTier default parameters
      _defaults.bitRangeSize = _bitRangeSize;
      _defaults.maxPicksPerUser = _maxPicksPerUser;
      _defaults.tiers = _tiers;

      // SSTORE update defaults with initial parameters
      defaults = _defaults;
    }
    
    /* ============ External Functions ============ */

    // @inheritdoc IPrizeTierHistory
    function push(DrawPrizeDistribution calldata _drawPrizeDistribution) external override onlyManager returns (uint32 drawId) {
      PrizeTierDefaults memory _defaults = defaults;

      // CREATE new PrizeTier using default parameters and incoming DrawPrizeDistribution parameters.
      PrizeTier memory _nextPrizeTier = PrizeTier({
        bitRangeSize:     _defaults.bitRangeSize,
        drawId:           _drawPrizeDistribution.drawId,
        maxPicksPerUser:  _defaults.maxPicksPerUser,
        tiers:       _defaults.tiers,
        validityDuration: _drawPrizeDistribution.drawStart + _defaults.prizeExpirationSeconds, // Sets prize claim expiration date/timestamp`
        prize:            _drawPrizeDistribution.prize
      });
      
      PrizeTier[] memory _history = history;
      if(_history.length > 0) {
        // READ the newest PrizeTier struct
        PrizeTier memory _newPrizeTier = history[history.length - 1];

        // New PrizeTier ID must only be 1 greater than the last PrizeTier ID.
        require(_nextPrizeTier.drawId == _newPrizeTier.drawId + 1, "PrizeTierHistory/non-sequential-prize-tier");
      } else {
        startDrawId = _drawPrizeDistribution.drawId;
      }

      history.push(_nextPrizeTier);
    }
    

    // @inheritdoc IPrizeTierHistory
    function getPrizeTier(uint32 _drawId) external view override returns (PrizeTier memory prizeTier) {
      return history[_drawId - startDrawId];
    }
    
    // @inheritdoc IPrizeTierHistory
    function getPrizeTierList(uint32[] calldata _drawIds) external view override returns (PrizeTier[] memory prizeTier) {
      PrizeTier[] memory _data = new PrizeTier[](_drawIds.length) ;
      PrizeTier[] memory _history = history;
      uint32 _startDrawId = startDrawId;
      for (uint256 index = 0; index < _drawIds.length; index++) {
        _data[index] = history[_drawIds[index] - _startDrawId]; // SLOAD each struct instead of the whole array before the FOR loop.
      }
      return _data;
    }
    
    // @inheritdoc IPrizeTierHistory
    function setPrizeTier(PrizeTier calldata _prizeTier) external override onlyOwner returns (uint32 drawId) {
      uint32 _idx = _prizeTier.drawId - startDrawId;
      history[_idx] = _prizeTier;
      emit PrizeTierSet(_idx, _prizeTier.drawId, _prizeTier);
    }

    // @inheritdoc IPrizeTierHistory
    function setDefaults(PrizeTierDefaults calldata _defaults) external override onlyOwner {
      defaults = _defaults;
      emit PrizeTierDefaultsSet(_defaults);
    }

}