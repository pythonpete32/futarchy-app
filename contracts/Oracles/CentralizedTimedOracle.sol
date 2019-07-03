pragma solidity ^0.4.24;

import './TimedOracle.sol';
import './ScalarPriceOracleBase.sol';

contract CentralizedTimedOracle is ScalarPriceOracleBase, TimedOracle {
  address public owner;
  bytes public ipfsHash;

  modifier isOwner () {
    // Only owner is allowed to proceed
    require(msg.sender == owner);
    _;
  }

  constructor(
    address _owner,
    bytes _ipfsHash,
    uint _resolutionDate
  ) public
    TimedOracle(_resolutionDate)
  {
    owner = _owner;
    ipfsHash = _ipfsHash;
  }

  /**
  * @dev Sets event outcome
  * @param _outcome Event outcome
  */
  function setOutcome(int _outcome) public resolutionDatePassed isOwner {
    ScalarPriceOracleBase.setOutcome(_outcome);
  }
}
