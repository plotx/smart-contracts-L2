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

import "./AllPlotMarkets_8.sol";

contract AllPlotMarkets_9 is AllPlotMarkets_8 {

  /**
    * @dev Internal function to deduct fee from the prediction amount
    * @param _marketId Index of the market
    * @param _amount Total preidction amount of the user
    * @param _msgSenderAddress User address
    */
  function _deductFee(uint _marketId, uint64 _amount, address _msgSenderAddress) internal returns(uint64 _amountPostFee){
    address _relayer;
    if(_msgSenderAddress != tx.origin) {
      _relayer = tx.origin;
    } else {
      _relayer = _msgSenderAddress;
    }
    //******************************************************************* */
    //Dont call getUintParams, pass prediction amount as input to handle fee and then calculate fee, multiplier, user level there itself
    // and passs the amount to be transferred as return value and then transfer it from here
    //******************************************************************* */
    
    // (, uint _cummulativeFeePercent)= IMarket(marketDataExtended[_marketId].marketCreatorContract).getUintParameters("CMFP");
    // _fee = _calculateAmulBdivC(uint64(_cummulativeFeePercent), _amount, 10000);
    uint64 _fee = IMarket(marketDataExtended[_marketId].marketCreatorContract).handleFee_2(_marketId, _amount, _msgSenderAddress, _relayer);
    _transferAsset(plotToken, marketDataExtended[_marketId].marketCreatorContract, (10**predictionDecimalMultiplier).mul(_fee));
    _amountPostFee = _amount.sub(_fee);
  }
}
