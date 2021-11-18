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

import "./AcyclicMarkets_2.sol";

contract AcyclicMarkets_3 is AcyclicMarkets_2 {
  address public authToSettleMarkets; // Authorized address to settlemarkets

  /**
  * @dev Update the authorized address to settle markets
  * @param _newAuth Address to update
  */
  function changeAuthAddressToSettleMarkets(address _newAuth) external onlyAuthorized {
    require(_newAuth != address(0));
    authToSettleMarkets = _newAuth;
  }

  /**
  * @dev Settle the market, setting the winning option
  * @param _marketId Index of market
  */
  function settleMarket(uint256 _marketId, uint _answer) public {
    require(_msgSender() ==  authToSettleMarkets);
    allMarkets.settleMarket(_marketId, _answer);
    if(allMarkets.marketStatus(_marketId) >= IAllMarkets.PredictionStatus.InSettlement) {
      _transferAsset(plotToken, masterAddress, (10**predictionDecimalMultiplier).mul(marketFeeParams.daoFee[_marketId]));
      delete marketFeeParams.daoFee[_marketId];

      marketCreationReward[marketData[_marketId].marketCreator] = marketCreationReward[marketData[_marketId].marketCreator].add((10**predictionDecimalMultiplier).mul(marketFeeParams.marketCreatorFee[_marketId]));
      emit MarketCreatorReward(marketData[_marketId].marketCreator, _marketId, marketFeeParams.marketCreatorFee[_marketId]);
      delete marketFeeParams.marketCreatorFee[_marketId];
    }
  }
}
