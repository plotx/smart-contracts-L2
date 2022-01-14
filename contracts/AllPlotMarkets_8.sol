/* Copyright (C) 2021 PlotX.io

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

import "./AllPlotMarkets_7.sol";

contract AllPlotMarkets_8 is AllPlotMarkets_7 {

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
  function depositAndPredictWithBoth_2(uint _tokenDeposit, uint _marketId, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount, uint64 optionPrice, bytes calldata signature) external {
    address payable _msgSenderAddress = _msgSender();
    UserData storage _userData = userData[_msgSenderAddress];
    uint64 _predictionStake = _plotPredictionAmount.add(_bPLOTPredictionAmount);
    //Can deposit only if prediction stake amount contains plot
    if(_plotPredictionAmount > 0 && _tokenDeposit > 0) {
      _deposit(_tokenDeposit, _msgSenderAddress);
    }
    if(_bPLOTPredictionAmount > 0) {
      require(!_userData.userMarketData[_marketId].predictedWithBlot);
      _userData.userMarketData[_marketId].predictedWithBlot = true;
      uint256 _amount = (10**predictionDecimalMultiplier).mul(_bPLOTPredictionAmount);
      bPLOTInstance.convertToPLOT(_msgSenderAddress, address(this), _amount);
      _userData.unusedBalance = _userData.unusedBalance.add(_amount);
    }
    
    require(!marketCreationPaused && _prediction <= (marketDataExtended[_marketId].optionRanges.length +1) && _prediction >0);
    require(now >= marketBasicData[_marketId].startTime && now <= marketExpireTime(_marketId));
    if(_userData.marketsParticipated.length > maxPendingClaims) {
      _withdrawReward(defaultMaxRecords, _msgSenderAddress);
    }

        uint decimalMultiplier = 10**predictionDecimalMultiplier;
    // if(_asset == predictionToken) {
      uint256 unusedBalance = _userData.unusedBalance;
      unusedBalance = unusedBalance.div(decimalMultiplier);
      if(_predictionStake > unusedBalance)
      {
        _withdrawReward(defaultMaxRecords, _msgSenderAddress);
        unusedBalance = _userData.unusedBalance;
        unusedBalance = unusedBalance.div(decimalMultiplier);
      }
      require(_predictionStake <= unusedBalance);
      _userData.unusedBalance = (unusedBalance.sub(_predictionStake)).mul(decimalMultiplier);
    _placePrediction_2(_marketId, _msgSenderAddress, _predictionStake, _prediction, optionPrice, signature);
  }

  function depositAndPredictWithBoth(uint _tokenDeposit, uint _marketId, address _asset, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount) external {
    revert("DEPR");
  }
  
  function depositAndPlacePrediction(uint _tokenDeposit, uint _marketId, address _asset, uint64 _predictionStake, uint256 _prediction) external {
    revert("DEPR");
  }

  function _placePrediction(uint _marketId, address _msgSenderAddress, address _asset, uint64 _predictionStake, uint256 _prediction) internal {
    revert("DEPR");
    // super._placePrediction(_marketId, _msgSenderAddress, _asset, _predictionStake, _prediction);
  }

  /**
  * @dev Place prediction on the available options of the market.
  * @param _marketId Index of the market
  * @param _predictionStake The amount staked by user at the time of prediction.
  * @param _prediction The option on which user placed prediction.
  * _predictionStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
  */
  function _placePrediction_2(uint _marketId, address _msgSenderAddress, uint64 _predictionStake, uint256 _prediction, uint64 optionPrice, bytes memory signature) internal {
    // UserData storage _userData = userData[_msgSenderAddress];
    
    // uint64 _predictionStakePostDeduction = _predictionStake;

    // } else {
    //   require(_asset == address(bPLOTInstance));
    //   require(!_userData.userMarketData[_marketId].predictedWithBlot);
    //   _userData.userMarketData[_marketId].predictedWithBlot = true;
    //   bPLOTInstance.convertToPLOT(_msgSenderAddress, address(this), (decimalMultiplier).mul(_predictionStake));
    //   _asset = plotToken;
    // }
    // address _relayer;
    // if(_msgSenderAddress != tx.origin) {
    //   _relayer = tx.origin;
    // } else {
    //   _relayer = _msgSenderAddress;
    // }
    (uint64 predictionPoints, uint64 _predictionStakePostDeduction, uint64 _fee) = IMarket(marketDataExtended[_marketId].marketCreatorContract).calculateFeeAndPositions(_msgSenderAddress, _marketId, _prediction, _predictionStake, marketBasicData[_marketId].startTime, optionPrice,signature);
    // MarketDataExtended memory _marketDataExtended = marketDataExtended[_marketId];
    _transferAsset(plotToken, marketDataExtended[_marketId].marketCreatorContract, (10**predictionDecimalMultiplier).mul(_fee));
    require(predictionPoints > 0);

    _storePredictionData(_marketId, _prediction, _msgSenderAddress, _predictionStakePostDeduction, predictionPoints);
    emit PlacePrediction(_msgSenderAddress, _predictionStake, predictionPoints, plotToken, _prediction, _marketId);
  }

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
      _transferAsset(plotToken, marketDataExtended[_marketId].marketCreatorContract, (10**predictionDecimalMultiplier).mul(_fee));
      IMarket(marketDataExtended[_marketId].marketCreatorContract).handleFee(_marketId, _fee, _msgSenderAddress, _relayer);
      _amountPostFee = _amount.sub(_fee);
    }
}
