/* Copyright (C) 2020 PlotX.io

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

import "./AcyclicMarkets.sol";

contract AcyclicMarkets_2 is AcyclicMarkets {

    /**
    * @dev Create the market.
    */
    function createMarketWithVariableLiquidity(string memory _questionDetails, uint64[] memory _optionRanges, uint32[] memory _marketTimes,bytes8 _marketType, bytes32 _marketCurr, uint64[] memory _marketInitialLiquidities) public {
      require(!paused);
      address _marketCreator = _msgSender();
      require(whiteListedMarketCreators[_marketCreator] || oneTimeMarketCreator[_marketCreator]);
      delete oneTimeMarketCreator[_marketCreator];
    //   require(_marketInitialLiquidities >= minLiquidityByCreator);
      uint32[] memory _timesArray = new uint32[](_marketTimes.length+1);
      _timesArray[0] = uint32(now);
      _timesArray[1] = _marketTimes[0].sub(uint32(now));
      _timesArray[2] = _marketTimes[1].sub(uint32(now));
      _timesArray[3] = _marketTimes[2];
      uint64 _marketId = allMarkets.getTotalMarketsLength();
      marketData[_marketId].pricingData = PricingData(stakingFactorMinStake, stakingFactorWeightage, timeWeightage, minTimePassed);
      marketData[_marketId].marketCreator = _marketCreator;
      allMarkets.createMarketWithVariableLiquidity(_timesArray, _optionRanges, _marketCreator, _marketInitialLiquidities);

      emit MarketParams(_marketId, _questionDetails, _optionRanges,_marketTimes, stakingFactorMinStake, minTimePassed, _marketCreator, _marketType, _marketCurr);
    }

}
