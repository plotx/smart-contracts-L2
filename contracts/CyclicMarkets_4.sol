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
    mapping(uint256 => mapping(uint256 => uint64)) public mcPairInitialLiquidity;//MarketType => Market Currency => Initial Liquidity

    /**
     * @dev Changes the master address and update it's instance
     * @param _authorizedMultiSig Authorized address to execute critical functions in the protocol.
     * @param _defaultAuthorizedAddress Authorized address to trigger initial functions by passing required external values.
     */
    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
      revert(); // Contract already initiated so this function is not required anymore
    }

    /**
    * @dev Set the initial liquidity for market type and currency pair
    * @param _marketType Market type index
    * @param _marketCurrency Market currency index
    * @param _initialLiquidity Initial liquidity of the market **with 8 decimals**
     */
    function setMCPairInitialLiquidity(uint _marketType, uint _marketCurrency, uint64 _initialLiquidity) external onlyAuthorized {
      mcPairInitialLiquidity[_marketType][_marketCurrency] = _initialLiquidity;
    }

    function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public {
      initialPredictionFlag = true;
      address _msgSenderAddress = _msgSender();
      require(isAuthorizedCreator[_msgSenderAddress]);
      MarketTypeData storage _marketType = marketTypeArray[_marketTypeIndex];
      MarketCurrency storage _marketCurrency = marketCurrencies[_marketCurrencyIndex];
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      require(!_marketType.paused && !_marketCreationData.paused);
      uint32 _startTime = _checkPreviousMarketAndGetStartTime( _marketTypeIndex, _marketCurrencyIndex, _marketType.predictionTime);
      // uint32 _startTime = calculateStartTimeForMarket(_marketCurrencyIndex, _marketTypeIndex);
      uint32[] memory _marketTimes = new uint32[](4);
      uint _optionLength = marketTypeOptionPricing[_marketTypeIndex];
      uint64[] memory _optionRanges = new uint64[](_optionLength);
      uint64 _marketIndex = allMarkets.getTotalMarketsLength();
      marketOptionPricing[_marketIndex] = optionPricingContracts[_optionLength];
      _optionRanges = _calculateOptionRanges(marketOptionPricing[_marketIndex], _marketType.optionRangePerc, _marketCurrency.decimals, _marketCurrency.roundOfToNearest, _marketCurrency.marketFeed);
      _marketTimes[0] = _startTime; 
      _marketTimes[1] = _marketType.predictionTime;
      _marketTimes[2] = marketTypeSettlementTime[_marketTypeIndex];
      _marketTimes[3] = _marketType.cooldownTime;
      marketPricingData[_marketIndex] = PricingData(stakingFactorMinStake, stakingFactorWeightage, currentPriceWeightage, _marketType.minTimePassed);
      marketData[_marketIndex] = MarketData(_marketTypeIndex, _marketCurrencyIndex, _msgSenderAddress);
      uint64 _initialLiquidity = mcPairInitialLiquidity[_marketTypeIndex][_marketCurrencyIndex];
      if(_initialLiquidity == 0) {
        _initialLiquidity =  _marketType.initialLiquidity;
      }
      allMarkets.createMarket(_marketTimes, _optionRanges, _msgSenderAddress, _initialLiquidity);

      _updateMarketIndexesAndEmitEvent(_marketTypeIndex, _marketCurrencyIndex, _marketIndex, _msgSenderAddress, _marketCurrency.currencyName, _marketType.minTimePassed);

      initialPredictionFlag = false;
    }

    function _updateMarketIndexesAndEmitEvent(uint _marketTypeIndex, uint _marketCurrencyIndex, uint64 _marketIndex, address _msgSenderAddress, bytes32 _currencyName, uint32 _minTimePassed) internal {
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      (_marketCreationData.penultimateMarket, _marketCreationData.latestMarket) =
       (_marketCreationData.latestMarket, _marketIndex);
     emit MarketParams(_marketIndex, _msgSenderAddress, _marketTypeIndex, _currencyName, stakingFactorMinStake,stakingFactorWeightage,currentPriceWeightage,_minTimePassed);
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
