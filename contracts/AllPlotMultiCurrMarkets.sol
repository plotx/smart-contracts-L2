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
import "./interfaces/IbPLOTToken.sol";
import "./interfaces/IAuth.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IALLCurrMarket.sol";

contract IMaster {
    function dAppToken() public view returns(address);
    function getLatestAddress(bytes2 _module) public view returns(address);
}

contract AllPlotMultiCurrMarkets is IAuth, NativeMetaTransaction {
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

    event Deposited(address indexed user, address asset, uint256 amount, uint256 timeStamp);
    event Withdrawn(address indexed user, address asset, uint256 amount, uint256 timeStamp);
    event MarketQuestion(uint256 indexed marketIndex, uint256 startTime, uint256 predictionTime, uint256 coolDownTime, uint256 setlementTime, uint64[] optionRanges, address marketCreatorContract);
    event MarketResult(uint256 indexed marketIndex, uint256[] totalReward, uint256 winningOption, uint256 closeValue);
    event MarketSettled(uint256 indexed marketIndex);
    // event MarketResult(uint256 indexed marketIndex, uint256 totalReward, uint256 winningOption, uint256 closeValue, uint256 roundId, uint256 daoFee, uint256 marketCreatorFee);
    event ReturnClaimed(address indexed user, uint256[] amount);
    event PlacePrediction(address indexed user,uint256 value, uint256 predictionPoints, address predictionAsset,uint256 prediction,uint256 indexed marketIndex);

    struct PredictionData {
      uint64 predictionPoints;
      mapping(address => uint64) amountStaked;
    }
    
    struct UserMarketData {
      bool predictedWithBlot;
      mapping(uint => PredictionData) predictionData;
    }

    struct UserData {
      mapping(address => uint128) totalStaked;
      uint128 lastClaimedIndex;
      uint[] marketsParticipated;
      mapping(address => uint) unusedBalance;
      mapping(uint => UserMarketData) userMarketData;
    }

    struct MarketBasicData {
      uint32 startTime;
      uint32 predictionTime;
      uint32 settlementTime;
      uint32 cooldownTime;
    }

    struct MarketDataExtended {
      uint64[] optionRanges;
      uint32 WinningOption;
      uint32 settleTime;
      address marketCreatorContract;
      // uint incentiveToDistribute;
      mapping(address => uint) rewardToDistribute;
      mapping(address => uint) totalStaked;
      PredictionStatus predictionStatus;
    }

    // mapping(address => uint256) public conversionRate;
    
    address internal masterAddress;
    address internal plotToken;
    address internal disputeResolution;

    struct PredictionCurrency {
      address token;
      address _priceFeed;
      // uint decimalMultiplier; // may remove it
    }

    // address internal predictionToken; // change (shifted to PredictionCurrency )

    IbPLOTToken internal bPLOTInstance;

    uint internal predictionDecimalMultiplier; // replace with function 
    uint internal defaultMaxRecords;
    bool public marketCreationPaused;
    uint public nextCurrencyIndex; // remove if using array

    MarketBasicData[] internal marketBasicData;

    mapping(address => bool) public authorizedMarketCreator;
    mapping(uint256 => MarketDataExtended) internal marketDataExtended;
    mapping(address => UserData) internal userData;

    mapping(uint =>mapping(uint=>PredictionData)) internal marketOptionsAvailable;

    mapping(uint => bool) internal marketSettleEventEmitted;

    mapping(uint => PredictionCurrency) public predictionCurrencies;
    mapping(address => uint) public currencyIndex;

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
      // predictionToken = _plotToken;
      authorized = _authorizedMultiSig;
      marketBasicData.push(MarketBasicData(0,0,0,0));
      _initializeEIP712("AA");
      predictionDecimalMultiplier = 10;
      defaultMaxRecords = 20;
      nextCurrencyIndex = 1;
    }

    /**
    * @dev Function to initialize the dependancies
    */
    function initializeDependencies() external {
      IMaster ms = IMaster(masterAddress);
      disputeResolution = ms.getLatestAddress("DR");
      bPLOTInstance = IbPLOTToken(ms.getLatestAddress("BL"));
    }

    function addPredictionCurrency(address _asset, address _feedAdd) external onlyAuthorized {
      require(currencyIndex[_asset] == 0);
      currencyIndex[_asset] = nextCurrencyIndex;
      predictionCurrencies[nextCurrencyIndex++] = PredictionCurrency(_asset,_feedAdd);
    }

    /**
    * @dev Whitelist an address to create market.
    * @param _authorized Address to whitelist.
    */
    function addAuthorizedMarketCreator(address _authorized) external onlyAuthorized {
      require(_authorized != address(0));
      authorizedMarketCreator[_authorized] = true;
    }

    /**
    * @dev de-whitelist an address to create market.
    * @param _authorized Address to whitelist.
    */
    function removeAuthorizedMarketCreator(address _authorized) external onlyAuthorized {
      authorizedMarketCreator[_authorized] = false;
    }

    /**
    * @dev Create the market.
    * @param _marketTimes Array of params as mentioned below
    * _marketTimes => [0] _startTime, [1] _predictionTIme, [2] _settlementTime, [3] _cooldownTime
    * @param _optionRanges Array of params as mentioned below
    * _optionRanges => For 3 options, the array will be with two values [a,b], First option will be the value less than zeroth index of this array, the next option will be the value less than first index of the array and the last option will be the value greater than the first index of array
    * @param _marketCreator Address of the user who initiated the market creation
    * @param _initialLiquidity Amount of tokens to be provided as initial liquidity to the market, to be split equally between all options. Can also be zero
    */
    function createMarket(uint32[] memory _marketTimes, uint64[] memory _optionRanges, address _marketCreator, uint64 _initialLiquidity, uint _predictionCurrencyIndex) 
    public 
    returns(uint64 _marketIndex)
    {
      require(_marketCreator != address(0));
      require(authorizedMarketCreator[msg.sender]);
      require(!marketCreationPaused);
      require(_predictionCurrencyIndex > 0 && _predictionCurrencyIndex < nextCurrencyIndex); // valid currency index
      _checkForValidMarketTimes(_marketTimes);
      _checkForValidOptionRanges(_optionRanges);
      _marketIndex = uint64(marketBasicData.length);
      marketBasicData.push(MarketBasicData(_marketTimes[0], _marketTimes[1], _marketTimes[2], _marketTimes[3]));
      marketDataExtended[_marketIndex].optionRanges = _optionRanges;
      marketDataExtended[_marketIndex].marketCreatorContract = msg.sender;
      emit MarketQuestion(_marketIndex, _marketTimes[0], _marketTimes[1], _marketTimes[3], _marketTimes[2], _optionRanges, msg.sender);
      if(_initialLiquidity > 0) {
        _placeInitialPrediction(_marketIndex, _marketCreator, _initialLiquidity, uint64(_optionRanges.length + 1), _predictionCurrencyIndex);
      }
      return _marketIndex;
    }

    /**
    * @dev Internal function to check for valid given market times.
    */
    function _checkForValidMarketTimes(uint32[] memory _marketTimes) internal pure {
      for(uint i=0;i<_marketTimes.length;i++) {
        require(_marketTimes[i] != 0);
      }
      require(_marketTimes[2] > _marketTimes[1]); // Settlement time should be greater than prediction time
    }

    /**
    * @dev Internal function to check for valid given option ranges.
    */
    function _checkForValidOptionRanges(uint64[] memory _optionRanges) internal pure {
      for(uint i=0;i<_optionRanges.length;i++) {
        require(_optionRanges[i] != 0);
        if( i > 0) {
          require(_optionRanges[i] > _optionRanges[i - 1]);
        }
      }
    }
    
    /**
     * @dev Internal function to place initial prediction of the market creator
     * @param _marketId Index of the market to place prediction
     * @param _msgSenderAddress Address of the user who is placing the prediction
     */
    function _placeInitialPrediction(uint64 _marketId, address _msgSenderAddress, uint64 _initialLiquidity, uint64 _totalOptions, uint _predictionCurrencyIndex) internal {
      PredictionCurrency storage _predictionCurr = predictionCurrencies[_predictionCurrencyIndex];
      uint256 _defaultAmount = (10**predictionDecimalMultiplier).mul(_initialLiquidity); // calculate multiplier if needed
      (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress, _predictionCurr.token);
      uint _balanceAvailable = _tokenLeft.add(_tokenReward);
      if(_balanceAvailable < _defaultAmount) {
        _deposit(_defaultAmount.sub(_balanceAvailable), _msgSenderAddress, _predictionCurr.token);
      }
      address _predictionToken = _predictionCurr.token;
      uint64 _predictionAmount = _initialLiquidity/ _totalOptions;
      for(uint i = 1;i < _totalOptions; i++) {
        _placePrediction(_marketId, _msgSenderAddress, _predictionToken, _predictionAmount, i);
        _initialLiquidity = _initialLiquidity.sub(_predictionAmount);
      }
      _placePrediction(_marketId, _msgSenderAddress, _predictionToken, _initialLiquidity, _totalOptions);
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
    * @dev Get market settle time
    * @param _marketId Index of the market
    * @return the time at which the market result will be declared
    */
    function marketSettleTime(uint256 _marketId) public view returns(uint32) {
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      if(_marketDataExtended.settleTime > 0) {
        return _marketDataExtended.settleTime;
      }
      return _marketBasicData.startTime + (_marketBasicData.settlementTime);
    }

    /**
    * @dev Gets the status of market.
    * @param _marketId Index of the market
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
    * @param _marketId Index of the market
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
    * @dev Function to deposit prediction token for participation in markets
    * @param _amount Amount of prediction token to deposit
    */
    function _deposit(uint _amount, address _msgSenderAddress, address _asset) internal {
      _transferTokenFrom(_asset, _msgSenderAddress, address(this), _amount);
      UserData storage _userData = userData[_msgSenderAddress];
      _userData.unusedBalance[_asset] = _userData.unusedBalance[_asset].add(_amount);
      emit Deposited(_msgSenderAddress, _asset, _amount, now);
    }

    /**
    * @dev Withdraw provided amount of deposited and available prediction token
    * @param _token Amount of prediction token to withdraw
    * @param _maxRecords Maximum number of records to check
    */
    function withdraw(uint _token, uint _maxRecords, address _asset) public {
      address payable _msgSenderAddress = _msgSender();
      (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress, _asset);
      _tokenLeft = _tokenLeft.add(_tokenReward);
      _withdraw(_token, _maxRecords, _tokenLeft, _msgSenderAddress, _asset);
    }

    /**
    * @dev Internal function to withdraw deposited and available assets
    * @param _token Amount of prediction token to withdraw
    * @param _maxRecords Maximum number of records to check
    * @param _tokenLeft Amount of prediction token left unused for user
    */
    function _withdraw(uint _token, uint _maxRecords, uint _tokenLeft, address _msgSenderAddress, address _asset) internal {
      _withdrawReward(_maxRecords, _msgSenderAddress);
      userData[_msgSenderAddress].unusedBalance[_asset] = _tokenLeft.sub(_token);
      require(_token > 0);
      _transferAsset(_asset, _msgSenderAddress, _token);
      emit Withdrawn(_msgSenderAddress, _asset, _token, now);
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
    * @dev Deposit and Place prediction on the available options of the market with both PLOT and BPLOT.
    * @param _marketId Index of the market
    * @param _tokenDeposit prediction token amount to deposit
    * @param _prediction The option on which user placed prediction.
    * @param _plotPredictionAmount The PLOT amount staked by user at the time of prediction.
    * @param _bPLOTPredictionAmount The BPLOT amount staked by user at the time of prediction.
    * _tokenDeposit should be passed with 18 decimals
    * _plotPredictionAmount and _bPLOTPredictionAmount should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function depositAndPredictWithPlotAndBPlot(uint _tokenDeposit, uint _marketId, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount) external {
      // require(_asset == plotToken);
      address payable _msgSenderAddress = _msgSender();
      UserData storage _userData = userData[_msgSenderAddress];
      uint64 _predictionStake = _plotPredictionAmount.add(_bPLOTPredictionAmount);
      //Can deposit only if prediction stake amount contains plot
      if(_plotPredictionAmount > 0 && _tokenDeposit > 0) {
        _deposit(_tokenDeposit, _msgSenderAddress, plotToken);
      }
      if(_bPLOTPredictionAmount > 0) {
        require(!_userData.userMarketData[_marketId].predictedWithBlot);
        _userData.userMarketData[_marketId].predictedWithBlot = true;
        uint256 _amount = (10**predictionDecimalMultiplier).mul(_bPLOTPredictionAmount);
        bPLOTInstance.convertToPLOT(_msgSenderAddress, address(this), _amount);
        _userData.unusedBalance[plotToken] = _userData.unusedBalance[plotToken].add(_amount);
      }
      _placePrediction(_marketId, _msgSenderAddress, plotToken, _predictionStake, _prediction);
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
      uint _currIndex = currencyIndex[_asset];
      require(_currIndex > 0 && _currIndex < nextCurrencyIndex); // valid prediction currency
      address payable _msgSenderAddress = _msgSender();
      if(_tokenDeposit > 0) {
        _deposit(_tokenDeposit, _msgSenderAddress, _asset);
      }
      _placePrediction(_marketId, _msgSenderAddress, _asset, _predictionStake, _prediction);
    }

    /**
    * @dev Place prediction on the available options of the market.
    * @param _marketId Index of the market
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param _prediction The option on which user placed prediction.
    * _predictionStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function _placePrediction(uint _marketId, address _msgSenderAddress, address _asset, uint64 _predictionStake, uint256 _prediction) internal {
      require(!marketCreationPaused && _prediction <= (marketDataExtended[_marketId].optionRanges.length +1) && _prediction >0);
      require(now >= marketBasicData[_marketId].startTime && now <= marketExpireTime(_marketId));
      uint64 _predictionStakePostDeduction = _predictionStake;
      uint decimalMultiplier = 10**predictionDecimalMultiplier; // need to update
      UserData storage _userData = userData[_msgSenderAddress];
      if(_asset != address(bPLOTInstance)) {
        uint256 unusedBalance = _userData.unusedBalance[_asset];
        unusedBalance = unusedBalance.div(decimalMultiplier);
        if(_predictionStake > unusedBalance)
        {
          _withdrawReward(defaultMaxRecords, _msgSenderAddress);
          unusedBalance = _userData.unusedBalance[_asset];
          unusedBalance = unusedBalance.div(decimalMultiplier);
        }
        require(_predictionStake <= unusedBalance);
        _userData.unusedBalance[_asset] = (unusedBalance.sub(_predictionStake)).mul(decimalMultiplier);
      } else {
        require(_asset == address(bPLOTInstance));
        require(!_userData.userMarketData[_marketId].predictedWithBlot);
        _userData.userMarketData[_marketId].predictedWithBlot = true;
        bPLOTInstance.convertToPLOT(_msgSenderAddress, address(this), (decimalMultiplier).mul(_predictionStake));
        _asset = plotToken;
      }
      _predictionStakePostDeduction = _deductFee(_marketId, _predictionStake, _msgSenderAddress, _asset);
      
      uint64 predictionPoints = IALLCurrMarket(marketDataExtended[_marketId].marketCreatorContract).calculatePredictionPointsAndMultiplier(_msgSenderAddress, _marketId, _prediction, _predictionStakePostDeduction,_asset);
      require(predictionPoints > 0);

      _storePredictionData(_marketId, _prediction, _msgSenderAddress, _predictionStakePostDeduction, predictionPoints, _asset);
      emit PlacePrediction(_msgSenderAddress, _predictionStake, predictionPoints, _asset, _prediction, _marketId);
    }

    /**
     * @dev Internal function to deduct fee from the prediction amount
     * @param _marketId Index of the market
     * @param _amount Total preidction amount of the user
     * @param _msgSenderAddress User address
     */
    function _deductFee(uint _marketId, uint64 _amount, address _msgSenderAddress, address _asset) internal returns(uint64 _amountPostFee){
      uint64 _fee;
      address _relayer;
      if(_msgSenderAddress != tx.origin) {
        _relayer = tx.origin;
      } else {
        _relayer = _msgSenderAddress;
      }
      (, uint _cummulativeFeePercent)= IALLCurrMarket(marketDataExtended[_marketId].marketCreatorContract).getUintParameters("CMFP");
      _fee = _calculateAmulBdivC(uint64(_cummulativeFeePercent), _amount, 10000);
      _transferAsset(_asset, marketDataExtended[_marketId].marketCreatorContract, (10**predictionDecimalMultiplier).mul(_fee));
      IALLCurrMarket(marketDataExtended[_marketId].marketCreatorContract).handleFee(_marketId, _fee, _msgSenderAddress, _relayer, _asset);
      _amountPostFee = _amount.sub(_fee);
    }

    /**
    * @dev Settle the market, setting the winning option
    * @param _marketId Index of market
    */
    function settleMarket(uint256 _marketId, uint256 _value) external {
      require(marketDataExtended[_marketId].marketCreatorContract == msg.sender);
      if(marketStatus(_marketId) == PredictionStatus.InSettlement) {
        _postResult(_value, _marketId);
      }
    }

    /**
    * @dev Function to settle the market when a dispute is raised
    * @param _marketId Index of market
    * @param _marketSettleValue The current price of market currency.
    */
    function postMarketResult(uint256 _marketId, uint256 _marketSettleValue) external {
      require(marketStatus(_marketId) == PredictionStatus.InDispute);
      require(msg.sender == disputeResolution);
      _postResult(_marketSettleValue, _marketId);
    }

    /**
    * @dev Function to emit MarketSettled event of given market.
    * @param _marketId Index of market
    */
    function emitMarketSettledEvent(uint256 _marketId) external {
      require(!marketSettleEventEmitted[_marketId]);
      require(marketStatus(_marketId) == PredictionStatus.Settled);
      marketSettleEventEmitted[_marketId] = true;
      emit MarketSettled(_marketId);
    }

    // function TEMP_emitMarketSettledEvent(uint256 _fromMarketId, uint256 _toMarketId) external {
    //   for(uint i = _fromMarketId; i<= _toMarketId; i++) {
    //     require(!marketSettleEventEmitted[i]);
    //     require(marketStatus(i) == PredictionStatus.Settled);
    //     marketSettleEventEmitted[i] = true;
    //     emit MarketSettled(i);
    //   }
    // }

    /**
    * @dev Calculate the result of market.
    * @param _value The current price of market currency.
    * @param _marketId Index of market
    */
    function _postResult(uint256 _value, uint256 _marketId) internal {
      require(now >= marketSettleTime(_marketId));
      require(_value > 0);
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      if(_marketDataExtended.predictionStatus != PredictionStatus.InDispute) {
        _marketDataExtended.settleTime = uint32(now);
      } else {
        delete _marketDataExtended.settleTime;
      }
      _marketDataExtended.predictionStatus = PredictionStatus.Settled;
      uint32 _winningOption;
      for(uint32 i = 0; i< _marketDataExtended.optionRanges.length;i++) {
        if(_value < _marketDataExtended.optionRanges[i]) {
          _winningOption = i+1;
          break;
        }
      }
      if(_winningOption == 0) {
        _winningOption = uint32(_marketDataExtended.optionRanges.length + 1);
      }
      _marketDataExtended.WinningOption = _winningOption;
      uint[] memory allCurrTotalRewards = _pushMarketTotalRewards(_marketId, _winningOption);
      // uint64 totalReward = _calculateRewardTally(_marketId, _winningOption);
      // _marketDataExtended.rewardToDistribute = totalReward; // need to do it for all assets - done
      
      //need to fix - fixed
      emit MarketResult(_marketId, allCurrTotalRewards, _winningOption, _value);
    }

    function _pushMarketTotalRewards(uint _marketId, uint32 _winningOption) internal returns(uint[] memory) {
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      uint _nextCurrIndex = nextCurrencyIndex;
      uint[] memory allCurrTotalRewards= new uint[](_nextCurrIndex.sub(2));
      for(uint i = 1; i < _nextCurrIndex; i++) {
         address _asset = predictionCurrencies[i].token;
         uint _reward = _calculateRewardTally(_marketId, _winningOption, _asset);
         _marketDataExtended.rewardToDistribute[_asset] = _reward;
        allCurrTotalRewards[i.sub(1)] = _reward;
      }
    }

    /**
    * @dev Internal function to calculate the reward.
    * @param _marketId Index of market
    * @param _winningOption WinningOption of market
    */
    function _calculateRewardTally(uint256 _marketId, uint256 _winningOption, address _asset) internal view returns(uint64 totalReward){
      for(uint i=1; i <= marketDataExtended[_marketId].optionRanges.length +1; i++){
        uint64 _tokenStakedOnOption = marketOptionsAvailable[_marketId][i].amountStaked[_asset];
        if(i != _winningOption) {
          totalReward = totalReward.add(_tokenStakedOnOption);
        }
      }
    }

    /**
    * @dev Claim the pending return of the market.
    * @param maxRecords Maximum number of records to claim reward for
    */
    function _withdrawReward(uint256 maxRecords, address _msgSenderAddress) internal {
      // address payable _msgSenderAddress = _msgSender();
      uint256 i;
      UserData storage _userData = userData[_msgSenderAddress];
      uint len = _userData.marketsParticipated.length;
      uint lastClaimed = len;
      uint count;
      uint nextCurrIndex = nextCurrencyIndex;
      uint[] memory tokenReward = new uint[](nextCurrIndex);
      require(!marketCreationPaused);
      for(i = _userData.lastClaimedIndex; i < len && count < maxRecords; i++) {
        (uint claimed, uint[] memory tempTokenReward) = claimReturn(_msgSenderAddress, _userData.marketsParticipated[i]);
        if(claimed > 0) {
          delete _userData.marketsParticipated[i];
          for(uint j=0;j<nextCurrIndex;j++) {

            tokenReward[j] = tokenReward[j].add(tempTokenReward[j]);
          }
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
      // need to fix - fixed
      emit ReturnClaimed(_msgSenderAddress, tokenReward);
      for(uint i=1;i<=nextCurrencyIndex;i++) {
        address _asset = predictionCurrencies[i].token;
        _userData.unusedBalance[_asset] = _userData.unusedBalance[_asset].add(tokenReward[i.sub(1)].mul(10**predictionDecimalMultiplier));
      }
      _userData.lastClaimedIndex = uint128(lastClaimed);
    }

    /**
    * @dev FUnction to return users unused deposited balance including the return earned in markets
    * @param _user Address of user
    * return prediction token Unused in deposit
    * return prediction token Return from market
    */
    function getUserUnusedBalance(address _user, address _asset) public view returns(uint256, uint256){
      uint tokenReward;
      uint decimalMultiplier = 10**predictionDecimalMultiplier;
      UserData storage _userData = userData[_user];
      uint len = _userData.marketsParticipated.length;
      for(uint i = _userData.lastClaimedIndex; i < len; i++) {
        tokenReward = tokenReward.add(getReturn(_user, _userData.marketsParticipated[i])[currencyIndex[_asset].sub(1)]);
      }
      return (_userData.unusedBalance[_asset], tokenReward.mul(decimalMultiplier));
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
    * @return _optionRanges Maximum values of all the options
    * @return _tokenStaked uint[] memory representing the prediction token staked on each option ranges of the market.
    * @return _predictionTime uint representing the type of market.
    * @return _expireTime uint representing the time at which market closes for prediction
    * @return _predictionStatus uint representing the status of the market.
    */
    function getMarketData(uint256 _marketId) external view returns
       (uint64[] memory _optionRanges, /*uint[] memory _tokenStaked,*/uint _predictionTime,uint _expireTime, PredictionStatus _predictionStatus){
        MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
        _predictionTime = _marketBasicData.predictionTime;
        
        _expireTime = marketExpireTime(_marketId);
        _predictionStatus = marketStatus(_marketId);
        _optionRanges = marketDataExtended[_marketId].optionRanges;
        //======== need to fix ===========//
       //  _tokenStaked = new uint[](marketDataExtended[_marketId].optionRanges.length +1);
       //  for (uint i = 0; i < marketDataExtended[_marketId].optionRanges.length +1; i++) {
       //    _tokenStaked[i] = marketOptionsAvailable[_marketId][i+1].amountStaked;
       // }
    }

    /**
    * @dev Get total options available in the given market id.
    * @param _marketId Index of the market.
    * @return Total number of options.
    */
    function getTotalOptions(uint256 _marketId) external view returns(uint) {
      return marketDataExtended[_marketId].optionRanges.length + 1;
    }

    /**
    * @dev Claim the return amount of the specified address.
    * @param _user User address
    * @param _marketId Index of market
    * @return Flag, if 0:cannot claim, 1: Already Claimed, 2: Claimed; Return in prediction token
    */
    function claimReturn(address _user, uint _marketId) internal view returns(uint256, uint256[] memory) {

      if(marketStatus(_marketId) != PredictionStatus.Settled) {
        return (0, new uint[](0));
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
    function getReturn(address _user, uint _marketId) public view returns (uint[] memory returnAmount){
      if(marketStatus(_marketId) != PredictionStatus.Settled || getTotalPredictionPoints(_marketId) == 0) {
       return (returnAmount);
      }
      uint256 _winningOption = marketDataExtended[_marketId].WinningOption;
      UserData storage _userData = userData[_user];
      uint _nextCurrIndex = nextCurrencyIndex;
      returnAmount = new uint[](_nextCurrIndex);
      for(uint i=1;i<_nextCurrIndex;i++) {
        address _asset = predictionCurrencies[i].token;
        returnAmount[i.sub(1)] = _userData.userMarketData[_marketId].predictionData[_winningOption].amountStaked[_asset];
        uint256 userPredictionPointsOnWinngOption = _userData.userMarketData[_marketId].predictionData[_winningOption].predictionPoints;
        if(userPredictionPointsOnWinngOption > 0) {
          returnAmount[i.sub(1)] = _addUserReward(_marketId, returnAmount[i.sub(1)], _winningOption, userPredictionPointsOnWinngOption, _asset);
        }
      }
      return returnAmount;
    }

    /**
    * @dev Adds the reward in the total return of the specified address.
    * @param returnAmount The return amount.
    * @return uint[] memory representing the return amount after adding reward.
    */
    function _addUserReward(uint256 _marketId, uint returnAmount, uint256 _winningOption, uint256 _userPredictionPointsOnWinngOption, address _asset) internal view returns(uint){
        return returnAmount.add(
            _userPredictionPointsOnWinngOption.mul(marketDataExtended[_marketId].rewardToDistribute[_asset]).div(marketOptionsAvailable[_marketId][_winningOption].predictionPoints)
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
//=================need to fix===================//
    // /**
    // * @dev Returns total assets staked in market in PLOT value
    // * @param _marketId Index of market
    // * @return tokenStaked Total prediction token staked on market value in PLOT
    // */
    // function getTotalStakedWorthInPLOT(uint256 _marketId) public view returns(uint256 _tokenStakedWorth) {
    //   return (marketDataExtended[_marketId].totalStaked).mul(10**predictionDecimalMultiplier);
    //   // return (marketDataExtended[_marketId].totalStaked).mul(conversionRate[plotToken]).mul(10**predictionDecimalMultiplier);
    // }

    /**
    * @dev Returns total prediction points allocated to users
    * @param _marketId Index of market
    * @return predictionPoints total prediction points allocated to users
    */
    function getTotalPredictionPoints(uint _marketId) public view returns(uint64 predictionPoints) {
      for(uint256 i = 1; i<= marketDataExtended[_marketId].optionRanges.length +1;i++) {
        predictionPoints = predictionPoints.add(marketOptionsAvailable[_marketId][i].predictionPoints);
      }
    }

    /**
    * @dev Stores the prediction data.
    * @param _prediction The option on which user place prediction.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param predictionPoints The positions user got during prediction.
    */
    function _storePredictionData(uint _marketId, uint _prediction, address _msgSenderAddress, uint64 _predictionStake, uint64 predictionPoints, address _asset) internal {
      UserData storage _userData = userData[_msgSenderAddress];
      PredictionData storage _predictionData = marketOptionsAvailable[_marketId][_prediction];
      if(!_hasUserParticipated(_marketId, _msgSenderAddress)) {
        _userData.marketsParticipated.push(_marketId);
      }
      _userData.userMarketData[_marketId].predictionData[_prediction].predictionPoints = _userData.userMarketData[_marketId].predictionData[_prediction].predictionPoints.add(predictionPoints);
      _predictionData.predictionPoints = _predictionData.predictionPoints.add(predictionPoints);
      
      _userData.userMarketData[_marketId].predictionData[_prediction].amountStaked[_asset] = _userData.userMarketData[_marketId].predictionData[_prediction].amountStaked[_asset].add(_predictionStake);
      _predictionData.amountStaked[_asset] = _predictionData.amountStaked[_asset].add(_predictionStake);
      _userData.totalStaked[_asset] = _userData.totalStaked[_asset].add(_predictionStake);
      marketDataExtended[_marketId].totalStaked[_asset] = marketDataExtended[_marketId].totalStaked[_asset].add(_predictionStake);
      
    }

    /**
    * @dev Function to check if user had participated in given market
    * @param _marketId Index of market
    * @param _user Address of user
    */
    function _hasUserParticipated(uint256 _marketId, address _user) internal view returns(bool _hasParticipated) {
      for(uint i = 1;i <= marketDataExtended[_marketId].optionRanges.length +1; i++) {
        if(userData[_user].userMarketData[_marketId].predictionData[i].predictionPoints > 0) {
          _hasParticipated = true;
          break;
        }
      }
    }

    /**
    * @dev Internal function to call transferFrom function of a given token
    * @param _token Address of the ERC20 token
    * @param _from Address from which the tokens are to be received
    * @param _to Address to which the tokens are to be transferred
    * @param _amount Amount of tokens to transfer. In Wei
    */
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
    function getUserFlags(uint256 _marketId, address _user) external view returns(bool) {
      return (
              userData[_user].userMarketData[_marketId].predictedWithBlot
      );
    }
//=============== need to fix//
    // *
    // * @dev Gets the result of the market.
    // * @param _marketId Index of market.
    // * @return uint256 representing the winning option of the market.
    // * @return uint256 Value of market currently at the time closing market.
    // * @return uint256 representing the positions of the winning option.
    // * @return uint[] memory representing the reward to be distributed.
    // * @return uint256 representing the prediction token staked on winning option.
    
    // function getMarketResults(uint256 _marketId) external view returns(uint256 _winningOption, uint256, uint256, uint256) {
    //   _winningOption = marketDataExtended[_marketId].WinningOption;
    //   return (_winningOption, marketOptionsAvailable[_marketId][_winningOption].predictionPoints, marketDataExtended[_marketId].rewardToDistribute, marketOptionsAvailable[_marketId][_winningOption].amountStaked);
    // }

    /**
    * @dev Internal function set market status
    * @param _marketId Index of market
    * @param _status Status of market to set
    */
    function setMarketStatus(uint256 _marketId, PredictionStatus _status) public {
      require(msg.sender == disputeResolution);
      marketDataExtended[_marketId].predictionStatus = _status;
    }
//===================need to fix according to option pricing needs====
    /**
    * @dev Gets the Option pricing params for market.
    * @param _marketId Index of market.
    * @param _option predicting option.
    * @return uint[] Array consist of pricing param.
    * @return uint32 start time of market.
    * @return address feed address for market.
    */
    function getMarketOptionPricingParams(uint _marketId, uint _option) external view returns(uint[] memory, uint32) {

      // [0] -> amount staked in `_option`
      // [1] -> Total amount staked in market
      uint[] memory _optionPricingParams = new uint256[](2);
      MarketBasicData storage _marketBasicData = marketBasicData[_marketId];
      // need to fix -  send equivalent amount in usd
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      uint _maxOptionRange = _marketDataExtended.optionRanges.length+2;
      uint _nextOptionIndex = nextCurrencyIndex;
      for(uint i=1;i<_nextOptionIndex;i++) {
        for(uint j=1;j<_maxOptionRange;j++)
        {
          uint usdEquivalentStake = getEquivalentTokens(marketOptionsAvailable[_marketId][j].amountStaked[predictionCurrencies[i].token],i);
          if(j==_option){
            _optionPricingParams[0] = _optionPricingParams[0].add(usdEquivalentStake);
          }
          _optionPricingParams[1]=_optionPricingParams[1].add(usdEquivalentStake);
        }
      }
      // _optionPricingParams[0] = 100;//marketOptionsAvailable[_marketId][_option].amountStaked;
      // _optionPricingParams[1] = 100;//marketDataExtended[_marketId].totalStaked;
      return (_optionPricingParams,_marketBasicData.startTime);
    }

    function getEquivalentTokens(uint _amount, uint _currencyIndex) public view returns(uint) {
      // need to handle overflow
      return  uint64(_amount.mul(10**8).div(IOracle(predictionCurrencies[_currencyIndex].token).getLatestPrice()));

    }

    /**
    * @dev Get total number of markets created till now.
    */
    function getTotalMarketsLength() external view returns(uint64) {
      return uint64(marketBasicData.length);
    }

    /**
    * @dev Get total amount staked by the user in markets.
    */
    function getTotalStakedByUser(address _user) external view returns(uint[] memory totalStakes) {
      
      totalStakes = new uint[](nextCurrencyIndex);
      for(uint i=1;i<=nextCurrencyIndex;i++) {
        totalStakes[i.sub(1)] = userData[_user].totalStaked[predictionCurrencies[i].token];
      }
    }
}
