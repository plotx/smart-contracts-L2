pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IbLOTToken.sol";
import "./interfaces/IMarketCreationRewards.sol";
import "./interfaces/IAuth.sol";
import "./interfaces/IOracle.sol";

contract IMaster {
    function dAppToken() public view returns(address);
    function getLatestAddress(bytes2 _module) public view returns(address);
}

contract CyclicMarkets is IAuth, NativeMetaTransaction {
    using SafeMath32 for uint32;
    using SafeMath64 for uint64;
    using SafeMath128 for uint128;
    using SafeMath for uint;

    enum PredictionStatus {
      Live,
      InSettlement,
      Cooling,
      InDispute,
      Settled
    }

    event OptionPricingParams(uint256 indexed marketIndex, uint256 _stakingFactorMinStake,uint32 _stakingFactorWeightage,uint256 _currentPriceWeightage,uint32 _minTimePassed);
    event MarketTypes(uint256 indexed index, uint32 predictionTime, uint32 cooldownTime, uint32 optionRangePerc, bool status, uint32 minTimePassed);
    event MarketCurrencies(uint256 indexed index, address feedAddress, bytes32 currencyName, bool status);

    struct MarketTypeData {
      uint32 predictionTime;
      uint32 optionRangePerc;
      uint32 cooldownTime;
      uint32 minTimePassed;
      bool paused;
    }

    struct MarketCurrency {
      bytes32 currencyName;
      address marketFeed;
      uint8 decimals;
      uint8 roundOfToNearest;
    }

    struct MarketCreationData {
      uint32 initialStartTime;
      uint64 latestMarket;
      uint64 penultimateMarket;
      bool paused;
    }

    struct PricingData {
      uint256 stakingFactorMinStake;
      uint32 stakingFactorWeightage;
      uint32 currentPriceWeightage;
      uint32 minTimePassed;
    }

    struct MarketFeeParams {
      uint32 cummulativeFeePercent;
      uint32 daoCommissionPercent;
      uint32 referrerFeePercent;
      uint32 refereeFeePercent;
      uint32 marketCreatorFeePercent;
      mapping (uint256 => uint64) daoFee;
      mapping (uint256 => uint64) marketCreatorFee;
    }

    MarketFeeParams internal marketFeeParams;

    address internal masterAddress;
    address internal plotToken;
    address internal disputeResolution;
    address internal predictionToken;

    IbLOTToken internal bPLOTInstance;
    IMarketCreationRewards internal marketCreationRewards;

    MarketCurrency[] internal marketCurrencies;
    MarketTypeData[] internal marketTypeArray;
    mapping(bytes32 => uint) internal marketCurrency;

    mapping(uint64 => uint32) internal marketType;
    mapping(uint256 => mapping(uint256 => MarketCreationData)) internal marketCreationData;

    mapping(uint256 => PricingData) internal marketPricingData;
    mapping(address => bool) public authorizedAddresses;

    uint internal totalOptions;
    uint internal minPredictionAmount ;
    uint internal maxPredictionAmount ;
    uint internal stakingFactorMinStake ;
    uint32 internal stakingFactorWeightage ;
    uint32 internal currentPriceWeightage ;

    modifier onlyAuthorizedUsers() {
        require(authorizedAddresses[msg.sender]);
        _;
    }

    /**
    * @dev Function to set authorized address
    **/
    function addAuthorizedAddress(address _address) external onlyAuthorizedUsers {
        authorizedAddresses[_address] = true;
    }
    
    /**
    * @dev Add new market currency.
    * @param _currencyName name of the currency
    * @param _marketFeed Price Feed address of the currency
    * @param decimals Decimals of the price provided by feed address
    * @param roundOfToNearest Round of the price to nearest number
    * @param _marketStartTime Start time of initial markets
    */
    function addMarketCurrency(bytes32 _currencyName, address _marketFeed, uint8 decimals, uint8 roundOfToNearest, uint32 _marketStartTime) external onlyAuthorized {
      require((marketCurrencies[marketCurrency[_currencyName]].currencyName != _currencyName));
      require(decimals != 0);
      require(roundOfToNearest != 0);
      require(_marketFeed != address(0));
      _addMarketCurrency(_currencyName, _marketFeed, decimals, roundOfToNearest, _marketStartTime);
    }

    /**
    * @dev Internal Function to add market currency
    * @param _currencyName name of the currency
    * @param _marketFeed Price Feed address of the currency
    * @param decimals Decimals of the price provided by feed address
    * @param roundOfToNearest Round of the price to nearest number
    * @param _marketStartTime Start time of initial markets
    */
    function _addMarketCurrency(bytes32 _currencyName, address _marketFeed, uint8 decimals, uint8 roundOfToNearest, uint32 _marketStartTime) internal {
      uint32 index = uint32(marketCurrencies.length);
      marketCurrency[_currencyName] = index;
      marketCurrencies.push(MarketCurrency(_currencyName, _marketFeed, decimals, roundOfToNearest));
      emit MarketCurrencies(index, _marketFeed, _currencyName, true);
      for(uint32 i = 0;i < marketTypeArray.length; i++) {
          marketCreationData[i][index].initialStartTime = _marketStartTime;
      }
    }

    /**
    * @dev Add market type.
    * @param _predictionTime The time duration of market.
    * @param _optionRangePerc Option range percent of neutral min, max options (raised by 2 decimals)
    * @param _marketStartTime Start time of first market to be created in this type
    * @param _marketCooldownTime Cool down time of the market after market is settled
    * @param _minTimePassed Minimum amount of time to be passed for the time factor to be kicked in while calculating option price
    */
    function addMarketType(uint32 _predictionTime, uint32 _optionRangePerc, uint32 _marketStartTime, uint32 _marketCooldownTime, uint32 _minTimePassed) external onlyAuthorized {
      require(marketTypeArray[marketType[_predictionTime]].predictionTime != _predictionTime);
      require(_predictionTime > 0);
      require(_optionRangePerc > 0);
      require(_marketCooldownTime > 0);
      require(_minTimePassed > 0);
      uint32 index = _addMarketType(_predictionTime, _optionRangePerc, _marketCooldownTime, _minTimePassed);
      for(uint32 i = 0;i < marketCurrencies.length; i++) {
          marketCreationData[index][i].initialStartTime = _marketStartTime;
      }
    }

    /**
    * @dev Internal function add market type.
    * @param _predictionTime The time duration of market.
    * @param _optionRangePerc Option range percent of neutral min, max options (raised by 2 decimals)
    * @param _marketCooldownTime Cool down time of the market after market is settled
    * @param _minTimePassed Minimum amount of time to be passed for the time factor to be kicked in while calculating option price
    */
    function _addMarketType(uint32 _predictionTime, uint32 _optionRangePerc, uint32 _marketCooldownTime, uint32 _minTimePassed) internal returns(uint32) {
      uint32 index = uint32(marketTypeArray.length);
      marketType[_predictionTime] = index;
      marketTypeArray.push(MarketTypeData(_predictionTime, _optionRangePerc, _marketCooldownTime, _minTimePassed, false));
      emit MarketTypes(index, _predictionTime, _marketCooldownTime, _optionRangePerc, true, _minTimePassed);
      return index;
    }

    /**
    * @dev Update market type.
    * @param _marketType Index of the updating market type.
    * @param _optionRangePerc Option range percent of neutral min, max options (raised by 2 decimals)
    * @param _marketCooldownTime Cool down time of the market after market is settled
    * @param _minTimePassed Minimum amount of time to be passed for the time factor to be kicked in while calculating option price
    */
    function updateMarketType(uint32 _marketType, uint32 _optionRangePerc, uint32 _marketCooldownTime, uint32 _minTimePassed) external onlyAuthorized {
      require(_optionRangePerc > 0);
      require(_marketCooldownTime > 0);
      require(_minTimePassed > 0);
      MarketTypeData storage _marketTypeArray = marketTypeArray[_marketType];
      require(_marketTypeArray.predictionTime != 0);
      _marketTypeArray.optionRangePerc = _optionRangePerc;
      _marketTypeArray.cooldownTime = _marketCooldownTime;
      _marketTypeArray.minTimePassed = _minTimePassed;
      emit MarketTypes(_marketType, _marketTypeArray.predictionTime, _marketCooldownTime, _optionRangePerc, true, _minTimePassed);
    }

    /**
    * @dev Start the initial market and set initial variables.
    * @param _marketStartTime Starttime of the initial market of protocol
    * @param _ethFeed Feed Address of initial eth/usd market
    * @param _btcFeed Feed Address of btc/usd market
    */
    function addInitialMarketTypesAndStart(uint32 _marketStartTime, address _ethFeed, address _btcFeed) external onlyAuthorizedUsers {
      require(marketTypeArray.length == 0);
      require(_ethFeed != address(0));
      require(_btcFeed != address(0));
      
      IMaster ms = IMaster(masterAddress);
      marketCreationRewards = IMarketCreationRewards(ms.getLatestAddress("MC"));
      disputeResolution = ms.getLatestAddress("DR");
      
      totalOptions = 3;
      stakingFactorMinStake = uint(20000).mul(10**8);
      stakingFactorWeightage = 40;
      currentPriceWeightage = 60;
      minPredictionAmount = 10 ether; // Need to be updated
      maxPredictionAmount = 100000 ether; // Need to be updated
      MarketFeeParams storage _marketFeeParams = marketFeeParams;
      _marketFeeParams.cummulativeFeePercent = 200;
      _marketFeeParams.daoCommissionPercent = 1000;
      _marketFeeParams.refereeFeePercent = 1000;
      _marketFeeParams.referrerFeePercent = 2000;
      _marketFeeParams.marketCreatorFeePercent = 4000;
      
      _addMarketType(4 hours, 100, 1 hours, 40 minutes);
      _addMarketType(24 hours, 200, 6 hours, 4 hours);
      _addMarketType(168 hours, 500, 8 hours, 28 hours);

      _addMarketCurrency("ETH/USD", _ethFeed, 8, 1, _marketStartTime);
      _addMarketCurrency("BTC/USD", _btcFeed, 8, 25, _marketStartTime);

      for(uint32 i = 0;i < marketTypeArray.length; i++) {
          createMarket(0, i, 0);
          createMarket(1, i, 0);
      }
      _initializeEIP712("AM");
    }

    /**
    * @dev Create the market.
    * @param _marketCurrencyIndex The index of market currency feed
    * @param _marketTypeIndex The time duration of market.
    * @param _roundId Round Id to settle previous market (If applicable, else pass 0)
    */
    function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public {
      MarketTypeData storage _marketType = marketTypeArray[_marketTypeIndex];
      MarketCurrency storage _marketCurrency = marketCurrencies[_marketCurrencyIndex];
      require(!_marketType.paused);
      _closePreviousMarketWithRoundId( _marketTypeIndex, _marketCurrencyIndex, _roundId);
      uint32 _startTime = calculateStartTimeForMarket(_marketCurrencyIndex, _marketTypeIndex);
      // uint64 _marketIndex = allMarkets.createMarket();
      uint64 _marketIndex;
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      (_marketCreationData.penultimateMarket, _marketCreationData.latestMarket) =
       (_marketCreationData.latestMarket, _marketIndex);
      marketPricingData[_marketIndex] = PricingData(stakingFactorMinStake, stakingFactorWeightage, currentPriceWeightage, _marketType.minTimePassed);
      
      emit OptionPricingParams(_marketIndex, stakingFactorMinStake,stakingFactorWeightage,currentPriceWeightage,_marketType.minTimePassed);
    }

    /**
    * @dev Calculate start time for next market of provided currency and market type indexes
    * @param _marketCurrencyIndex Index of the market currency
    * @param _marketType Index of the market type
    */
    function calculateStartTimeForMarket(uint32 _marketCurrencyIndex, uint32 _marketType) public view returns(uint32 _marketStartTime) {
      _marketStartTime = marketCreationData[_marketType][_marketCurrencyIndex].initialStartTime;
      uint predictionTime = marketTypeArray[_marketType].predictionTime;
      if(now > (predictionTime) + (_marketStartTime)) {
        uint noOfMarketsCycles = ((now) - (_marketStartTime)) / (predictionTime);
       _marketStartTime = uint32((noOfMarketsCycles * (predictionTime)) + (_marketStartTime));
      }
    }

    /**
    * @dev Internal function to settle the previous market 
    * @param _marketTypeIndex Index of the market type
    * @param _marketCurrencyIndex Index of the market currency
    * @param _roundId RoundId of the feed for the settlement price
    */
    function _closePreviousMarketWithRoundId(uint64 _marketTypeIndex, uint64 _marketCurrencyIndex, uint80 _roundId) internal {
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      uint64 currentMarket = _marketCreationData.latestMarket;
      if(currentMarket != 0) {
        // require(allMarkets.marketStatus(currentMarket) >= PredictionStatus.InSettlement);
        uint64 penultimateMarket = _marketCreationData.penultimateMarket;
        // if(penultimateMarket > 0 && now >= allMarkets.marketSettleTime(penultimateMarket)) {
          // _settleMarket(penultimateMarket, _roundId);
          // _settleMarket(penultimateMarket, _settlementPrice);
        // }
      }
    }

    /**
    * @dev Settle the market, setting the winning option
    * @param _marketId Index of market
    * @param _roundId RoundId of the feed for the settlement price
    */
    function settleMarket(uint256 _marketId, uint80 _roundId) external {
      // address _feedAdd = marketBasicData[_marketId].feedAddress;
      // (uint256 _value, uint256 _roundIdUsed) = IOracle(_feedAdd).getSettlementPrice(marketSettleTime(_marketId), _roundId);
      // allMarkets.settleMarket(_marketId, _value);
    }


    /**
    * @dev Set the flag to pause/resume market creation of particular market type
    */
    function toggleMarketCreationType(uint64 _marketTypeIndex, bool _flag) external onlyAuthorized {
      MarketTypeData storage _marketType = marketTypeArray[_marketTypeIndex];
      require(_marketType.paused != _flag);
      _marketType.paused = _flag;
    }


}