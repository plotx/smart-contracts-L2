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

import "./CyclicMarkets_5.sol";

contract CyclicMarkets_6 is CyclicMarkets_5 {

  function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public {
      revert("DEPR");
  }

  function createMarketWithOptionRanges(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint64[] calldata _optionRanges) external {
      initialPredictionFlag = true;
      address _msgSenderAddress = _msgSender();
      require(isAuthorizedCreator[_msgSenderAddress]);
      MarketTypeData storage _marketType = marketTypeArray[_marketTypeIndex];
      MarketCurrency storage _marketCurrency = marketCurrencies[_marketCurrencyIndex];
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      require(!_marketType.paused && !_marketCreationData.paused);
      uint32 _startTime = _checkPreviousMarketAndGetStartTime( _marketTypeIndex, _marketCurrencyIndex, _marketType.predictionTime);
      uint32[] memory _marketTimes = new uint32[](4);
      uint64 _marketIndex = allMarkets.getTotalMarketsLength();
      uint _optionLength = marketTypeOptionPricing[_marketTypeIndex];
      marketOptionPricing[_marketIndex] = optionPricingContracts[_optionLength];
    //   _optionRanges = _calculateOptionRanges(marketOptionPricing[_marketIndex], _marketType.optionRangePerc, _marketCurrency.decimals, _marketCurrency.roundOfToNearest, _marketCurrency.marketFeed);
      _marketTimes[0] = _startTime; 
      _marketTimes[1] = _marketType.predictionTime;
      _marketTimes[2] = marketTypeSettlementTime[_marketTypeIndex];
      _marketTimes[3] = _marketType.cooldownTime;
      // marketPricingData[_marketIndex] = PricingData(stakingFactorMinStake, stakingFactorWeightage, currentPriceWeightage, _marketType.minTimePassed);
      marketData[_marketIndex] = MarketData(_marketTypeIndex, _marketCurrencyIndex, _msgSenderAddress);
      uint64 _initialLiquidity = mcPairInitialLiquidity[_marketTypeIndex][_marketCurrencyIndex];
      if(_initialLiquidity == 0) {
        _initialLiquidity =  _marketType.initialLiquidity;
      }
      allMarkets.createMarket(_marketTimes, _optionRanges, _msgSenderAddress, _initialLiquidity);

      _updateMarketIndexesAndEmitEvent(_marketTypeIndex, _marketCurrencyIndex, _marketIndex, _msgSenderAddress, _marketCurrency.currencyName, _marketType.minTimePassed);

      initialPredictionFlag = false;
  }

  function _calculateOptionRange(uint _optionRangePerc, uint64 _decimals, uint8 _roundOfToNearest, address _marketFeed) internal view returns(uint64[] memory _optionRanges) {
    revert("DEPR");
  }

  function _calculateOptionRanges(address _optionPricingContract, uint _optionRangePerc, uint64 _decimals, uint8 _roundOfToNearest, address _marketFeed) internal view returns(uint64[] memory _optionRanges) {
    revert("DEPR");
  }

  function _updateMarketIndexesAndEmitEvent(uint _marketTypeIndex, uint _marketCurrencyIndex, uint64 _marketIndex, address _msgSenderAddress, bytes32 _currencyName, uint32 _minTimePassed) internal {
    MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
    (_marketCreationData.penultimateMarket, _marketCreationData.latestMarket) =
      (_marketCreationData.latestMarket, _marketIndex);
    emit MarketParams(_marketIndex, _msgSenderAddress, _marketTypeIndex, _currencyName, 0,0,0,0);
  }

  /**
  * @dev Gets price for given market and option
  * @param _marketId  Market ID
  * @param _prediction  prediction option
  * @return  option price
  **/
  function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64) {
    revert("DEPR");
  }
  
  function getAllOptionPrices(uint _marketId) external view returns(uint64[] memory _optionPrices) {
    revert("DEPR");
  }
  /**
  * @dev Gets price for given market and option
  * @param _marketId  Market ID
  * @param _prediction  prediction option
  * @return  option price
  **/
  function getOptionPriceWithStake(uint _marketId, uint256 _prediction, uint _predictionAmount) public view returns(uint64) {
    //For the markets which are created before the upgrade
    // if(marketOptionPricing[_marketId] == address(0)) {
    //   return super.getOptionPrice(_marketId, _prediction);
    // }

    uint _marketCurr = marketData[_marketId].marketCurrencyIndex;

    uint[] memory _marketPricingDataArray = new uint[](5);
    PricingData storage _marketPricingData = marketPricingData[_marketId];
    _marketPricingDataArray[0] = _marketPricingData.stakingFactorMinStake;
    _marketPricingDataArray[1] = _marketPricingData.stakingFactorWeightage;
    _marketPricingDataArray[2] = _marketPricingData.currentPriceWeightage;
    _marketPricingDataArray[3] = _marketPricingData.minTimePassed;
    _marketPricingDataArray[4] = _predictionAmount;

    // Fetching current price
    uint currentPrice = IOracle(marketCurrencies[_marketCurr].marketFeed).getLatestPrice();

    return IOptionPricing(marketOptionPricing[_marketId]).getOptionPrice(_marketId, currentPrice, _prediction, _marketPricingDataArray, address(allMarkets));

  }

  /**
  * @dev Gets price for all the options in a market
  * @param _marketId  Market ID
  * @return _optionPrices array consisting of prices for all available options
  **/
  function getAllOptionPricesWithStake(uint _marketId, uint defaultPredictionAmount) external view returns(uint[] memory _optionPrices) {
    uint _optionLength;
    if(marketOptionPricing[_marketId] != address(0)) {
      _optionLength = IOptionPricing(marketOptionPricing[_marketId]).optionLength();
    } else {
      _optionLength = 3;
    }
    _optionPrices = new uint[](_optionLength);
    for(uint i=0; i< _optionLength; i++) {
      _optionPrices[i] = getOptionPriceWithStake(_marketId,i+1, defaultPredictionAmount);
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
    uint64 _optionPrice = getOptionPriceWithStake(_marketId, _prediction, _predictionStake);
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