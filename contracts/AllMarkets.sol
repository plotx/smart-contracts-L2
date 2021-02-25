/* Copyright (C) 2020 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IbLOTToken.sol";
import "./interfaces/IMarketCreationRewards.sol";
import "./IAuth.sol";
import "./IOracle.sol";

contract IMaster {
    function dAppToken() public view returns(address);
    function getLatestAddress(bytes2 _module) public view returns(address);
}


contract AllMarkets is IAuth, NativeMetaTransaction {
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

    event Deposited(address indexed user, uint256 amount, uint256 timeStamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timeStamp);
    event MarketTypes(uint256 indexed index, uint32 predictionTime, uint32 cooldownTime, uint32 optionRangePerc, bool status, uint32 minTimePassed);
    event MarketCurrencies(uint256 indexed index, address feedAddress, bytes32 currencyName, bool status);
    event MarketQuestion(uint256 indexed marketIndex, bytes32 currencyName, uint256 indexed predictionType, uint256 startTime, uint256 predictionTime, uint256 neutralMinValue, uint256 neutralMaxValue);
    event OptionPricingParams(uint256 indexed marketIndex, uint256 _stakingFactorMinStake,uint32 _stakingFactorWeightage,uint256 _currentPriceWeightage,uint32 _minTimePassed);
    event MarketResult(uint256 indexed marketIndex, uint256 totalReward, uint256 winningOption, uint256 closeValue, uint256 roundId, uint256 daoFee, uint256 marketCreatorFee);
    event ReturnClaimed(address indexed user, uint256 amount);
    event PlacePrediction(address indexed user,uint256 value, uint256 predictionPoints, address predictionAsset,uint256 prediction,uint256 indexed marketIndex);
    event ReferralLog(address indexed referrer, address indexed referee, uint256 referredOn);

    struct PredictionData {
      uint64 predictionPoints;
      uint64 amountStaked;
    }
    
    struct UserMarketData {
      bool predictedWithBlot;
      bool multiplierApplied;
      mapping(uint => PredictionData) predictionData;
    }

    struct UserData {
      uint128 totalStaked;
      uint128 lastClaimedIndex;
      uint[] marketsParticipated;
      uint unusedBalance;
      uint referrerFee;
      uint refereeFee;
      address referrer;
      mapping(uint => UserMarketData) userMarketData;
    }


    struct MarketBasicData {
      uint32 Mtype;
      uint32 currency;
      uint32 startTime;
      uint32 predictionTime;
      uint32 cooldownTime;
      uint64 neutralMinValue;
      uint64 neutralMaxValue;
      address feedAddress;
    }

    struct MarketDataExtended {
      uint32 WinningOption;
      uint32 settleTime;
      uint incentiveToDistribute;
      uint rewardToDistribute;
      uint totalStaked;
      PredictionStatus predictionStatus;
    }

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
    uint64 internal mcDefaultPredictionAmount;
    mapping (address => uint256) public relayerFeeEarned;
    mapping(uint256 => PricingData) internal marketPricingData;
    // mapping(address => uint256) public conversionRate;
    
    address internal masterAddress;
    address internal plotToken;
    address internal disputeResolution;

    address internal predictionToken;

    IbLOTToken internal bPLOTInstance;
    IMarketCreationRewards internal marketCreationRewards;

    address public authorizedMultiSig;
    uint internal totalOptions;
    uint internal predictionDecimalMultiplier;
    uint internal defaultMaxRecords;
    uint internal minPredictionAmount;
    uint internal maxPredictionAmount;
    uint internal stakingFactorMinStake;
    uint32 internal stakingFactorWeightage;
    uint32 internal currentPriceWeightage;


    bool public marketCreationPaused;
    MarketCurrency[] internal marketCurrencies;
    MarketTypeData[] internal marketTypeArray;
    mapping(bytes32 => uint) internal marketCurrency;

    mapping(uint64 => uint32) internal marketType;
    mapping(uint256 => mapping(uint256 => MarketCreationData)) internal marketCreationData;

    MarketBasicData[] internal marketBasicData;

    mapping(address => bool) public authorizedAddresses;
    mapping(uint256 => MarketDataExtended) internal marketDataExtended;
    mapping(address => UserData) internal userData;
    mapping(address => uint256) public userLevel;
    mapping(uint256 => uint256) public levelMultiplier;

    mapping(uint =>mapping(uint=>PredictionData)) internal marketOptionsAvailable;

    modifier onlyAuthorizedUsers() {
        require(authorizedAddresses[msg.sender]);
        _;
    }

    function setReferrer(address _referrer, address _referee) external onlyAuthorizedUsers {
      require(authorizedAddresses[msg.sender]);
      UserData storage _userData = userData[_referee];
      require(_userData.totalStaked == 0);
      require(_userData.referrer == address(0));
      _userData.referrer = _referrer;
      emit ReferralLog(_referrer, _referee, now);
    }

    /**
    * @dev Get fees earned by participating in the referral program
    * @param _user Address of the user
    * @return _referrerFee Fees earned by referring other users
    * @return _refereeFee Fees earned if referred by some one
    */
    function getReferralFees(address _user) external view returns(uint256 _referrerFee, uint256 _refereeFee) {
      UserData storage _userData = userData[_user];
      return (_userData.referrerFee, _userData.refereeFee);
    }

    function claimReferralFee(address _user) external {
      UserData storage _userData = userData[_user];
      uint256 _referrerFee = _userData.referrerFee;
      delete _userData.referrerFee;
      uint256 _refereeFee = _userData.refereeFee;
      delete _userData.refereeFee;
      _transferAsset(predictionToken, _user, (_refereeFee.add(_referrerFee)).mul(10**predictionDecimalMultiplier));
    }

    /**
    * @dev Function to set authorized address
    **/
    function addAuthorizedAddress(address _address) external onlyAuthorizedUsers {
        authorizedAddresses[_address] = true;
    }

    /**
    * @dev Function to set `_user` level for prediction points multiplier
    * @param _user User address
    * @param _level user level indicator
    */
    function setUserLevel(address _user, uint256 _level) public onlyAuthorizedUsers {
      userLevel[_user] = _level;
    }

    /**
    * @dev Function to set multiplier per level (With 2 decimals)
    * @param _userLevels Array of levels
    * @param _multipliers Array of corresponding multipliers
    */
    function setMultiplierLevels(uint256[] memory _userLevels, uint256[] memory _multipliers) public onlyAuthorized {
      require(_userLevels.length == _multipliers.length);
      for(uint256 i = 0; i < _userLevels.length; i++) {
        levelMultiplier[_userLevels[i]] = _multipliers[i];
      }
    }

    // /**
    // * @dev Function to set `_asset` to PLOT token value conversion rate
    // * @param _asset Token Address
    // * @param _rate `_asset` to PLOT conversion rate
    // */
    // function setAssetPlotConversionRate(address _asset, uint256 _rate) public onlyAuthorizedUsers {
    //   conversionRate[_asset] = _rate;
    // }

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
    * @dev Add new market type.
    * @param _predictionTime The time duration of market.
    * @param _optionRangePerc Option range percent of neutral min, max options (raised by 2 decimals)
    * @param _marketCooldownTime Cool down time of the market after market is settled
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

    function _addMarketType(uint32 _predictionTime, uint32 _optionRangePerc, uint32 _marketCooldownTime, uint32 _minTimePassed) internal returns(uint32) {
      uint32 index = uint32(marketTypeArray.length);
      marketType[_predictionTime] = index;
      marketTypeArray.push(MarketTypeData(_predictionTime, _optionRangePerc, _marketCooldownTime, _minTimePassed, false));
      emit MarketTypes(index, _predictionTime, _marketCooldownTime, _optionRangePerc, true, _minTimePassed);
      return index;
    }

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
    */
    function updateUintParameters(bytes8 code, uint256 value) external onlyAuthorized {
      MarketFeeParams storage _marketFeeParams = marketFeeParams;
      if(code == "MDPA") { // Market creators default prediction amount
        mcDefaultPredictionAmount = uint64(value);
      } else {
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
    * @dev Function to update address parameters
    */
    function updateAddressParameters(bytes8 code, address _address) external onlyAuthorized {
      if(code == "MULSIG") {
        authorizedMultiSig = _address;
      } else {
        revert("Invalid code");
      }
    }

    /**
    * @dev function to get integer parameters
    */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value) {
      codeVal = code;
      if(code == "CMFP") { // Cummulative fee percent
        value = marketFeeParams.cummulativeFeePercent;
      } else if(code == "DAOF") { // DAO Fee percent in Cummulative fee
        value = marketFeeParams.daoCommissionPercent;
      } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
        value = marketFeeParams.referrerFeePercent;
      } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
        value = marketFeeParams.refereeFeePercent;
      } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
        value = marketFeeParams.marketCreatorFeePercent;
      } else if(code == "MDPA") { // Market creators default prediction amount
        value = mcDefaultPredictionAmount;
      }
    }

    /**
     * @dev Changes the master address and update it's instance
     */
    function setMasterAddress(address _defaultAuthorizedAddress) public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner());
      IMaster ms = IMaster(msg.sender);
      masterAddress = msg.sender;
      address _plotToken = ms.dAppToken();
      plotToken = _plotToken;
      predictionToken = _plotToken;
      bPLOTInstance = IbLOTToken(ms.getLatestAddress("BL"));
      authorizedAddresses[_defaultAuthorizedAddress] = true;
    }

    /**
    * @dev Start the initial market and set initial variables.
    */
    function addInitialMarketTypesAndStart(uint32 _marketStartTime, address _ethFeed, address _btcFeed, address _multiSig) external onlyAuthorizedUsers {
      require(marketTypeArray.length == 0);
      require(_ethFeed != address(0));
      require(_btcFeed != address(0));
      require(_multiSig != address(0));
      
      IMaster ms = IMaster(masterAddress);
      marketCreationRewards = IMarketCreationRewards(ms.getLatestAddress("MC"));
      disputeResolution = ms.getLatestAddress("DR");
      
      authorizedMultiSig = _multiSig;
      totalOptions = 3;
      predictionDecimalMultiplier = 10;
      defaultMaxRecords = 20;
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
      mcDefaultPredictionAmount = 100 * 10**8;
      
      _addMarketType(4 hours, 100, 1 hours, 40 minutes);
      _addMarketType(24 hours, 200, 6 hours, 4 hours);
      _addMarketType(168 hours, 500, 8 hours, 28 hours);

      _addMarketCurrency("ETH/USD", _ethFeed, 8, 1, _marketStartTime);
      _addMarketCurrency("BTC/USD", _btcFeed, 8, 25, _marketStartTime);

      marketBasicData.push(MarketBasicData(0,0,0, 0,0,0,0, address(0)));
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
      require(!marketCreationPaused && !_marketType.paused);
      _closePreviousMarketWithRoundId( _marketTypeIndex, _marketCurrencyIndex, _roundId);
      uint32 _startTime = calculateStartTimeForMarket(_marketCurrencyIndex, _marketTypeIndex);
      (uint64 _minValue, uint64 _maxValue) = _calculateOptionRange(_marketType.optionRangePerc, _marketCurrency.decimals, _marketCurrency.roundOfToNearest, _marketCurrency.marketFeed);
      uint64 _marketIndex = uint64(marketBasicData.length);
      marketBasicData.push(MarketBasicData(_marketTypeIndex,_marketCurrencyIndex,_startTime, _marketType.predictionTime, _marketType.cooldownTime, _minValue, _maxValue, _marketCurrency.marketFeed));
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      (_marketCreationData.penultimateMarket, _marketCreationData.latestMarket) =
       (_marketCreationData.latestMarket, _marketIndex);
      marketPricingData[_marketIndex] = PricingData(stakingFactorMinStake, stakingFactorWeightage, currentPriceWeightage, _marketType.minTimePassed);
      emit MarketQuestion(_marketIndex, _marketCurrency.currencyName, _marketTypeIndex, _startTime, _marketType.predictionTime, _minValue, _maxValue);
      emit OptionPricingParams(_marketIndex, stakingFactorMinStake,stakingFactorWeightage,currentPriceWeightage,_marketType.minTimePassed);
      address _msgSenderAddress = _msgSender();
      marketCreationRewards.updateMarketCreationData(_msgSenderAddress, _marketIndex);
      _placeInitialPrediction(_marketIndex, _msgSenderAddress);
    }

    function _calculateOptionRange(uint _optionRangePerc, uint64 _decimals, uint8 _roundOfToNearest, address _marketFeed) internal view returns(uint64 _minValue, uint64 _maxValue) {
      uint currentPrice = IOracle(_marketFeed).getLatestPrice();
      uint optionRangePerc = currentPrice.mul(_optionRangePerc.div(2)).div(10000);
      _minValue = uint64((ceil(currentPrice.sub(optionRangePerc).div(_roundOfToNearest), 10**_decimals)).mul(_roundOfToNearest));
      _maxValue = uint64((ceil(currentPrice.add(optionRangePerc).div(_roundOfToNearest), 10**_decimals)).mul(_roundOfToNearest));
    }

    function _placeInitialPrediction(uint64 _marketId, address _msgSenderAddress) internal {
      uint64 _mcDefaultPredictionAmount = mcDefaultPredictionAmount;
      uint256 _defaultAmount = (10**predictionDecimalMultiplier).mul(_mcDefaultPredictionAmount);
      (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress);
      if(_tokenLeft.add(_tokenReward) < _defaultAmount) {
        _deposit(_defaultAmount);
      }
      address _predictionToken = predictionToken;
      _placePrediction(_marketId, _predictionToken, _mcDefaultPredictionAmount/3, 1);
      _placePrediction(_marketId, _predictionToken, _mcDefaultPredictionAmount/3, 2);
      _placePrediction(_marketId, _predictionToken, _mcDefaultPredictionAmount - 2*(_mcDefaultPredictionAmount/3), 3);
    }

    /**
    * @dev Calculate start time for next market of provided currency and market type indexes
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
    * @dev Transfer the _asset to specified address.
    * @param _recipient The address to transfer the asset of
    * @param _amount The amount which is transfer.
    */
    function _transferAsset(address _asset, address _recipient, uint256 _amount) internal {
      if(_amount > 0) { 
          require(IToken(_asset).transfer(_recipient, _amount));
      }
    }

    /**
    * @dev Internal function to settle the previous market 
    */
    function _closePreviousMarketWithRoundId(uint64 _marketTypeIndex, uint64 _marketCurrencyIndex, uint80 _roundId) internal {
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      uint64 currentMarket = _marketCreationData.latestMarket;
      if(currentMarket != 0) {
        require(marketStatus(currentMarket) >= PredictionStatus.InSettlement);
        uint64 penultimateMarket = _marketCreationData.penultimateMarket;
        if(penultimateMarket > 0 && now >= marketSettleTime(penultimateMarket)) {
          _settleMarket(penultimateMarket, _roundId);
        }
      }
    }

    /**
    * @dev Get market settle time
    * @return the time at which the market result will be declared
    */
    function marketSettleTime(uint256 _marketId) public view returns(uint32) {
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      if(_marketDataExtended.settleTime > 0) {
        return _marketDataExtended.settleTime;
      }
      return _marketBasicData.startTime + (_marketBasicData.predictionTime * 2);
    }

    /**
    * @dev Gets the status of market.
    * @return PredictionStatus representing the status of market.
    */
    function marketStatus(uint256 _marketId) public view returns(PredictionStatus){
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      if(_marketDataExtended.predictionStatus == PredictionStatus.Live && now >= marketExpireTime(_marketId)) {
        return PredictionStatus.InSettlement;
      } else if(_marketDataExtended.predictionStatus == PredictionStatus.Settled && now <= marketCoolDownTime(_marketId)) {
        return PredictionStatus.Cooling;
      }
      return _marketDataExtended.predictionStatus;
    }

    /**
    * @dev Get market cooldown time
    * @return the time upto which user can raise the dispute after the market is settled
    */
    function marketCoolDownTime(uint256 _marketId) public view returns(uint256) {
      return (marketSettleTime(_marketId) + marketBasicData[_marketId].cooldownTime);
    }

    /**
    * @dev Updates Flag to pause creation of market.
    */
    function pauseMarketCreation() external onlyAuthorized {
      require(!marketCreationPaused);
      marketCreationPaused = true;
    }

    /**
    * @dev Updates Flag to resume creation of market.
    */
    function resumeMarketCreation() external onlyAuthorized {
      require(marketCreationPaused);
      marketCreationPaused = false;
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
    * @dev Function to deposit prediction token for participation in markets
    * @param _amount Amount of prediction token to deposit
    */
    function _deposit(uint _amount) internal {
      address payable _msgSenderAddress = _msgSender();
      _transferTokenFrom(predictionToken, _msgSenderAddress, address(this), _amount);
      UserData storage _userData = userData[_msgSenderAddress];
      _userData.unusedBalance = _userData.unusedBalance.add(_amount);
      emit Deposited(_msgSenderAddress, _amount, now);
    }

    /**
    * @dev Withdraw provided amount of deposited and available prediction token
    * @param _token Amount of prediction token to withdraw
    * @param _maxRecords Maximum number of records to check
    */
    function withdraw(uint _token, uint _maxRecords) public {
      (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSender());
      _tokenLeft = _tokenLeft.add(_tokenReward);
      _withdraw(_token, _maxRecords, _tokenLeft);
    }

    /**
    * @dev Internal function to withdraw deposited and available assets
    * @param _token Amount of prediction token to withdraw
    * @param _maxRecords Maximum number of records to check
    * @param _tokenLeft Amount of prediction token left unused for user
    */
    function _withdraw(uint _token, uint _maxRecords, uint _tokenLeft) internal {
      address payable _msgSenderAddress = _msgSender();
      _withdrawReward(_maxRecords);
      userData[_msgSenderAddress].unusedBalance = _tokenLeft.sub(_token);
      require(_token > 0);
      _transferAsset(predictionToken, _msgSenderAddress, _token);
      emit Withdrawn(_msgSenderAddress, _token, now);
    }

    /**
    * @dev Get market expire time
    * @return the time upto which user can place predictions in market
    */
    function marketExpireTime(uint _marketId) internal view returns(uint256) {
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      return _marketBasicData.startTime + (_marketBasicData.predictionTime);
    }

    /**
    * @dev Deposit and Place prediction on the available options of the market.
    * @param _marketId Index of the market
    * @param _tokenDeposit prediction token amount to deposit
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param _prediction The option on which user placed prediction.
    * _tokenDeposit should be passed with 18 decimals
    * _predictioStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function depositAndPlacePrediction(uint _tokenDeposit, uint _marketId, address _asset, uint64 _predictionStake, uint256 _prediction) external {
      if(_tokenDeposit > 0) {
        _deposit(_tokenDeposit);
      }
      _placePrediction(_marketId, _asset, _predictionStake, _prediction);
    }

    /**
    * @dev Place prediction on the available options of the market.
    * @param _marketId Index of the market
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param _prediction The option on which user placed prediction.
    * _predictioStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function _placePrediction(uint _marketId, address _asset, uint64 _predictionStake, uint256 _prediction) internal {
      address payable _msgSenderAddress = _msgSender();
      require(!marketCreationPaused && _prediction <= totalOptions && _prediction >0);
      require(now >= marketBasicData[_marketId].startTime && now <= marketExpireTime(_marketId));
      uint64 _predictionStakePostDeduction = _predictionStake;
      uint decimalMultiplier = 10**predictionDecimalMultiplier;
      UserData storage _userData = userData[_msgSenderAddress];
      if(_asset == predictionToken) {
        uint256 unusedBalance = _userData.unusedBalance;
        unusedBalance = unusedBalance.div(decimalMultiplier);
        if(_predictionStake > unusedBalance)
        {
          _withdrawReward(defaultMaxRecords);
          unusedBalance = _userData.unusedBalance;
          unusedBalance = unusedBalance.div(decimalMultiplier);
        }
        require(_predictionStake <= unusedBalance);
        _userData.unusedBalance = (unusedBalance.sub(_predictionStake)).mul(decimalMultiplier);
      } else {
        require(_asset == address(bPLOTInstance));
        require(!_userData.userMarketData[_marketId].predictedWithBlot);
        _userData.userMarketData[_marketId].predictedWithBlot = true;
        bPLOTInstance.convertToPLOT(_msgSenderAddress, address(this), (decimalMultiplier).mul(_predictionStake));
        _asset = plotToken;
      }
      _predictionStakePostDeduction = _deductFee(_marketId, _predictionStake, _msgSenderAddress);
      
      uint64 predictionPoints = _calculatePredictionPointsAndMultiplier(_msgSenderAddress, _marketId, _prediction, _predictionStakePostDeduction);
      require(predictionPoints > 0);

      _storePredictionData(_marketId, _prediction, _predictionStakePostDeduction, predictionPoints);
      emit PlacePrediction(_msgSenderAddress, _predictionStake, predictionPoints, _asset, _prediction, _marketId);
    }

    function _deductFee(uint _marketId, uint64 _amount, address _msgSenderAddress) internal returns(uint64 _amountPostFee){
      uint64 _fee;
      address _relayer;
      if(_msgSenderAddress != tx.origin) {
        _relayer = tx.origin;
      } else {
        _relayer = _msgSenderAddress;
      }
      MarketFeeParams storage _marketFeeParams = marketFeeParams;
      _fee = _calculateAmulBdivC(_marketFeeParams.cummulativeFeePercent, _amount, 10000);
      _amountPostFee = _amount.sub(_fee);
      (uint64 _referrerFee, uint64 _refereeFee) = _calculateReferalFee(_msgSenderAddress, _fee, _marketFeeParams.refereeFeePercent, _marketFeeParams.referrerFeePercent);
      uint64 _daoFee = _calculateAmulBdivC(_marketFeeParams.daoCommissionPercent, _fee, 10000);
      uint64 _marketCreatorFee = _calculateAmulBdivC(_marketFeeParams.marketCreatorFeePercent, _fee, 10000);
      _marketFeeParams.daoFee[_marketId] = _marketFeeParams.daoFee[_marketId].add(_daoFee);
      _marketFeeParams.marketCreatorFee[_marketId] = _marketFeeParams.marketCreatorFee[_marketId].add(_marketCreatorFee);
      _fee = _fee.sub(_daoFee).sub(_referrerFee).sub(_refereeFee).sub(_marketCreatorFee);
      relayerFeeEarned[_relayer] = relayerFeeEarned[_relayer].add(_fee);
      // _transferAsset(predictionToken, address(marketCreationRewards), (10**predictionDecimalMultiplier).mul(_daoFee));
    }

    function _calculateReferalFee(address _msgSenderAddress, uint64 _cummulativeFee, uint32 _refereeFeePerc, uint32 _referrerFeePerc) internal returns(uint64 _referrerFee, uint64 _refereeFee) {
      UserData storage _userData = userData[_msgSenderAddress];
      address _referrer = _userData.referrer;
      if(_referrer != address(0)) {
        //Commission for referee
        _refereeFee = _calculateAmulBdivC(_refereeFeePerc, _cummulativeFee, 10000);
        _userData.refereeFee = _userData.refereeFee.add(_refereeFee);
        //Commission for referrer
        _referrerFee = _calculateAmulBdivC(_referrerFeePerc, _cummulativeFee, 10000);
        userData[_referrer].referrerFee = userData[_referrer].referrerFee.add(_referrerFee);
      }
    }

    /**
    * @dev Internal function to calculate prediction points  and multiplier
    */
    function _calculatePredictionPointsAndMultiplier(address _user, uint256 _marketId, uint256 _prediction, uint64 _stake) internal returns(uint64 predictionPoints){
      bool isMultiplierApplied;
      UserData storage _userData = userData[_user];
      (predictionPoints, isMultiplierApplied) = calculatePredictionPoints(_marketId, _prediction, _user, _userData.userMarketData[_marketId].multiplierApplied, _stake);
      if(isMultiplierApplied) {
        _userData.userMarketData[_marketId].multiplierApplied = true; 
      }
    }

    function calculatePredictionPoints(uint _marketId, uint256 _prediction, address _user, bool multiplierApplied, uint _predictionStake) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
      uint _stakeValue = _predictionStake.mul(1e10);
      if(_stakeValue < minPredictionAmount || _stakeValue > maxPredictionAmount) {
        return (0, isMultiplierApplied);
      }
      uint64 _optionPrice = getOptionPrice(_marketId, _prediction);
      predictionPoints = uint64(_predictionStake).div(_optionPrice);
      if(!multiplierApplied) {
        uint256 _predictionPoints;
        (_predictionPoints, isMultiplierApplied) = checkMultiplier(_user,  predictionPoints);
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
      bool multiplierApplied;
      uint _muliplier = 100;
      uint256 _userLevel = userLevel[_user];
      if(_userLevel > 0) {
        _muliplier = _muliplier + levelMultiplier[_userLevel];
        multiplierApplied = true;
      }
      return (_predictionPoints.mul(_muliplier).div(100),multiplierApplied);
    }

    /**
     * @dev Gets price for given market and option
     * @param _marketId  Market ID
     * @param _prediction  prediction option
     * @return  option price
     **/
    function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64) {
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      PricingData storage _marketPricingData = marketPricingData[_marketId];
      uint stakingFactorConst;
      uint optionPrice; 
      uint256 totalStaked = marketDataExtended[_marketId].totalStaked;
      // Checking if current stake in market reached minimum stake required for considering staking factor.
      if(totalStaked > _marketPricingData.stakingFactorMinStake)
      {
        // 10000 / staking weightage
        stakingFactorConst = uint(10000).div(_marketPricingData.stakingFactorWeightage); 
        // (stakingFactorConst x Amount staked in option x 10^18) / Total staked in market --- (1)
        optionPrice = (stakingFactorConst.mul(marketOptionsAvailable[_marketId][_prediction].amountStaked).mul(10**18).div(totalStaked)); 
      }
      uint timeElapsed = uint(now).sub(_marketBasicData.startTime);
      // max(timeElapsed, minTimePassed)
      if(timeElapsed < _marketPricingData.minTimePassed) {
        timeElapsed = _marketPricingData.minTimePassed;
      }
      uint[] memory _distanceData = getOptionDistanceData(_marketId,_prediction);

      // (Time Elapsed x 10000) / ((Max Distance + 1) x currentPriceWeightage)
      uint timeFactor = timeElapsed.mul(10000).div((_distanceData[0].add(1)).mul(_marketPricingData.currentPriceWeightage));

      uint totalTime = _marketBasicData.predictionTime;

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
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      // [0]--> Max Distance between current option and any option, (For 3 options, if current option is 2 it will be `1`. else, it will be `2`) 
      // [1]--> Predicting option distance from Max distance, (MaxDistance - | currentOption - predicting option |)
      // [2]--> sum of all possible option distances,  
      uint[] memory _distanceData = new uint256[](3); 

      // Fetching current price
      uint currentPrice = IOracle(_marketBasicData.feedAddress).getLatestPrice();
      _distanceData[0] = 2;
      // current option based on current price
      uint currentOption;
      _distanceData[2] = 3;
      if(currentPrice < _marketBasicData.neutralMinValue)
      {
        currentOption = 1;
      } else if(currentPrice > _marketBasicData.neutralMaxValue) {
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

    /**
    * @dev Settle the market, setting the winning option
    */
    function settleMarket(uint256 _marketId, uint80 _roundId) external {
      _settleMarket(_marketId, _roundId);
    }

    /**
    * @dev Settle the market explicitly by manually passing the price of market currency
    * @param _marketId Index of market
    * @param _marketSettleValue The current price of market currency.
    */
    function postMarketResult(uint256 _marketId, uint256 _marketSettleValue) external {
      PredictionStatus _status = marketStatus(_marketId);
      if(msg.sender == authorizedMultiSig) {
        require(marketBasicData[_marketId].feedAddress == address(0));
        require(_status == PredictionStatus.InSettlement);
      } else {
        require(msg.sender == disputeResolution);
        require(_status == PredictionStatus.InDispute);
      }
      _postResult(_marketSettleValue, 0, _marketId);
    }

    /**
    * @dev Settle the market, setting the winning option
    */
    function _settleMarket(uint256 _marketId, uint80 _roundId) internal {
      address _feedAdd = marketBasicData[_marketId].feedAddress;
      if(marketStatus(_marketId) == PredictionStatus.InSettlement && _feedAdd != address(0)) {
        (uint256 _value, uint256 _roundIdUsed) = IOracle(_feedAdd).getSettlementPrice(marketSettleTime(_marketId), _roundId);
        _postResult(_value, _roundIdUsed, _marketId);
      }
    }

    /**
    * @dev Calculate the result of market.
    * @param _value The current price of market currency.
    * @param _roundId Chainlink round Id
    * @param _marketId Index of market
    */
    function _postResult(uint256 _value, uint256 _roundId, uint256 _marketId) internal {
      require(now >= marketSettleTime(_marketId));
      require(_value > 0);
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      if(_marketDataExtended.predictionStatus != PredictionStatus.InDispute) {
        _marketDataExtended.settleTime = uint32(now);
        uint64 amountToTransfer;
        MarketFeeParams storage _marketFeeParams = marketFeeParams;
        amountToTransfer = (_marketFeeParams.daoFee[_marketId]).add(_marketFeeParams.marketCreatorFee[_marketId]);
        uint _decimalMultiplier = 10**predictionDecimalMultiplier;
        _transferAsset(predictionToken, address(marketCreationRewards), _decimalMultiplier.mul(amountToTransfer));
        marketCreationRewards.depositMarketCreationReward(_marketId, _decimalMultiplier.mul(_marketFeeParams.marketCreatorFee[_marketId]));
      } else {
        delete _marketDataExtended.settleTime;
      }
      marketDataExtended[_marketId].predictionStatus = PredictionStatus.Settled;
      uint32 _winningOption; 
      if(_value < _marketBasicData.neutralMinValue) {
        _winningOption = 1;
      } else if(_value > _marketBasicData.neutralMaxValue) {
        _winningOption = 3;
      } else {
        _winningOption = 2;
      }
      _marketDataExtended.WinningOption = _winningOption;
      uint64 totalReward = _calculateRewardTally(_marketId, _winningOption);
      _marketDataExtended.rewardToDistribute = totalReward;
      emit MarketResult(_marketId, _marketDataExtended.rewardToDistribute, _winningOption, _value, _roundId, marketFeeParams.daoFee[_marketId], marketFeeParams.marketCreatorFee[_marketId]);
    }

    /**
    * @dev Internal function to calculate the reward.
    * @param _marketId Index of market
    * @param _winningOption WinningOption of market
    */
    function _calculateRewardTally(uint256 _marketId, uint256 _winningOption) internal view returns(uint64 totalReward){
      for(uint i=1;i <= totalOptions;i++){
        uint64 _tokenStakedOnOption = marketOptionsAvailable[_marketId][i].amountStaked;
        if(i != _winningOption) {
          totalReward = totalReward.add(_tokenStakedOnOption);
        }
      }
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
      _transferAsset(predictionToken, _relayer, _fee);
    }

    /**
    * @dev Claim the pending return of the market.
    * @param maxRecords Maximum number of records to claim reward for
    */
    function _withdrawReward(uint256 maxRecords) internal {
      address payable _msgSenderAddress = _msgSender();
      uint256 i;
      UserData storage _userData = userData[_msgSenderAddress];
      uint len = _userData.marketsParticipated.length;
      uint lastClaimed = len;
      uint count;
      uint tokenReward =0 ;
      require(!marketCreationPaused);
      for(i = _userData.lastClaimedIndex; i < len && count < maxRecords; i++) {
        (uint claimed, uint tempTokenReward) = claimReturn(_msgSenderAddress, _userData.marketsParticipated[i]);
        if(claimed > 0) {
          delete _userData.marketsParticipated[i];
          tokenReward = tokenReward.add(tempTokenReward);
          count++;
        } else {
          if(lastClaimed == len) {
            lastClaimed = i;
          }
        }
      }
      if(lastClaimed == len) {
        lastClaimed = i;
      }
      emit ReturnClaimed(_msgSenderAddress, tokenReward);
      _userData.unusedBalance = _userData.unusedBalance.add(tokenReward.mul(10**predictionDecimalMultiplier));
      _userData.lastClaimedIndex = uint128(lastClaimed);
    }

    /**
    * @dev FUnction to return users unused deposited balance including the return earned in markets
    * @param _user Address of user
    * return prediction token Unused in deposit
    * return prediction token Return from market
    */
    function getUserUnusedBalance(address _user) public view returns(uint256, uint256){
      uint tokenReward;
      uint decimalMultiplier = 10**predictionDecimalMultiplier;
      UserData storage _userData = userData[_user];
      uint len = _userData.marketsParticipated.length;
      for(uint i = _userData.lastClaimedIndex; i < len; i++) {
        tokenReward = tokenReward.add(getReturn(_user, _userData.marketsParticipated[i]));
      }
      return (_userData.unusedBalance, tokenReward.mul(decimalMultiplier));
    }

    /**
    * @dev Gets number of positions user got in prediction
    * @param _user Address of user
    * @param _marketId Index of market
    * @param _option Option Id
    * return Number of positions user got in prediction
    */
    function getUserPredictionPoints(address _user, uint256 _marketId, uint256 _option) external view returns(uint64) {
      return userData[_user].userMarketData[_marketId].predictionData[_option].predictionPoints;
    }

    /**
    * @dev Gets the market data.
    * @return _marketCurrency returns the currency name of the market.
    * @return neutralMinValue Neutral min value deciding the option ranges of market
    * @return neutralMaxValue Neutral max value deciding the option ranges of market
    * @return _optionPrice uint[] memory representing the option price of each option ranges of the market.
    * @return _tokenStaked uint[] memory representing the prediction token staked on each option ranges of the market.
    * @return _predictionTime uint representing the type of market.
    * @return _expireTime uint representing the time at which market closes for prediction
    * @return _predictionStatus uint representing the status of the market.
    */
    function getMarketData(uint256 _marketId) external view returns
       (bytes32 _marketCurrency,uint neutralMinValue,uint neutralMaxValue, uint[] memory _tokenStaked,uint _predictionTime,uint _expireTime, PredictionStatus _predictionStatus){
        MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
        _marketCurrency = marketCurrencies[_marketBasicData.currency].currencyName;
        _predictionTime = _marketBasicData.predictionTime;
        
        _expireTime = marketExpireTime(_marketId);
        _predictionStatus = marketStatus(_marketId);
        neutralMinValue = _marketBasicData.neutralMinValue;
        neutralMaxValue = _marketBasicData.neutralMaxValue;
        
        _tokenStaked = new uint[](totalOptions);
        for (uint i = 0; i < totalOptions; i++) {
          _tokenStaked[i] = marketOptionsAvailable[_marketId][i+1].amountStaked;
       }
    }

    /**
    * @dev Claim the return amount of the specified address.
    * @param _user User address
    * @param _marketId Index of market
    * @return Flag, if 0:cannot claim, 1: Already Claimed, 2: Claimed; Return in prediction token
    */
    function claimReturn(address payable _user, uint _marketId) internal returns(uint256, uint256) {

      if(marketStatus(_marketId) != PredictionStatus.Settled) {
        return (0, 0);
      }
      return (2, getReturn(_user, _marketId));
    }

    /** 
    * @dev Gets the return amount of the specified address.
    * @param _user The address to specify the return of
    * @param _marketId Index of market
    * @return returnAmount uint[] memory representing the return amount.
    * @return incentive uint[] memory representing the amount incentive.
    * @return _incentiveTokens address[] memory representing the incentive tokens.
    */
    function getReturn(address _user, uint _marketId) public view returns (uint returnAmount){
      if(marketStatus(_marketId) != PredictionStatus.Settled || getTotalPredictionPoints(_marketId) == 0) {
       return (returnAmount);
      }
      uint256 _winningOption = marketDataExtended[_marketId].WinningOption;
      UserData storage _userData = userData[_user];
      returnAmount = _userData.userMarketData[_marketId].predictionData[_winningOption].amountStaked;
      uint256 userPredictionPointsOnWinngOption = _userData.userMarketData[_marketId].predictionData[_winningOption].predictionPoints;
      if(userPredictionPointsOnWinngOption > 0) {
        returnAmount = _addUserReward(_marketId, returnAmount, _winningOption, userPredictionPointsOnWinngOption);
      }
      return returnAmount;
    }

    /**
    * @dev Adds the reward in the total return of the specified address.
    * @param returnAmount The return amount.
    * @return uint[] memory representing the return amount after adding reward.
    */
    function _addUserReward(uint256 _marketId, uint returnAmount, uint256 _winningOption, uint256 _userPredictionPointsOnWinngOption) internal view returns(uint){
        return returnAmount.add(
            _userPredictionPointsOnWinngOption.mul(marketDataExtended[_marketId].rewardToDistribute).div(marketOptionsAvailable[_marketId][_winningOption].predictionPoints)
          );
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
    * @dev Returns total assets staked in market in PLOT value
    * @param _marketId Index of market
    * @return tokenStaked Total prediction token staked on market value in PLOT
    */
    function getTotalStakedWorthInPLOT(uint256 _marketId) public view returns(uint256 _tokenStakedWorth) {
      return (marketDataExtended[_marketId].totalStaked).mul(10**predictionDecimalMultiplier);
      // return (marketDataExtended[_marketId].totalStaked).mul(conversionRate[plotToken]).mul(10**predictionDecimalMultiplier);
    }

    /**
    * @dev Returns total prediction points allocated to users
    * @param _marketId Index of market
    * @return predictionPoints total prediction points allocated to users
    */
    function getTotalPredictionPoints(uint _marketId) public view returns(uint64 predictionPoints) {
      for(uint256 i = 1; i<= totalOptions;i++) {
        predictionPoints = predictionPoints.add(marketOptionsAvailable[_marketId][i].predictionPoints);
      }
    }

    /**
    * @dev Stores the prediction data.
    * @param _prediction The option on which user place prediction.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param predictionPoints The positions user got during prediction.
    */
    function _storePredictionData(uint _marketId, uint _prediction, uint64 _predictionStake, uint64 predictionPoints) internal {
      address payable _msgSenderAddress = _msgSender();
      UserData storage _userData = userData[_msgSenderAddress];
      PredictionData storage _predictionData = marketOptionsAvailable[_marketId][_prediction];
      if(!_hasUserParticipated(_marketId, _msgSenderAddress)) {
        _userData.marketsParticipated.push(_marketId);
      }
      _userData.userMarketData[_marketId].predictionData[_prediction].predictionPoints = _userData.userMarketData[_marketId].predictionData[_prediction].predictionPoints.add(predictionPoints);
      _predictionData.predictionPoints = _predictionData.predictionPoints.add(predictionPoints);
      
      _userData.userMarketData[_marketId].predictionData[_prediction].amountStaked = _userData.userMarketData[_marketId].predictionData[_prediction].amountStaked.add(_predictionStake);
      _predictionData.amountStaked = _predictionData.amountStaked.add(_predictionStake);
      _userData.totalStaked = _userData.totalStaked.add(_predictionStake);
      marketDataExtended[_marketId].totalStaked = marketDataExtended[_marketId].totalStaked.add(_predictionStake);
      
    }

    /**
    * @dev Function to check if user had participated in given market
    * @param _marketId Index of market
    * @param _user Address of user
    */
    function _hasUserParticipated(uint256 _marketId, address _user) internal view returns(bool _hasParticipated) {
      for(uint i = 1;i <= totalOptions; i++) {
        if(userData[_user].userMarketData[_marketId].predictionData[i].predictionPoints > 0) {
          _hasParticipated = true;
          break;
        }
      }
    }

    function _transferTokenFrom(address _token, address _from, address _to, uint256 _amount) internal {
      IToken(_token).transferFrom(_from, _to, _amount);
    }

    /**
    * @dev Get flags set for user
    * @param _marketId Index of market.
    * @param _user User address
    * @return Flag defining if user had predicted with bPLOT
    * @return Flag defining if user had availed multiplier
    */
    function getUserFlags(uint256 _marketId, address _user) external view returns(bool, bool) {
      return (
              userData[_user].userMarketData[_marketId].predictedWithBlot,
              userData[_user].userMarketData[_marketId].multiplierApplied
      );
    }

    /**
    * @dev Gets the result of the market.
    * @param _marketId Index of market.
    * @return uint256 representing the winning option of the market.
    * @return uint256 Value of market currently at the time closing market.
    * @return uint256 representing the positions of the winning option.
    * @return uint[] memory representing the reward to be distributed.
    * @return uint256 representing the prediction token staked on winning option.
    */
    function getMarketResults(uint256 _marketId) external view returns(uint256 _winningOption, uint256, uint256, uint256) {
      _winningOption = marketDataExtended[_marketId].WinningOption;
      return (_winningOption, marketOptionsAvailable[_marketId][_winningOption].predictionPoints, marketDataExtended[_marketId].rewardToDistribute, marketOptionsAvailable[_marketId][_winningOption].amountStaked);
    }

    /**
    * @dev Internal function set market status
    * @param _marketId Index of market
    * @param _status Status of market to set
    */    
    function setMarketStatus(uint256 _marketId, PredictionStatus _status) public {
      require(msg.sender == disputeResolution);
      require(marketStatus(_marketId) == PredictionStatus.InDispute);
      marketDataExtended[_marketId].predictionStatus = _status;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }

}
