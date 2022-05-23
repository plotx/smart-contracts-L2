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

import "./AllPlotMarkets_9.sol";

contract AllPlotMarkets_10 is AllPlotMarkets_9 {

  /**
    * @dev Deposit and Place prediction on behalf of another address
    * @param _predictFor Address of user, to place prediction for
    * @param _marketId Index of the market
    * @param _tokenDeposit prediction token amount to deposit
    * @param _prediction The option on which user placed prediction.
    * @param _plotPredictionAmount The PLOT amount staked by user at the time of prediction.
    * _tokenDeposit should be passed with 18 decimals
    * _plotPredictionAmount and _bPLOTPredictionAmount should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function depositAndPredictForWithDBPlot(address _predictFor, uint _tokenDeposit, uint _marketId, uint256 _prediction, uint64 _plotPredictionAmount, bool _dbPlotUsed) external {
      if(_dbPlotUsed) {
        UserData storage _userData = userData[_predictFor];
        require(!_userData.userMarketData[_marketId].predictedWithBlot);
        _userData.userMarketData[_marketId].predictedWithBlot = true;
      }
      require(_predictFor != address(0));
      address payable _msgSenderAddress = _msgSender();
      require(authToProxyPrediction[_msgSenderAddress]);
      uint64 _predictionStake = _plotPredictionAmount;
      //Can deposit only if prediction stake amount contains plot
      if(_plotPredictionAmount > 0 && _tokenDeposit > 0) {
        _depositFor(_tokenDeposit, _msgSenderAddress, _predictFor);
      }
      
      _placePrediction(_marketId, _predictFor, plotToken, _predictionStake, _prediction);
    }
}
