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

import "./AllPlotMarkets.sol";

contract AllPlotMarkets_2 is AllPlotMarkets {

    mapping(address => bool) public authToProxyPrediction;

    /**
    * @dev Function to deposit prediction token for participation in markets
    * @param _amount Amount of prediction token to deposit
    */
    function _depositFor(uint _amount, address _msgSenderAddress, address _depositForAddress) internal {
      _transferTokenFrom(predictionToken, _msgSenderAddress, address(this), _amount);
      UserData storage _userData = userData[_depositForAddress];
      _userData.unusedBalance = _userData.unusedBalance.add(_amount);
      emit Deposited(_depositForAddress, _amount, now);
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
    function depositAndPredictFor(address _predictFor, uint _tokenDeposit, uint _marketId, address _asset, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount) external {
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
        bPLOTInstance.convertToPLOT(_predictFor, address(this), _amount);
        _userData.unusedBalance = _userData.unusedBalance.add(_amount);
      }
      require(_asset == plotToken);
      _placePrediction(_marketId, _predictFor, _asset, _predictionStake, _prediction);
    }

}
