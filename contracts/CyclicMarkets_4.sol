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

import "./CyclicMarkets_3.sol";

contract CyclicMarkets_4 is CyclicMarkets_3 {

    bool internal initialPredictionFlag;

    function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public {
        initialPredictionFlag = true;
        CyclicMarkets_3.createMarket(_marketCurrencyIndex, _marketTypeIndex, _roundId);
        initialPredictionFlag = false;
    }
    /**
    * @dev Internal function to calculate prediction points
    * @param _marketId Index of the market
    * @param _prediction Option predicted by the user
    * @param _user User Address
    * @param _multiplierApplied Flag defining if user had already availed multiplier
    * @param _predictionStake Amount staked by the user
    */
    function calculatePredictionPoints(uint _marketId, uint256 _prediction, address _user, bool _multiplierApplied, uint _predictionStake) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
      (predictionPoints, isMultiplierApplied) = _calculatePredictionPoints(_marketId, _prediction, _user, _multiplierApplied, _predictionStake);
    	uint _marketType = marketData[_marketId].marketTypeIndex;
      EarlyParticipantMultiplier memory _multiplierData = earlyParticipantMultiplier[_marketType];
      (, uint _startTime) = allMarkets.getMarketOptionPricingParams(_marketId, _prediction);
      uint _timePassed;
      // If given market is buffer market, then the time passed should be zero, as start time will not be reached 
      if(_startTime < now) {
        _timePassed = uint(now).sub(_startTime);
      }
      if(_timePassed <= _multiplierData.cutoffTime) {
        uint64 _muliplier = 100;
        _muliplier = _muliplier.add(_multiplierData.multiplierPerc);
        predictionPoints = (predictionPoints.mul(_muliplier).div(100));
      }
    }

    /**
    * @dev Internal function to calculate prediction points
    * @param _marketId Index of the market
    * @param _prediction Option predicted by the user
    * @param _user User Address
    * @param _multiplierApplied Flag defining if user had already availed multiplier
    * @param _predictionStake Amount staked by the user
    */
    function _calculatePredictionPoints(uint _marketId, uint256 _prediction, address _user, bool _multiplierApplied, uint _predictionStake) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
      uint _stakeValue = _predictionStake.mul(1e10);
      if(_stakeValue < minPredictionAmount || _stakeValue > maxPredictionAmount) {
        return (0, isMultiplierApplied);
      }
      uint64 _optionPrice = getOptionPrice(_marketId, _prediction);
      predictionPoints = uint64(_predictionStake).div(_optionPrice);
      if(!_multiplierApplied || (initialPredictionFlag)) {
        uint256 _predictionPoints = predictionPoints;
        if(address(userLevels) != address(0)) {
          (_predictionPoints, isMultiplierApplied) = checkMultiplier(_user,  predictionPoints);
        }
        predictionPoints = uint64(_predictionPoints);
      }
    }


}
