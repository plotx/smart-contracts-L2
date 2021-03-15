pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IbLOTToken.sol";
import "./interfaces/IAuth.sol";
import "./interfaces/IAllMarkets.sol";
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

    event MarketParams(uint256 indexed marketIndex, uint256 marketType, bytes32 currencyName, uint256 _stakingFactorMinStake,uint32 _stakingFactorWeightage,uint256 _currentPriceWeightage,uint32 _minTimePassed);
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

    struct MarketData {
      uint64 marketTypeIndex;
      uint64 marketCurrencyIndex;
    }

    MarketFeeParams internal marketFeeParams;

    address internal masterAddress;
    address internal plotToken;
    IAllMarkets internal allMarkets;

    MarketCurrency[] internal marketCurrencies;
    MarketTypeData[] internal marketTypeArray;
    mapping(bytes32 => uint) internal marketCurrency;

    mapping(uint64 => uint32) internal marketType;
    mapping(uint256 => mapping(uint256 => MarketCreationData)) public marketCreationData;

    mapping(uint256 => PricingData) internal marketPricingData;
    address public authorizedAddress;
    mapping(uint256 => MarketData) public marketData;

    uint internal totalOptions;
    uint internal stakingFactorMinStake ;
    uint32 internal stakingFactorWeightage ;
    uint32 internal currentPriceWeightage ;

    modifier onlyAuthorizedUsers() {
        require(authorizedAddress == msg.sender);
        _;
    }

    /**
     * @dev Changes the master address and update it's instance
     * @param _authorizedMultiSig Authorized address to execute critical functions in the protocol.
     * @param _defaultAuthorizedAddress Authorized address to trigger initial functions by passing required external values.
     */
    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner());
      IMaster ms = IMaster(msg.sender);
      masterAddress = msg.sender;
      address _plotToken = ms.dAppToken();
      plotToken = _plotToken;
      allMarkets = IAllMarkets(ms.getLatestAddress("AM"));
      authorizedAddress = _defaultAuthorizedAddress;
      authorized = _authorizedMultiSig;
      _initializeEIP712("CM");
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
    * @dev function to update integer parameters
    * @param code Code of the updating parameter.
    * @param value Value to which the parameter should be updated
    */
    function updateUintParameters(bytes8 code, uint256 value) external onlyAuthorized {
      if(code == "CPW") { // Current price weighage
        require(value <= 100);
        currentPriceWeightage = uint32(value);
        //Staking factor weightage% = 100% - currentPriceWeightage%
        stakingFactorWeightage = 100 - currentPriceWeightage;
      } else if(code == "SFMS") { // Minimum amount for staking factor to apply
        stakingFactorMinStake = value;
      } else {
        revert("Invalid code");
      }
    }

    /**
    * @dev function to get integer parameters
    * @param code Code of the parameter.
    * @return codeVal Code of the parameter.
    * @return value Value of the queried parameter.
    */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value) {
      codeVal = code;
      if(code == "CPW") { // Current price weighage
        value = currentPriceWeightage;
      } else if(code == "SFMS") { // Minimum amount for staking factor to apply
        value = stakingFactorMinStake;
      }
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

      totalOptions = 3;
      stakingFactorMinStake = uint(20000).mul(10**8);
      stakingFactorWeightage = 40;
      currentPriceWeightage = 60;
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
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      require(!_marketType.paused && !_marketCreationData.paused);
      _closePreviousMarketWithRoundId( _marketTypeIndex, _marketCurrencyIndex, _roundId);
      uint32 _startTime = calculateStartTimeForMarket(_marketCurrencyIndex, _marketTypeIndex);
      (uint64 _minValue, uint64 _maxValue) = _calculateOptionRange(_marketType.optionRangePerc, _marketCurrency.decimals, _marketCurrency.roundOfToNearest, _marketCurrency.marketFeed);
      uint32[] memory _marketTimes = new uint32[](4);
      uint64[] memory _optionRanges = new uint64[](2);
      _marketTimes[0] = _startTime; 
      _marketTimes[1] = _marketType.predictionTime;
      _marketTimes[2] = _marketType.predictionTime*2;
      _marketTimes[3] = _marketType.cooldownTime;
      _optionRanges[0] = _minValue;
      _optionRanges[1] = _maxValue;
      uint64 _marketIndex = allMarkets.getTotalMarketsLength();
      marketPricingData[_marketIndex] = PricingData(stakingFactorMinStake, stakingFactorWeightage, currentPriceWeightage, _marketType.minTimePassed);
      allMarkets.createMarket(_marketTimes, _optionRanges, _msgSender());
      marketData[_marketIndex] = MarketData(_marketTypeIndex, _marketCurrencyIndex);
      // uint64 _marketIndex;
      (_marketCreationData.penultimateMarket, _marketCreationData.latestMarket) =
       (_marketCreationData.latestMarket, _marketIndex);
      
      emit MarketParams(_marketIndex, _marketTypeIndex, _marketCurrency.currencyName, stakingFactorMinStake,stakingFactorWeightage,currentPriceWeightage,_marketType.minTimePassed);
    }


    /**
    * @dev Internal function to perfrom ceil operation of given params
    */
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
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
        require(uint(allMarkets.marketStatus(currentMarket)) >= uint(PredictionStatus.InSettlement));
        uint64 penultimateMarket = _marketCreationData.penultimateMarket;
        if(penultimateMarket > 0 && now >= allMarkets.marketSettleTime(penultimateMarket)) {
          settleMarket(penultimateMarket, _roundId);
          // _settleMarket(penultimateMarket, _settlementPrice);
        }
      }
    }

    /**
     * @dev Internal function to calculate option ranges for the market
     * @param _optionRangePerc Defined Option percent
     * @param _decimals Decimals of the given feed address
     * @param _roundOfToNearest Round of the option range to the nearest multiple
     * @param _marketFeed Market Feed address
     */
    function _calculateOptionRange(uint _optionRangePerc, uint64 _decimals, uint8 _roundOfToNearest, address _marketFeed) internal view returns(uint64 _minValue, uint64 _maxValue) {
      uint currentPrice = IOracle(_marketFeed).getLatestPrice();
      uint optionRangePerc = currentPrice.mul(_optionRangePerc.div(2)).div(10000);
      _minValue = uint64((ceil(currentPrice.sub(optionRangePerc).div(_roundOfToNearest), 10**_decimals)).mul(_roundOfToNearest));
      _maxValue = uint64((ceil(currentPrice.add(optionRangePerc).div(_roundOfToNearest), 10**_decimals)).mul(_roundOfToNearest));
    }

    /**
    * @dev Settle the market, setting the winning option
    * @param _marketId Index of market
    * @param _roundId RoundId of the feed for the settlement price
    */
    function settleMarket(uint256 _marketId, uint80 _roundId) public {
      address _feedAdd = marketCurrencies[marketData[_marketId].marketCurrencyIndex].marketFeed;
      (uint256 _value, uint256 _roundIdUsed) = IOracle(_feedAdd).getSettlementPrice(allMarkets.marketSettleTime(_marketId), _roundId);
      allMarkets.settleMarket(_marketId, _value);
    }

    /**
    * @dev Set the flag to pause/resume market creation of particular market type and currency pair
    */
    function toggleTypeAndCurrencyPairCreation(uint64 _marketTypeIndex, uint64 _marketCurrencyIndex, bool _flag) external onlyAuthorized {
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      
      require(_marketCreationData.paused != _flag);
      _marketCreationData.paused = _flag;
    }

    /**
    * @dev Set the flag to pause/resume market creation of particular market type
    */
    function toggleMarketCreationType(uint64 _marketTypeIndex, bool _flag) external onlyAuthorized {
      MarketTypeData storage _marketType = marketTypeArray[_marketTypeIndex];
      require(_marketType.paused != _flag);
      _marketType.paused = _flag;
    }

    /**
     * @dev Gets price for given market and option
     * @param _marketId  Market ID
     * @param _prediction  prediction option
     * @return  option price
     **/
    function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64) {
      // MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      (uint[] memory _optionPricingParams, uint32 _startTime) = allMarkets.getMarketOptionPricingParams(_marketId,_prediction);
      PricingData storage _marketPricingData = marketPricingData[_marketId];
      (,,uint _predictionTime,,) = allMarkets.getMarketData(_marketId);
      uint stakingFactorConst;
      uint optionPrice; 
      uint256 totalStaked = _optionPricingParams[1];
      // Checking if current stake in market reached minimum stake required for considering staking factor.
      if(totalStaked > _marketPricingData.stakingFactorMinStake)
      {
        // 10000 / staking weightage
        stakingFactorConst = uint(10000).div(_marketPricingData.stakingFactorWeightage); 
        // (stakingFactorConst x Amount staked in option x 10^18) / Total staked in market --- (1)
        optionPrice = (stakingFactorConst.mul(_optionPricingParams[0]).mul(10**18).div(totalStaked)); 
      }
      uint timeElapsed = uint(now).sub(_startTime);
      // max(timeElapsed, minTimePassed)
      if(timeElapsed < _marketPricingData.minTimePassed) {
        timeElapsed = _marketPricingData.minTimePassed;
      }
      uint[] memory _distanceData = getOptionDistanceData(_marketId,_prediction);

      // (Time Elapsed x 10000) / ((Max Distance + 1) x currentPriceWeightage)
      uint timeFactor = timeElapsed.mul(10000).div((_distanceData[0].add(1)).mul(_marketPricingData.currentPriceWeightage));

      uint totalTime = _predictionTime;
      // (1) + ((Option Distance from max distance + 1) x timeFactor x 10^18 / Total Prediction Time)  -- (2)
      optionPrice = optionPrice.add((_distanceData[1].add(1)).mul(timeFactor).mul(10**18).div(totalTime));  
      // (2) / ((stakingFactorConst x 10^13) + timeFactor x 10^13 x (cummulative option distaance + 3) / Total Prediction Time)
      optionPrice = optionPrice.div(stakingFactorConst.mul(10**13).add(timeFactor.mul(10**13).mul(_distanceData[2].add(3)).div(totalTime)));

      // option price for `_prediction` in 10^5 format
      return uint64(optionPrice);

    }

    /**
     * @dev Gets price for all the options in a market
     * @param _marketId  Market ID
     * @return _optionPrices array consisting of prices for all available options
     **/
    function getAllOptionPrices(uint _marketId) external view returns(uint64[] memory _optionPrices) {
      _optionPrices = new uint64[](3);
      for(uint i=0;i<3;i++) {
        _optionPrices[i] = getOptionPrice(_marketId,i+1);
      }

    }

    /**
     * @dev Gets price for given market and option
     * @param _marketId  Market ID
     * @param _prediction  prediction option
     * @return  Array consist of Max Distance between current option and any option, predicting Option distance from max distance, cummulative option distance
     **/
    function getOptionDistanceData(uint _marketId,uint _prediction) internal view returns(uint[] memory) {
      (uint64[] memory _optionRanges,,,,) = allMarkets.getMarketData(_marketId);
      // [0]--> Max Distance between current option and any option, (For 3 options, if current option is 2 it will be `1`. else, it will be `2`) 
      // [1]--> Predicting option distance from Max distance, (MaxDistance - | currentOption - predicting option |)
      // [2]--> sum of all possible option distances,  
      uint[] memory _distanceData = new uint256[](3); 

      uint _marketCurr = marketData[_marketId].marketCurrencyIndex;

      // Fetching current price
      uint currentPrice = IOracle(marketCurrencies[_marketCurr].marketFeed).getLatestPrice();
      _distanceData[0] = 2;
      // current option based on current price
      uint currentOption;
      _distanceData[2] = 3;
      if(currentPrice < _optionRanges[0])
      {
        currentOption = 1;
      } else if(currentPrice > _optionRanges[1]) {
        currentOption = 3;
      } else {
        currentOption = 2;
        _distanceData[0] = 1;
        _distanceData[2] = 1;
      }

      // MaxDistance - | currentOption - predicting option |
      _distanceData[1] = _distanceData[0].sub(modDiff(currentOption,_prediction)); 
      return _distanceData;
    }

    /**
     * @dev  Calculates difference between `a` and `b`.
     **/
    function modDiff(uint a, uint b) internal pure returns(uint) {
      if(a>b)
      {
        return a.sub(b);
      } else {
        return b.sub(a);
      }
    }
}