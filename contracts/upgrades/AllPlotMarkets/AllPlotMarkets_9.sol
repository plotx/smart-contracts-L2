/* Copyright (C) 2022 PlotX.io

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

import "./AllPlotMarkets_8.sol";

contract AllPlotMarkets_9 is AllPlotMarkets_8 {

  uint internal pendingbPLOT; // bPLOT amount pending to be converted to plot in the contract
  mapping(address => uint) internal accumulatedFee; // Fee accumulated per market type(cyclic/acyclic)

  /**
  * @dev Internal function to place initial prediction of the market creator
  * @param _marketId Index of the market to place prediction
  * @param _msgSenderAddress Address of the user who is placing the prediction
  */
  function _placeInitialPrediction(uint64 _marketId, address _msgSenderAddress, uint64 _initialLiquidity, uint64 _totalOptions) internal {
    uint256 _defaultAmount = (10**predictionDecimalMultiplier).mul(_initialLiquidity);
    if(userData[_msgSenderAddress].marketsParticipated.length > maxPendingClaims) {
      _withdrawReward(defaultMaxRecords, _msgSenderAddress);
    }

    (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress);
    uint _balanceAvailable = _tokenLeft.add(_tokenReward);
    if(_balanceAvailable < _defaultAmount) {
      _deposit(_defaultAmount.sub(_balanceAvailable), _msgSenderAddress);
    }
    address _predictionToken = predictionToken;
    uint64 _predictionAmount = _initialLiquidity/ _totalOptions;
    userData[_msgSenderAddress].marketsParticipated.push(_marketId);

    for(uint i = 1;i < _totalOptions; i++) {
      _provideLiquidity(_marketId, _msgSenderAddress, _predictionToken, _predictionAmount, i);
      _initialLiquidity = _initialLiquidity.sub(_predictionAmount);
    }
    _provideLiquidity(_marketId, _msgSenderAddress, _predictionToken, _initialLiquidity, _totalOptions);
  }

  /**
  * @dev Add liquidity on given option (Simplified version of _placePrediction, removed checks)
  * @param _marketId Index of the market
  * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
  * @param _predictionStake The amount staked by user at the time of prediction.
  * @param _prediction The option on which user placed prediction.
  * _predictionStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
  */
  function _provideLiquidity(uint _marketId, address _msgSenderAddress, address _asset, uint64 _predictionStake, uint256 _prediction) internal {
    uint decimalMultiplier = 10**predictionDecimalMultiplier;
    UserData storage _userData = userData[_msgSenderAddress];
    
    uint256 unusedBalance = _userData.unusedBalance;
    unusedBalance = unusedBalance.div(decimalMultiplier);
    if(_predictionStake > unusedBalance)
    {
      _withdrawReward(defaultMaxRecords, _msgSenderAddress);
      unusedBalance = _userData.unusedBalance;
      unusedBalance = unusedBalance.div(decimalMultiplier);
    }
    _userData.unusedBalance = (unusedBalance.sub(_predictionStake)).mul(decimalMultiplier);
  
    uint64 predictionPoints = IMarket(marketDataExtended[_marketId].marketCreatorContract).calculatePredictionPointsAndMultiplier(_msgSenderAddress, _marketId, _prediction, _predictionStake);
    require(predictionPoints > 0);

    
    PredictionData storage _predictionData = marketOptionsAvailable[_marketId][_prediction];

    _userData.userMarketData[_marketId].predictionData[_prediction].predictionPoints = _userData.userMarketData[_marketId].predictionData[_prediction].predictionPoints.add(predictionPoints);
    _predictionData.predictionPoints = _predictionData.predictionPoints.add(predictionPoints);
    
    _userData.userMarketData[_marketId].predictionData[_prediction].amountStaked = _userData.userMarketData[_marketId].predictionData[_prediction].amountStaked.add(_predictionStake);
    _predictionData.amountStaked = _predictionData.amountStaked.add(_predictionStake);
    _userData.totalStaked = _userData.totalStaked.add(_predictionStake);
    marketDataExtended[_marketId].totalStaked = marketDataExtended[_marketId].totalStaked.add(_predictionStake);
    
    emit PlacePrediction(_msgSenderAddress, _predictionStake, predictionPoints, _asset, _prediction, _marketId);
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
    UserData storage _userData = userData[_msgSenderAddress];

    require(!marketCreationPaused && _prediction <= (marketDataExtended[_marketId].optionRanges.length +1) && _prediction >0);
    require(now >= marketBasicData[_marketId].startTime && now <= marketExpireTime(_marketId));
    uint64 _predictionStakePostDeduction = _predictionStake;
    uint decimalMultiplier = 10**predictionDecimalMultiplier;
    uint256 unusedBalance = _userData.unusedBalance;
    unusedBalance = unusedBalance.div(decimalMultiplier);
    if(_predictionStake > unusedBalance || _userData.marketsParticipated.length > maxPendingClaims)
    {
      _withdrawReward(defaultMaxRecords, _msgSenderAddress);
      unusedBalance = _userData.unusedBalance;
      unusedBalance = unusedBalance.div(decimalMultiplier);
    }
    // require(_predictionStake <= unusedBalance);
    _userData.unusedBalance = (unusedBalance.sub(_predictionStake)).mul(decimalMultiplier);

    _predictionStakePostDeduction = _deductFee(_marketId, _predictionStake, _msgSenderAddress);
    
    uint64 predictionPoints = IMarket(marketDataExtended[_marketId].marketCreatorContract).calculatePredictionPointsAndMultiplier(_msgSenderAddress, _marketId, _prediction, _predictionStakePostDeduction);
    require(predictionPoints > 0);

    _storePredictionData(_marketId, _prediction, _msgSenderAddress, _predictionStakePostDeduction, predictionPoints);
    emit PlacePrediction(_msgSenderAddress, _predictionStake, predictionPoints, _asset, _prediction, _marketId);
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
    revert("DEPR");
  }

  /**
  * @dev Deposit and Place prediction on the available options of the market with both PLOT and BPLOT.
  * @param _marketId Index of the market
  * @param _tokenDeposit prediction token amount to deposit
  * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
  * @param _prediction The option on which user placed prediction.
  * @param _plotPredictionAmount The PLOT amount staked by user at the time of prediction.
  * @param _bPLOTPredictionAmount The BPLOT amount staked by user at the time of prediction.
  * _tokenDeposit should be passed with 18 decimals
  * _plotPredictionAmount and _bPLOTPredictionAmount should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
  */
  function depositAndPredictWithBoth(uint _tokenDeposit, uint _marketId, address _asset, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount) external {
    address payable _msgSenderAddress = _msgSender();
    uint64 _predictionStake = _plotPredictionAmount.add(_bPLOTPredictionAmount);
    //Can deposit only if prediction stake amount contains plot
    if(_plotPredictionAmount > 0 && _tokenDeposit > 0) {
      _deposit(_tokenDeposit, _msgSenderAddress);
    }
    if(_bPLOTPredictionAmount > 0) {
      UserData storage _userData = userData[_msgSenderAddress];
      require(!_userData.userMarketData[_marketId].predictedWithBlot);
      _userData.userMarketData[_marketId].predictedWithBlot = true;
      uint256 _amount = (10**predictionDecimalMultiplier).mul(_bPLOTPredictionAmount);
      // bPLOTInstance.convertToPLOT(_msgSenderAddress, address(this), _amount);
      bPLOTInstance.collectBPLOT(_msgSenderAddress, _amount);
      _userData.unusedBalance = _userData.unusedBalance.add(_amount);
    }
    // require(_asset == plotToken);
    _placePrediction(_marketId, _msgSenderAddress, plotToken, _predictionStake, _prediction);
  }

  /**
  * @dev Deposit and Place prediction on behalf of another address
  * @param _predictFor Address of user, to place prediction for
  * @param _marketId Index of the market
  * @param _tokenDeposit prediction token amount to deposit
  * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
  * @param _prediction The option on which user placed prediction.
  * @param _plotPredictionAmount The PLOT amount staked by user at the time of prediction.
  * @param _bPLOTPredictionAmount The BPLOT amount staked by user at the time of prediction.
  * _tokenDeposit should be passed with 18 decimals
  * _plotPredictionAmount and _bPLOTPredictionAmount should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
  */
  function depositAndPredictFor(address _predictFor, uint _tokenDeposit, uint _marketId, address _asset, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount) external {
    require(_predictFor != address(0));
    address payable _msgSenderAddress = _msgSender();
    require(authToProxyPrediction[_msgSenderAddress]);
    uint64 _predictionStake = _plotPredictionAmount.add(_bPLOTPredictionAmount);
    //Can deposit only if prediction stake amount contains plot
    if(_plotPredictionAmount > 0 && _tokenDeposit > 0) {
      _depositFor(_tokenDeposit, _msgSenderAddress, _predictFor);
    }
    if(_bPLOTPredictionAmount > 0) {
      UserData storage _userData = userData[_predictFor];
      require(!_userData.userMarketData[_marketId].predictedWithBlot);
      _userData.userMarketData[_marketId].predictedWithBlot = true;
      uint256 _amount = (10**predictionDecimalMultiplier).mul(_bPLOTPredictionAmount);
      // bPLOTInstance.convertToPLOT(_predictFor, address(this), _amount);
      bPLOTInstance.collectBPLOT(_predictFor, _amount);
      _userData.unusedBalance = _userData.unusedBalance.add(_amount);
    }
    // require(_asset == plotToken);
    _placePrediction(_marketId, _predictFor, plotToken, _predictionStake, _prediction);
  }

  /**
    * @dev Internal function to deduct fee from the prediction amount
    * @param _marketId Index of the market
    * @param _amount Total preidction amount of the user
    * @param _msgSenderAddress User address
    */
  function _deductFee(uint _marketId, uint64 _amount, address _msgSenderAddress) internal returns(uint64 _amountPostFee){
    uint64 _fee;
    address _relayer;
    if(_msgSenderAddress != tx.origin) {
      _relayer = tx.origin;
    } else {
      _relayer = _msgSenderAddress;
    }
    (, uint _cummulativeFeePercent)= IMarket(marketDataExtended[_marketId].marketCreatorContract).getUintParameters("CMFP");
    _fee = _calculateAmulBdivC(uint64(_cummulativeFeePercent), _amount, 10000);
    accumulatedFee[marketDataExtended[_marketId].marketCreatorContract] = accumulatedFee[marketDataExtended[_marketId].marketCreatorContract].add(_fee);
    // _transferAsset(plotToken, marketDataExtended[_marketId].marketCreatorContract, (10**predictionDecimalMultiplier).mul(_fee));
    IMarket(marketDataExtended[_marketId].marketCreatorContract).handleFee(_marketId, _fee, _msgSenderAddress, _relayer);
    _amountPostFee = _amount.sub(_fee);
  }

  /**
  * @dev Internal function to withdraw deposited and available assets
  * @param _token Amount of prediction token to withdraw
  * @param _maxRecords Maximum number of records to check
  * @param _tokenLeft Amount of prediction token left unused for user
  */
  function _withdraw(uint _token, uint _maxRecords, uint _tokenLeft, address _msgSenderAddress) internal {
    super._withdraw(_token, _maxRecords, _tokenLeft, _msgSenderAddress);
    uint bPlotBalance = bPLOTInstance.balanceOf(address(this));
    if(bPlotBalance > 0) {
      bPLOTInstance.convertToPLOT(address(this), address(this), bPlotBalance);
    }
  }

  function transferAccumulatedRewards() external {
    require(authorizedMarketCreator[msg.sender]);
    _transferAsset(plotToken, msg.sender, (10**predictionDecimalMultiplier).mul(accumulatedFee[msg.sender]));
  }

}
