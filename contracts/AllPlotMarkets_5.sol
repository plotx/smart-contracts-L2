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

import "./AllPlotMarkets_4.sol";

contract AllPlotMarkets_5 is AllPlotMarkets_4 {

    /**
    * @dev Create the market.
    * @param _marketTimes Array of params as mentioned below
    * _marketTimes => [0] _startTime, [1] _predictionTIme, [2] _settlementTime, [3] _cooldownTime
    * @param _optionRanges Array of params as mentioned below
    * _optionRanges => For 3 options, the array will be with two values [a,b], First option will be the value less than zeroth index of this array, the next option will be the value less than first index of the array and the last option will be the value greater than the first index of array
    * @param _marketCreator Address of the user who initiated the market creation
    * @param _initialLiquidities Amount of tokens to be provided as initial liquidity to the market, to be split equally between all options. Can also be zero
    */
    function createMarketWithVariableLiquidity(uint32[] memory _marketTimes, uint64[] memory _optionRanges, address _marketCreator, uint64[] memory _initialLiquidities) 
    public 
    returns(uint64 _marketIndex)
    {
      require(_marketCreator != address(0));
      require(authorizedMarketCreator[msg.sender]);
      require(!marketCreationPaused);
      _checkForValidMarketTimes(_marketTimes);
      _checkForValidOptionRanges(_optionRanges);
      _marketIndex = uint64(marketBasicData.length);
      marketBasicData.push(MarketBasicData(_marketTimes[0], _marketTimes[1], _marketTimes[2], _marketTimes[3]));
      marketDataExtended[_marketIndex].optionRanges = _optionRanges;
      marketDataExtended[_marketIndex].marketCreatorContract = msg.sender;
      emit MarketQuestion(_marketIndex, _marketTimes[0], _marketTimes[1], _marketTimes[3], _marketTimes[2], _optionRanges, msg.sender);
    //   if(_initialLiquidity > 0) {
        _initialPredictionWithVariableLiquidity(_marketIndex, _marketCreator, _initialLiquidities, uint64(_optionRanges.length + 1));
    //   }
      return _marketIndex;
    }

    /**
     * @dev Internal function to place initial prediction of the market creator
     * @param _marketId Index of the market to place prediction
     * @param _msgSenderAddress Address of the user who is placing the prediction
     */
    function _initialPredictionWithVariableLiquidity(uint64 _marketId, address _msgSenderAddress, uint64[] memory _initialLiquidities, uint64 _totalOptions) internal {
      uint64 _initialLiquidity;
      for(uint i = 0;i < _initialLiquidities.length; i++) {
        _initialLiquidity = _initialLiquidity.add(_initialLiquidities[i]);
      }
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
      for(uint i = 1;i <= _totalOptions; i++) {
        if(_initialLiquidities[i-1] > 0) {
          _provideLiquidity(_marketId, _msgSenderAddress, _predictionToken, _initialLiquidities[i-1], i);
        }
      }
    }

}