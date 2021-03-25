pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IAuth.sol";
import "./interfaces/IAllMarkets.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IUserLevels.sol";

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

    event MarketParams(uint256 indexed marketIndex, address marketCreator, uint256 marketType, bytes32 currencyName, uint256 _stakingFactorMinStake,uint32 _stakingFactorWeightage,uint256 _currentPriceWeightage,uint32 _minTimePassed);
    event MarketTypes(uint256 indexed index, uint32 predictionTime, uint32 cooldownTime, uint32 optionRangePerc, bool status, uint32 minTimePassed, uint64 initialLiquidity);
    event MarketCurrencies(uint256 indexed index, address feedAddress, bytes32 currencyName, bool status);
	  event MarketCreatorReward(address indexed createdBy, uint256 indexed marketIndex, uint256 tokenIncentive);
    event ClaimedMarketCreationReward(address indexed user, uint reward, address predictionToken);

    struct MarketTypeData {
      uint32 predictionTime;
      uint32 optionRangePerc;
      uint32 cooldownTime;
      uint32 minTimePassed;
      uint64 initialLiquidity;
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
      address marketCreator;
    }

    MarketFeeParams internal marketFeeParams;

    address internal masterAddress;
    address internal plotToken;
    IAllMarkets internal allMarkets;
    IReferral public referral;
    IUserLevels public userLevels;

    MarketCurrency[] internal marketCurrencies;
    MarketTypeData[] internal marketTypeArray;
    mapping(bytes32 => uint) internal marketCurrency;

    mapping(uint64 => uint32) internal marketType;
    mapping(uint256 => mapping(uint256 => MarketCreationData)) public marketCreationData;

    mapping(uint256 => PricingData) internal marketPricingData;
    address public authorizedAddress;
    mapping(uint256 => MarketData) public marketData;

    mapping(address => uint256) public marketCreationReward;
    mapping (address => uint256) public relayerFeeEarned;

    mapping(address => mapping(uint256 => bool)) public multiplierApplied;

    uint internal totalOptions;
    uint internal stakingFactorMinStake;
    uint32 internal stakingFactorWeightage;
    uint32 internal currentPriceWeightage;
    uint internal predictionDecimalMultiplier;
    uint internal minPredictionAmount;
    uint internal maxPredictionAmount;

    modifier onlyAuthorizedUsers() {
        require(authorizedAddress == msg.sender);
        _;
    }

    modifier onlyAllMarkets {
      require(msg.sender == address(allMarkets));
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
    * @dev Set the referral contract address, to handle referrals and their fees.
    * @param _referralContract Address of the referral contract
    */
    function setReferralContract(address _referralContract) external onlyAuthorized {
      require(address(referral) == address(0));
      referral = IReferral(_referralContract);
    }

    /**
    * @dev Unset the referral contract address
    */
    function removeReferralContract() external onlyAuthorized {
      require(address(referral) != address(0));
      delete referral;
    }

    /**
    * @dev Set the User levels contract address, to handle user multiplier.
    * @param _userLevelsContract Address of the referral contract
    */
    function setUserLevelsContract(address _userLevelsContract) external onlyAuthorized {
      require(address(userLevels) == address(0));
      userLevels = IUserLevels(_userLevelsContract);
    }

    /**
    * @dev Unset the User levels contract address
    */
    function removeUserLevelsContract() external onlyAuthorized {
      require(address(userLevels) != address(0));
      delete userLevels;
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
    * @param _initialLiquidity Initial liquidity to be provided by the market creator for the market.
    */
    function addMarketType(uint32 _predictionTime, uint32 _optionRangePerc, uint32 _marketStartTime, uint32 _marketCooldownTime, uint32 _minTimePassed, uint64 _initialLiquidity) external onlyAuthorized {
      require(marketTypeArray[marketType[_predictionTime]].predictionTime != _predictionTime);
      require(_predictionTime > 0);
      require(_optionRangePerc > 0);
      require(_marketCooldownTime > 0);
      require(_minTimePassed > 0);
      uint32 index = _addMarketType(_predictionTime, _optionRangePerc, _marketCooldownTime, _minTimePassed, _initialLiquidity);
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
    * @param _initialLiquidity Initial liquidity to be provided by the market creator for the market.
    */
    function _addMarketType(uint32 _predictionTime, uint32 _optionRangePerc, uint32 _marketCooldownTime, uint32 _minTimePassed, uint64 _initialLiquidity) internal returns(uint32) {
      uint32 index = uint32(marketTypeArray.length);
      marketType[_predictionTime] = index;
      marketTypeArray.push(MarketTypeData(_predictionTime, _optionRangePerc, _marketCooldownTime, _minTimePassed, _initialLiquidity, false));
      emit MarketTypes(index, _predictionTime, _marketCooldownTime, _optionRangePerc, true, _minTimePassed, _initialLiquidity);
      return index;
    }

    /**
    * @dev Update market type.
    * @param _marketType Index of the updating market type.
    * @param _optionRangePerc Option range percent of neutral min, max options (raised by 2 decimals)
    * @param _marketCooldownTime Cool down time of the market after market is settled
    * @param _minTimePassed Minimum amount of time to be passed for the time factor to be kicked in while calculating option price
    * @param _initialLiquidity Initial liquidity to be provided by the market creator for the market.
    */
    function updateMarketType(uint32 _marketType, uint32 _optionRangePerc, uint32 _marketCooldownTime, uint32 _minTimePassed, uint64 _initialLiquidity) external onlyAuthorized {
      require(_optionRangePerc > 0);
      require(_marketCooldownTime > 0);
      require(_minTimePassed > 0);
      MarketTypeData storage _marketTypeArray = marketTypeArray[_marketType];
      require(_marketTypeArray.predictionTime != 0);
      _marketTypeArray.optionRangePerc = _optionRangePerc;
      _marketTypeArray.cooldownTime = _marketCooldownTime;
      _marketTypeArray.minTimePassed = _minTimePassed;
      _marketTypeArray.initialLiquidity = _initialLiquidity;
      emit MarketTypes(_marketType, _marketTypeArray.predictionTime, _marketCooldownTime, _optionRangePerc, true, _minTimePassed, _initialLiquidity);
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
      } else if(code == "MINP") { // Minimum prediction amount
        minPredictionAmount = value;
      } else if(code == "MAXP") { // Maximum prediction amount
        maxPredictionAmount = value;
      } else {
        MarketFeeParams storage _marketFeeParams = marketFeeParams;
        require(value < 10000);
        if(code == "CMFP") { // Cummulative fee percent
          _marketFeeParams.cummulativeFeePercent = uint32(value);
        } else {
          if(code == "DAOF") { // DAO Fee percent in Cummulative fee
            _marketFeeParams.daoCommissionPercent = uint32(value);
          } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
            _marketFeeParams.referrerFeePercent = uint32(value);
          } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
            _marketFeeParams.refereeFeePercent = uint32(value);
          } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
            _marketFeeParams.marketCreatorFeePercent = uint32(value);
          } else {
            revert("Invalid code");
          } 
          require(
            _marketFeeParams.daoCommissionPercent + 
            _marketFeeParams.referrerFeePercent + 
            _marketFeeParams.refereeFeePercent + 
            _marketFeeParams.marketCreatorFeePercent
            < 10000);
        }
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
      } else if(code == "MINP") { // Minimum prediction amount
        value = minPredictionAmount;
      } else if(code == "MAXP") { // Maximum prediction amount
        value = maxPredictionAmount;
      } else if(code == "CMFP") { // Cummulative fee percent
        value = marketFeeParams.cummulativeFeePercent;
      } else if(code == "DAOF") { // DAO Fee percent in Cummulative fee
        value = marketFeeParams.daoCommissionPercent;
      } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
        value = marketFeeParams.referrerFeePercent;
      } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
        value = marketFeeParams.refereeFeePercent;
      } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
        value = marketFeeParams.marketCreatorFeePercent;
      }
    }

    /**
    * @dev Start the initial market and set initial variables.
    * @param _marketStartTime Starttime of the initial market of protocol
    * @param _ethFeed Feed Address of initial eth/usd market
    * @param _btcFeed Feed Address of btc/usd market
    */
    function addInitialMarketTypesAndStart(uint32 _marketStartTime, address _ethFeed, address _btcFeed) external onlyAuthorizedUsers {
      require(_ethFeed != address(0));
      require(_btcFeed != address(0));
      require(marketTypeArray.length == 0);

      totalOptions = 3;
      stakingFactorMinStake = uint(20000).mul(10**8);
      stakingFactorWeightage = 40;
      currentPriceWeightage = 60;
      predictionDecimalMultiplier = 10;
      MarketFeeParams storage _marketFeeParams = marketFeeParams;
      _marketFeeParams.cummulativeFeePercent = 200;
      _marketFeeParams.daoCommissionPercent = 1000;
      _marketFeeParams.refereeFeePercent = 1000;
      _marketFeeParams.referrerFeePercent = 2000;
      _marketFeeParams.marketCreatorFeePercent = 4000;
      minPredictionAmount = 10 ether; // Need to be updated
      maxPredictionAmount = 100000 ether; // Need to be updated
      
      _addMarketType(4 hours, 100, 1 hours, 40 minutes, (100 * 10**8));
      _addMarketType(24 hours, 200, 6 hours, 4 hours, (100 * 10**8));
      _addMarketType(168 hours, 500, 8 hours, 28 hours, (100 * 10**8));

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
      uint32[] memory _marketTimes = new uint32[](4);
      uint64[] memory _optionRanges = new uint64[](2);
      _optionRanges = _calculateOptionRange(_marketType.optionRangePerc, _marketCurrency.decimals, _marketCurrency.roundOfToNearest, _marketCurrency.marketFeed);
      _marketTimes[0] = _startTime; 
      _marketTimes[1] = _marketType.predictionTime;
      _marketTimes[2] = _marketType.predictionTime*2;
      _marketTimes[3] = _marketType.cooldownTime;
      uint64 _marketIndex = allMarkets.getTotalMarketsLength();
      address _msgSenderAddress = _msgSender();
      marketPricingData[_marketIndex] = PricingData(stakingFactorMinStake, stakingFactorWeightage, currentPriceWeightage, _marketType.minTimePassed);
      allMarkets.createMarket(_marketTimes, _optionRanges, _msgSenderAddress, _marketType.initialLiquidity);
      marketData[_marketIndex] = MarketData(_marketTypeIndex, _marketCurrencyIndex, _msgSenderAddress);
      // uint64 _marketIndex;
      (_marketCreationData.penultimateMarket, _marketCreationData.latestMarket) =
       (_marketCreationData.latestMarket, _marketIndex);
      
      emit MarketParams(_marketIndex, _msgSenderAddress, _marketTypeIndex, _marketCurrency.currencyName, stakingFactorMinStake,stakingFactorWeightage,currentPriceWeightage,_marketType.minTimePassed);
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
    function _calculateOptionRange(uint _optionRangePerc, uint64 _decimals, uint8 _roundOfToNearest, address _marketFeed) internal view returns(uint64[] memory _optionRanges) {
      uint currentPrice = IOracle(_marketFeed).getLatestPrice();
      uint optionRangePerc = currentPrice.mul(_optionRangePerc.div(2)).div(10000);
      _optionRanges = new uint64[](2);
      _optionRanges[0] = uint64((ceil(currentPrice.sub(optionRangePerc).div(_roundOfToNearest), 10**_decimals)).mul(_roundOfToNearest));
      _optionRanges[1] = uint64((ceil(currentPrice.add(optionRangePerc).div(_roundOfToNearest), 10**_decimals)).mul(_roundOfToNearest));
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
      if(allMarkets.marketStatus(_marketId) >= IAllMarkets.PredictionStatus.InSettlement) {
        _transferAsset(plotToken, masterAddress, (10**predictionDecimalMultiplier).mul(marketFeeParams.daoFee[_marketId]));
        delete marketFeeParams.daoFee[_marketId];

    	  marketCreationReward[marketData[_marketId].marketCreator] = (10**predictionDecimalMultiplier).mul(marketFeeParams.marketCreatorFee[_marketId]);
        emit MarketCreatorReward(marketData[_marketId].marketCreator, _marketId, (10**predictionDecimalMultiplier).mul(marketFeeParams.marketCreatorFee[_marketId]));
        delete marketFeeParams.marketCreatorFee[_marketId];
      }
    }

    /**
     * @dev Internal function to deduct fee from the prediction amount
     * @param _marketId Index of the market
     * @param _cummulativeFee Total fee amount
     * @param _msgSenderAddress User address
     */
    function handleFee(uint _marketId, uint64 _cummulativeFee, address _msgSenderAddress, address _relayer) external onlyAllMarkets {
      MarketFeeParams storage _marketFeeParams = marketFeeParams;
      // _fee = _calculateAmulBdivC(_marketFeeParams.cummulativeFeePercent, _amount, 10000);
      uint64 _referrerFee = _calculateAmulBdivC(_marketFeeParams.referrerFeePercent, _cummulativeFee, 10000);
      uint64 _refereeFee = _calculateAmulBdivC(_marketFeeParams.refereeFeePercent, _cummulativeFee, 10000);
      bool _isEligibleForReferralReward;
      if(address(referral) != address(0)) {
      _isEligibleForReferralReward = referral.setReferralRewardData(_msgSenderAddress, plotToken, _referrerFee, _refereeFee);
      }
      if(_isEligibleForReferralReward){
        _transferAsset(plotToken, address(referral), (10**predictionDecimalMultiplier).mul(_referrerFee.add(_refereeFee)));
      } else {
        _refereeFee = 0;
        _referrerFee = 0;
      }
      uint64 _daoFee = _calculateAmulBdivC(_marketFeeParams.daoCommissionPercent, _cummulativeFee, 10000);
      uint64 _marketCreatorFee = _calculateAmulBdivC(_marketFeeParams.marketCreatorFeePercent, _cummulativeFee, 10000);
      _marketFeeParams.daoFee[_marketId] = _marketFeeParams.daoFee[_marketId].add(_daoFee);
      _marketFeeParams.marketCreatorFee[_marketId] = _marketFeeParams.marketCreatorFee[_marketId].add(_marketCreatorFee);
      _setRelayerFee(_relayer, _cummulativeFee, _daoFee, _referrerFee, _refereeFee, _marketCreatorFee);
    }

    /**
    * @dev Internal function to set the relayer fee earned in the prediction 
    */
    function _setRelayerFee(address _relayer, uint _cummulativeFee, uint _daoFee, uint _referrerFee, uint _refereeFee, uint _marketCreatorFee) internal {
      relayerFeeEarned[_relayer] = relayerFeeEarned[_relayer].add(_cummulativeFee.sub(_daoFee).sub(_referrerFee).sub(_refereeFee).sub(_marketCreatorFee));
    }

    /**
    * @dev Internal function to calculate prediction points  and multiplier
    * @param _user User Address
    * @param _marketId Index of the market
    * @param _prediction Option predicted by the user
    * @param _stake Amount staked by the user
    */
    function calculatePredictionPointsAndMultiplier(address _user, uint256 _marketId, uint256 _prediction, uint64 _stake) external returns(uint64 predictionPoints){
      bool isMultiplierApplied;
      (predictionPoints, isMultiplierApplied) = calculatePredictionPoints(_marketId, _prediction, _user, multiplierApplied[_user][_marketId], _stake);
      if(isMultiplierApplied) {
        multiplierApplied[_user][_marketId] = true; 
      }
    }

    /**
    * @dev Internal function to calculate prediction points
    * @param _marketId Index of the market
    * @param _prediction Option predicted by the user
    * @param _user User Address
    * @param multiplierApplied Flag defining if user had already availed multiplier
    * @param _predictionStake Amount staked by the user
    */
    function calculatePredictionPoints(uint _marketId, uint256 _prediction, address _user, bool multiplierApplied, uint _predictionStake) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
      uint _stakeValue = _predictionStake.mul(1e10);
      if(_stakeValue < minPredictionAmount || _stakeValue > maxPredictionAmount) {
        return (0, isMultiplierApplied);
      }
      uint64 _optionPrice = getOptionPrice(_marketId, _prediction);
      predictionPoints = uint64(_predictionStake).div(_optionPrice);
      if(!multiplierApplied) {
        uint256 _predictionPoints = predictionPoints;
        if(address(userLevels) != address(0)) {
          (_predictionPoints, isMultiplierApplied) = checkMultiplier(_user,  predictionPoints);
        }
        predictionPoints = uint64(_predictionPoints);
      }
    }

    /**
    * @dev Check if user gets any multiplier on his positions
    * @param _user User address
    * @param _predictionPoints The actual positions user got during prediction.
    * @return uint256 representing multiplied positions
    * @return bool returns true if multplier applied
    */
    function checkMultiplier(address _user, uint _predictionPoints) internal view returns(uint, bool) {
      bool _multiplierApplied;
      uint _muliplier = 100;
      (uint256 _userLevel, uint256 _levelMultiplier) = userLevels.getUserLevelAndMultiplier(_user);
      if(_userLevel > 0) {
        _muliplier = _muliplier + _levelMultiplier;
        _multiplierApplied = true;
      }
      return (_predictionPoints.mul(_muliplier).div(100), _multiplierApplied);
    }

    /**
    * @dev Claim fees earned by the relayer address
    */
    function claimRelayerRewards() external {
      uint _decimalMultiplier = 10**predictionDecimalMultiplier;
      address _relayer = msg.sender;
      uint256 _fee = (_decimalMultiplier).mul(relayerFeeEarned[_relayer]);
      delete relayerFeeEarned[_relayer];
      require(_fee > 0);
      _transferAsset(plotToken, _relayer, _fee);
    }

    /**
    * @dev Basic function to perform mathematical operation of (`_a` * `_b` / `_c`)
    * @param _a value of variable a
    * @param _b value of variable b
    * @param _c value of variable c
    */
    function _calculateAmulBdivC(uint64 _a, uint64 _b, uint64 _c) internal pure returns(uint64) {
      return _a.mul(_b).div(_c);
    }

    /**
    * @dev function to reward user for initiating market creation calls as per the new incetive calculations
    */
    function claimCreationReward() external {
      address payable _msgSenderAddress = _msgSender();
      uint256 rewardEarned = marketCreationReward[_msgSenderAddress];
      require(rewardEarned > 0, "No pending");
      _transferAsset(plotToken, _msgSenderAddress, rewardEarned);
      emit ClaimedMarketCreationReward(_msgSenderAddress, rewardEarned, plotToken);
    }

    /**
    * @dev Transfer the assets to specified address.
    * @param _asset The asset transfer to the specific address.
    * @param _recipient The address to transfer the asset of
    * @param _amount The amount which is transfer.
    */
    function _transferAsset(address _asset, address _recipient, uint256 _amount) internal {
      if(_amount > 0) { 
          require(IToken(_asset).transfer(_recipient, _amount));
      }
    }

    /**
    * @dev function to get pending reward of user for initiating market creation calls as per the new incetive calculations
    * @param _user Address of user for whom pending rewards to be checked
    * @return tokenIncentive Incentives given for creating market as per the gas consumed
    * @return pendingTokenReward prediction token Reward pool share of markets created by user
    */
    function getPendingMarketCreationRewards(address _user) external view returns(uint256 tokenIncentive){
      return marketCreationReward[_user];
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