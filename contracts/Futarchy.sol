pragma solidity ^0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/common/IForwarder.sol";
import "@aragon/os/contracts/lib/math/SafeMath64.sol";
import '@gnosis.pm/pm-contracts/contracts/Oracles/FutarchyOracleFactory.sol';
import '@gnosis.pm/pm-contracts/contracts/MarketMakers/LMSRMarketMaker.sol';
import '@gnosis.pm/pm-contracts/contracts/Oracles/CentralizedOracleFactory.sol';
import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import '@gnosis.pm/pm-contracts/contracts/Tokens/ERC20Gnosis.sol';

contract Futarchy is AragonApp {
  using SafeMath64 for uint64;

  event StartDecision(uint indexed decisionId, address indexed creator, string metadata, FutarchyOracle futarchyOracle);
  event ExecuteDecision(uint decisionId);

  bytes32 public constant CREATE_DECISION_ROLE = keccak256("CREATE_DECISION_ROLE");

  FutarchyOracleFactory public futarchyOracleFactory;
  MiniMeToken public token;
  CentralizedOracleFactory public priceOracleFactory;
  LMSRMarketMaker public lmsrMarketMaker;
  uint24 public fee;
  uint public tradingPeriod;

  struct Decision {
    FutarchyOracle futarchyOracle;
    uint64 startDate;
    uint tradingPeriod;
    uint64 snapshotBlock;
    bool executed;
    string metadata;
    bytes executionScript;
  }

  mapping(uint256 => Decision) public decisions;
  uint public decisionLength;

  modifier decisionExists(uint256 _decisionId) {
      require(_decisionId < decisionLength);
      _;
  }

    /**
    * @notice initialize Futarchy app with state
    * @param _fee Percent trading fee prediction markets will collect
    * @param _tradingPeriod trading period before decision can be determined
    * @param _token token used to participate in prediction markets
    * @param _futarchyOracleFactory creates FutarchyOracle to begin new decision
    *         https://github.com/gnosis/pm-contracts/blob/v1.0.0/contracts/Oracles/FutarchyOracleFactory.sol
    * @param _priceOracleFactory oracle factory used to create oracles that resolve price after all trading is closed
    * @param _lmsrMarketMaker market maker library that calculates prediction market outomce token prices
    * FutarchyOracleFactory comes from Gnosis https://github.com/gnosis/pm-contracts/blob/v1.0.0/contracts/Oracles/FutarchyOracleFactory.sol
    * TODO: BoundsOracle - Calculates the upper and lower bounds for creating a new FutarchyOracle
    * TODO: PriceFeedOracle - Is used to resolve all futarchy decision markets
    **/
    function initialize(
      uint24 _fee,
      uint _tradingPeriod,
      MiniMeToken _token,
      FutarchyOracleFactory _futarchyOracleFactory,
      CentralizedOracleFactory _priceOracleFactory,
      LMSRMarketMaker _lmsrMarketMaker
    )
      onlyInit
      public
    {
      initialized();
      fee = _fee;
      tradingPeriod = _tradingPeriod;
      token = _token;
      futarchyOracleFactory = _futarchyOracleFactory;
      priceOracleFactory = _priceOracleFactory;
      lmsrMarketMaker = _lmsrMarketMaker;
    }


    /**
    * @notice creates a new futarchy decision market related to `metadata`
    * @param executionScript EVM script to be executed on approval
    * @param metadata Decision metadata
    **/
    function newDecision(
      bytes executionScript,
      string metadata
    )
      public
      auth(CREATE_DECISION_ROLE)
      returns (uint decisionId)
    {
      int lowerBound;
      int upperBound;
      decisionId = decisionLength++;
      decisions[decisionId].startDate = getTimestamp64();
      decisions[decisionId].tradingPeriod = tradingPeriod; // set tradingPeriod to protect against future variable updates
      decisions[decisionId].metadata = metadata;
      decisions[decisionId].snapshotBlock = getBlockNumber64() - 1;
      decisions[decisionId].executionScript = executionScript;
      (lowerBound, upperBound) = _calculateBounds();

      decisions[decisionId].futarchyOracle = futarchyOracleFactory.createFutarchyOracle(
        ERC20Gnosis(token),
        priceOracleFactory.createCentralizedOracle("QmWmyoMoctfbAaiEs2G46gpeUmhqFRDW6KWo64y5r581Vz"),
        2,
        lowerBound,
        upperBound,
        lmsrMarketMaker,
        fee,
        tradingPeriod,
        decisions[decisionId].startDate
      );

      emit StartDecision(decisionId, msg.sender, metadata, decisions[decisionId].futarchyOracle);
    }

    /**
    * @notice returns data about decision
    * @param decisionId decision unique identifier
    **/
    function getDecision(uint decisionId)
      public
      view
      decisionExists(decisionId)
      returns (
        bool open,
        bool executed,
        uint64 startDate,
        uint64 snapshotBlock,
        uint256 marketPower,
        bytes script

        )
    {
      Decision storage decision = decisions[decisionId];
      open = !decision.futarchyOracle.isOutcomeSet();
      executed = decision.executed;
      startDate = decision.startDate;
      snapshotBlock = decision.snapshotBlock;
      marketPower = token.totalSupplyAt(decision.snapshotBlock);
      script = decision.executionScript;
    }

    /**
    * TODO: enable special permissions for executing decisions
    * TODO: create data to signal "cannot execute, so don't even try" (??)
    * @notice execute decision if final decision is ready and equals YES; otherwise Revert
    * @param decisionId decision unique identifier
    */
    function executeDecision(uint decisionId) public {
      Decision storage decision = decisions[decisionId];

      require(!decision.executed);
      require(tradingPeriodEnded(decisionId));
      if (!decision.futarchyOracle.isOutcomeSet()) {
          decision.futarchyOracle.setOutcome();
      }
      require(decision.futarchyOracle.getOutcome() == 0); // 0 == YES; 1 == NO

      bytes memory input = new bytes(0); // TODO: (aragon comment) Consider including input for decision scripts
      runScript(decision.executionScript, input, new address[](0));

      decision.executed = true;
      emit ExecuteDecision(decisionId);
    }

    /**
    * @notice returns true if the trading period before making the decision has passed
    * @param decisionId decision unique identifier
    */
    function tradingPeriodEnded(uint decisionId) public view returns(bool) {
      Decision storage decision = decisions[decisionId];
      return (now > decision.startDate.add(uint64(decision.tradingPeriod)));
    }

    /* TODO: actually get real bounds */
    function _calculateBounds() internal returns(int lowerBound, int upperBound) {
      lowerBound = 0;
      upperBound = 100;
    }

    /* IForwarder API */

    /* @notice confirms Futarchy implements IForwarder */
    function isForwarder() external pure returns (bool) {
      return true;
    }

    /**
    * @notice Creates a new decision to execute the desired action
    * @dev IForwarder interface conformance
    * @param evmCallScript executionScript for a successful YES decision
    */
    function forward(bytes evmCallScript) public {
      require(canForward(msg.sender, evmCallScript));
      newDecision(evmCallScript, '');
    }

    /**
    * @notice Confirms whether sender has permissions to forward the action
    * @dev IForwarder interface conformance
    * @param sender msg.sender
    * @param evmCallScript script to execute upon successful YES decision
    */
    function canForward(address sender, bytes evmCallScript) public returns (bool) {
      return canPerform(sender, CREATE_DECISION_ROLE, arr());
    }
}
