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
import "./interfaces/IMarketUtility.sol";   
import "./interfaces/IToken.sol";
import "./interfaces/IbLOTToken.sol";
import "./interfaces/IMarketCreationRewards.sol";
import "./IAuth.sol";

contract IMaster {
    mapping(address => bool) public whitelistedSponsor;
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
    event DisputeRaised(uint256 indexed marketIndex, address raisedBy, uint256 proposalId, uint256 proposedValue);
    event DisputeResolved(uint256 indexed marketIndex, bool status);
    event ReferralLog(address indexed referrer, address indexed referee, uint256 referredOn);

    struct PredictionData {
      uint64 predictionPoints;
      uint64 amountStaked;
    }
    
    struct UserMarketData {
      bool claimedReward;
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
      address disputeRaisedBy;
      uint64 disputeStakeAmount;
      uint incentiveToDistribute;
      uint rewardToDistribute;
      uint totalStaked;
      PredictionStatus predictionStatus;
    }

    struct MarketTypeData {
      uint32 predictionTime;
      uint32 optionRangePerc;
      uint32 cooldownTime;
      bool paused;
      uint32 minTimePassed;
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
    
    address internal masterAddress;
    address internal plotToken;

    address internal predictionToken;

    IbLOTToken internal bPLOTInstance;
    IMarketUtility internal marketUtility;
    IMarketCreationRewards internal marketCreationRewards;

    address public authorizedMultiSig;
    uint internal totalOptions;
    uint internal predictionDecimalMultiplier;
    uint internal defaultMaxRecords;

    bool public marketCreationPaused;
    MarketCurrency[] internal marketCurrencies;
    MarketTypeData[] internal marketTypeArray;
    mapping(bytes32 => uint) internal marketCurrency;

    mapping(uint64 => uint32) internal marketType;
    mapping(uint256 => mapping(uint256 => MarketCreationData)) internal marketCreationData;

    MarketBasicData[] internal marketBasicData;

    mapping(uint256 => MarketDataExtended) internal marketDataExtended;
    mapping(address => UserData) internal userData;

    mapping(uint =>mapping(uint=>PredictionData)) internal marketOptionsAvailable;
    mapping(uint256 => uint256) internal disputeProposalId;

    function setReferrer(address _referrer, address _referee) external {
      require(marketUtility.isAuthorizedUser(msg.sender));
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
      marketTypeArray.push(MarketTypeData(_predictionTime, _optionRangePerc, _marketCooldownTime, false, _minTimePassed));
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
      if(code == "MDPA") { // Market creators default prediction amount
        mcDefaultPredictionAmount = uint64(value);
      } else {
        require(value < 10000);
        if(code == "CMFP") { // Cummulative fee percent
          marketFeeParams.cummulativeFeePercent = uint32(value);
        } else {
          if(code == "DAOF") { // DAO Fee percent in Cummulative fee
            marketFeeParams.daoCommissionPercent = uint32(value);
          } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
            marketFeeParams.referrerFeePercent = uint32(value);
          } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
            marketFeeParams.refereeFeePercent = uint32(value);
          } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
            marketFeeParams.marketCreatorFeePercent = uint32(value);
          } else {
            revert("Invalid code");
          } 
          require(
            marketFeeParams.daoCommissionPercent + 
            marketFeeParams.referrerFeePercent + 
            marketFeeParams.refereeFeePercent + 
            marketFeeParams.marketCreatorFeePercent
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
    function setMasterAddress() public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner());
      IMaster ms = IMaster(msg.sender);
      masterAddress = msg.sender;
      address _plotToken = ms.dAppToken();
      plotToken = _plotToken;
      predictionToken = _plotToken;
      bPLOTInstance = IbLOTToken(ms.getLatestAddress("BL"));
    }

    /**
    * @dev Start the initial market and set initial variables.
    */
    function addInitialMarketTypesAndStart(uint32 _marketStartTime, address _ethFeed, address _btcFeed, address _multiSig) external {
      require(marketTypeArray.length == 0);
      require(_ethFeed != address(0));
      require(_btcFeed != address(0));
      require(_multiSig != address(0));
      
      IMaster ms = IMaster(masterAddress);
      marketCreationRewards = IMarketCreationRewards(ms.getLatestAddress("MC"));
      marketUtility = IMarketUtility(ms.getLatestAddress("MU"));
      require(marketUtility.isAuthorizedUser(msg.sender));
      
      authorizedMultiSig = _multiSig;
      totalOptions = 3;
      predictionDecimalMultiplier = 10;
      defaultMaxRecords = 20;
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
          createMarket(0, i);
          createMarket(1, i);
      }
      _initializeEIP712("AM");
    }

    /**
    * @dev Create the market.
    * @param _marketCurrencyIndex The index of market currency feed
    * @param _marketTypeIndex The time duration of market.
    */
    function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex) public {
      MarketTypeData storage _marketType = marketTypeArray[_marketTypeIndex];
      require(!marketCreationPaused && !_marketType.paused);
      _closePreviousMarket( _marketTypeIndex, _marketCurrencyIndex);
      // marketUtility.update();
      uint32 _startTime = calculateStartTimeForMarket(_marketCurrencyIndex, _marketTypeIndex);
      (uint64 _minValue, uint64 _maxValue) = marketUtility.calculateOptionRange(_marketType.optionRangePerc, marketCurrencies[_marketCurrencyIndex].decimals, marketCurrencies[_marketCurrencyIndex].roundOfToNearest, marketCurrencies[_marketCurrencyIndex].marketFeed, marketCurrencies[_marketCurrencyIndex].currencyName);
      uint64 _marketIndex = uint64(marketBasicData.length);
      marketBasicData.push(MarketBasicData(_marketTypeIndex,_marketCurrencyIndex,_startTime, _marketType.predictionTime, _marketType.cooldownTime, _minValue, _maxValue, marketCurrencies[_marketCurrencyIndex].marketFeed));
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      (_marketCreationData.penultimateMarket, _marketCreationData.latestMarket) =
       (_marketCreationData.latestMarket, _marketIndex);
      (uint256 _stakingFactorMinStake, uint32 _stakingFactorWeightage, uint32 _currentPriceWeightage) = marketUtility.getPriceCalculationParams();
      marketPricingData[_marketIndex] = PricingData(_stakingFactorMinStake, _stakingFactorWeightage, _currentPriceWeightage, _marketType.minTimePassed);
      emit MarketQuestion(_marketIndex, marketCurrencies[_marketCurrencyIndex].currencyName, _marketTypeIndex, _startTime, _marketType.predictionTime, _minValue, _maxValue);
      emit OptionPricingParams(_marketIndex, _stakingFactorMinStake,_stakingFactorWeightage,_currentPriceWeightage,marketPricingData[_marketIndex].minTimePassed);
      address _msgSenderAddress = _msgSender();
      marketCreationRewards.calculateMarketCreationIncentive(_msgSenderAddress, _marketIndex);
      _placeInitialPrediction(_marketIndex, _msgSenderAddress);
    }

    function _placeInitialPrediction(uint64 _marketId, address _msgSenderAddress) internal {
      uint256 _defaultAmount = (10**predictionDecimalMultiplier).mul(mcDefaultPredictionAmount);
      (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress);
      if(_tokenLeft.add(_tokenReward) < _defaultAmount) {
        _deposit(_defaultAmount);
      }

      _placePrediction(_marketId, predictionToken, mcDefaultPredictionAmount/3, 1);
      _placePrediction(_marketId, predictionToken, mcDefaultPredictionAmount/3, 2);
      _placePrediction(_marketId, predictionToken, mcDefaultPredictionAmount - 2*(mcDefaultPredictionAmount/3), 3);
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
    function _closePreviousMarket(uint64 _marketTypeIndex, uint64 _marketCurrencyIndex) internal {
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      uint64 currentMarket = _marketCreationData.latestMarket;
      if(currentMarket != 0) {
        require(marketStatus(currentMarket) >= PredictionStatus.InSettlement);
        uint64 penultimateMarket = _marketCreationData.penultimateMarket;
        if(penultimateMarket > 0 && now >= marketSettleTime(penultimateMarket)) {
          _settleMarket(penultimateMarket);
        }
      }
    }

    /**
    * @dev Get market settle time
    * @return the time at which the market result will be declared
    */
    function marketSettleTime(uint256 _marketId) public view returns(uint32) {
      if(marketDataExtended[_marketId].settleTime > 0) {
        return marketDataExtended[_marketId].settleTime;
      }
      return marketBasicData[_marketId].startTime + (marketBasicData[_marketId].predictionTime * 2);
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
      require(marketTypeArray[_marketTypeIndex].paused != _flag);
      marketTypeArray[_marketTypeIndex].paused = _flag;
    }

    /**
    * @dev Function to deposit prediction token for participation in markets
    * @param _amount Amount of prediction token to deposit
    */
    function _deposit(uint _amount) internal {
      address payable _msgSenderAddress = _msgSender();
      _transferTokenFrom(predictionToken, _msgSenderAddress, address(this), _amount);
      userData[_msgSenderAddress].unusedBalance = userData[_msgSenderAddress].unusedBalance.add(_amount);
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
      return marketBasicData[_marketId].startTime + (marketBasicData[_marketId].predictionTime);
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
      (predictionPoints, isMultiplierApplied) = marketUtility.calculatePredictionPoints(_marketId, _prediction, _user, _userData.userMarketData[_marketId].multiplierApplied, _stake);
      if(isMultiplierApplied) {
        _userData.userMarketData[_marketId].multiplierApplied = true; 
      }
    }

    /**
    * @dev Settle the market, setting the winning option
    */
    function settleMarket(uint256 _marketId) external {
      _settleMarket(_marketId);
    }

    /**
    * @dev Settle the market explicitly by manually passing the price of market currency
    * @param _marketId Index of market
    * @param _marketSettleValue The current price of market currency.
    */
    function postMarketResult(uint256 _marketId, uint256 _marketSettleValue) external {
      require(msg.sender == authorizedMultiSig);
      require(marketBasicData[_marketId].feedAddress == address(0));
      if(marketStatus(_marketId) == PredictionStatus.InSettlement) {
        _postResult(_marketSettleValue, 0, _marketId);
      }
    }

    /**
    * @dev Settle the market, setting the winning option
    */
    function _settleMarket(uint256 _marketId) internal {
      address _feedAdd = marketCurrencies[marketBasicData[_marketId].currency].marketFeed;
      if(marketStatus(_marketId) == PredictionStatus.InSettlement && _feedAdd != address(0)) {
        (uint256 _value, uint256 _roundId) = marketUtility.getSettlemetPrice(_feedAdd, marketSettleTime(_marketId));
        _postResult(_value, _roundId, _marketId);
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
        _transferAsset(predictionToken, address(marketCreationRewards), (10**predictionDecimalMultiplier).mul(amountToTransfer));
        marketCreationRewards.depositMarketCreationReward(_marketId, (10**predictionDecimalMultiplier).mul(_marketFeeParams.marketCreatorFee[_marketId]));
      } else {
        delete _marketDataExtended.settleTime;
      }
      _setMarketStatus(_marketId, PredictionStatus.Settled);
      uint32 _winningOption; 
      if(_value < _marketBasicData.neutralMinValue) {
        _winningOption = 1;
      } else if(_value > _marketBasicData.neutralMaxValue) {
        _winningOption = 3;
      } else {
        _winningOption = 2;
      }
      _marketDataExtended.WinningOption = _winningOption;
      // uint64 predictionPointsOnWinningOption = marketOptionsAvailable[_marketId][_winningOption].predictionPoints;
      uint64 totalReward = _calculateRewardTally(_marketId, _winningOption);
      // (uint64 _rewardPoolShare, bool _thresholdReached) = marketCreationRewards.getMarketCreatorRPoolShareParams(_marketId, tokenParticipation);
      // if(_thresholdReached) {
        // if(
        //   predictionPointsOnWinningOption == 0
        // ){
        //   marketCreatorIncentive = _calculateAmulBdivC(_rewardPoolShare, tokenParticipation, 10000);
        //   tokenParticipation = tokenParticipation.sub(marketCreatorIncentive);
        // } else {
          // marketCreatorIncentive = _calculateAmulBdivC(_rewardPoolShare, totalReward, 10000);
          // totalReward = totalReward.sub(marketCreatorIncentive);
          // tokenParticipation = 0;
        // }
      // }  
      //  else {
      //   // if(
      //   //   predictionPointsOnWinningOption > 0
      //   // ){
      //     tokenParticipation = 0;
      //   // }
      // }
      _marketDataExtended.rewardToDistribute = totalReward;
      // _transferAsset(predictionToken, address(marketCreationRewards), (10**predictionDecimalMultiplier).mul(marketCreatorIncentive));
      // marketCreationRewards.depositMarketRewardPoolShare(_marketId, (10**predictionDecimalMultiplier).mul(marketCreatorIncentive), tokenParticipation);
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
        _expireTime =marketExpireTime(_marketId);
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
      UserData storage _userData = userData[_user];
      if(_userData.userMarketData[_marketId].claimedReward) {
        return (1, 0);
      }
      _userData.userMarketData[_marketId].claimedReward = true;
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
      uint256 _conversionRate = marketUtility.conversionRate(predictionToken);
      return (marketDataExtended[_marketId].totalStaked).mul(_conversionRate).mul(10**predictionDecimalMultiplier);
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

    /**
    * @dev Raise the dispute if wrong value passed at the time of market result declaration.
    * @param _proposedValue The proposed value of market currency.
    * @param proposalTitle The title of proposal created by user.
    * @param description The description of dispute.
    * @param solutionHash The ipfs solution hash.
    */
    function raiseDispute(uint256 _marketId, uint256 _proposedValue, string memory proposalTitle, string memory description, string memory solutionHash) public {
      // address payable _msgSenderAddress = _msgSender();
      // MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      // require(marketStatus(_marketId) == PredictionStatus.Cooling);
      // uint _stakeForDispute =  marketUtility.getDisputeResolutionParams();
      // _transferTokenFrom(plotToken, _msgSenderAddress, address(this), _stakeForDispute);
      // uint proposalId = governance.getProposalLength();
      // _marketDataExtended.disputeRaisedBy = _msgSenderAddress;
      // _marketDataExtended.disputeStakeAmount = uint64(_stakeForDispute.div(10**predictionDecimalMultiplier));
      // disputeProposalId[proposalId] = _marketId;
      // governance.createProposalwithSolution(proposalTitle, proposalTitle, description, 9, solutionHash, abi.encode(_marketId, _proposedValue));
      // emit DisputeRaised(_marketId, _msgSenderAddress, proposalId, _proposedValue);
      // _setMarketStatus(_marketId, PredictionStatus.InDispute);
    }

    function _transferTokenFrom(address _token, address _from, address _to, uint256 _amount) internal {
      IToken(_token).transferFrom(_from, _to, _amount);
    }

    /**
    * @dev Resolve the dispute if wrong value passed at the time of market result declaration.
    * @param _marketId Index of market.
    * @param _result The final proposed result of the market.
    */
    function resolveDispute(uint256 _marketId, uint256 _result) external onlyAuthorized {
      // delete marketCreationRewardData[_marketId].plotIncentive;
      // delete marketCreationRewardData[_marketId].ethIncentive;
      _resolveDispute(_marketId, true, _result);
      emit DisputeResolved(_marketId, true);
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      _transferAsset(plotToken, _marketDataExtended.disputeRaisedBy, (10**predictionDecimalMultiplier).mul(_marketDataExtended.disputeStakeAmount));
    }

    /**
    * @dev Resolve the dispute
    * @param _marketId Index of market.
    * @param accepted Flag mentioning if dispute is accepted or not
    * @param finalResult The final correct value of market currency.
    */
    function _resolveDispute(uint256 _marketId, bool accepted, uint256 finalResult) internal {
      require(marketStatus(_marketId) == PredictionStatus.InDispute);
      if(accepted) {
        _postResult(finalResult, 0, _marketId);
      }
      _setMarketStatus(_marketId, PredictionStatus.Settled);
    }

    /**
    * @dev Burns the tokens of member who raised the dispute, if dispute is rejected.
    * @param _proposalId Id of dispute resolution proposal
    */
    function burnDisputedProposalTokens(uint _proposalId) external onlyAuthorized {
      uint256 _marketId = disputeProposalId[_proposalId];
      _resolveDispute(_marketId, false, 0);
      emit DisputeResolved(_marketId, false);
      _transferAsset(plotToken, address(marketCreationRewards), (10**predictionDecimalMultiplier).mul(marketDataExtended[_marketId].disputeStakeAmount));
      // IToken(plotToken).transfer(address(marketCreationRewards),(10**predictionDecimalMultiplier).mul(marketDataExtended[_marketId].disputeStakeAmount));
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
    function _setMarketStatus(uint256 _marketId, PredictionStatus _status) internal {
      marketDataExtended[_marketId].predictionStatus = _status;
    }

    /**
    * @dev Gets the Option pricing params for market.
    * @param _marketId Index of market.
    * @param _option predicting option.
    * @return uint[] Array consist of pricing param.
    * @return uint32 start time of market.
    * @return address feed address for market.
    */
    function getMarketOptionPricingParams(uint _marketId, uint _option) external view returns(uint[] memory, uint32,address) {

      // [0] -> amount staked in `_option`
      // [1] -> Total amount staked in market
      // [2] -> Minimum prediction amount in market needed to kick-in staking factor in option pricing calculation
      // [3] -> Weightage given to staking factor in option pricing
      // [4] -> Weightage given to Current price factor in option pricing
      // [5] -> Till this time, time factor will be same for option pricing
      uint[] memory _optionPricingParams = new uint256[](6);
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      PricingData storage _marketPricingData = marketPricingData[_marketId];
      _optionPricingParams[0] = marketOptionsAvailable[_marketId][_option].amountStaked;
      _optionPricingParams[1] = marketDataExtended[_marketId].totalStaked;
      _optionPricingParams[2] = _marketPricingData.stakingFactorMinStake;
      _optionPricingParams[3] = _marketPricingData.stakingFactorWeightage;
      _optionPricingParams[4] = _marketPricingData.currentPriceWeightage;
      _optionPricingParams[5] = _marketPricingData.minTimePassed;
      return (_optionPricingParams,_marketBasicData.startTime,_marketBasicData.feedAddress);
    }

    /**
    * @dev Gets the Feed address for market.
    * @ param currencyType currency name.
    * @return address feed address for market.
    */
    function getMarketCurrencyData(bytes32 currencyType) external view returns(address) {
      uint typeIndex = marketCurrency[currencyType];
      MarketCurrency storage _marketCurrency = marketCurrencies[typeIndex];
      // Market currency should be valid
      require((_marketCurrency.currencyName == currencyType));
      return (_marketCurrency.marketFeed);

    } 

}
