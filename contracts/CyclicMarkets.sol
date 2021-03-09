pragma solidity 0.5.7;

contract CyclicMarkets {

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

    MarketCurrency[] internal marketCurrencies;
    MarketTypeData[] internal marketTypeArray;
    mapping(bytes32 => uint) internal marketCurrency;

    mapping(uint64 => uint32) internal marketType;
    mapping(uint256 => mapping(uint256 => MarketCreationData)) internal marketCreationData;

    
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

}