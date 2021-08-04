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

import "./AllPlotMarkets_3.sol";

contract AllPlotMarkets_4 is AllPlotMarkets_3 {

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
      uint64 _predictionStakePostDeduction = _predictionStake;
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
      require(_predictionStake <= unusedBalance); // Redundant check, can be removed
      _userData.unusedBalance = (unusedBalance.sub(_predictionStake)).mul(decimalMultiplier);
      _predictionStakePostDeduction = _deductFee(_marketId, _predictionStake, _msgSenderAddress);
      
      uint64 predictionPoints = IMarket(marketDataExtended[_marketId].marketCreatorContract).calculatePredictionPointsAndMultiplier(_msgSenderAddress, _marketId, _prediction, _predictionStakePostDeduction);
      require(predictionPoints > 0);

      _storePredictionData(_marketId, _prediction, _msgSenderAddress, _predictionStakePostDeduction, predictionPoints);
      emit PlacePrediction(_msgSenderAddress, _predictionStake, predictionPoints, _asset, _prediction, _marketId);
    }
}