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

import "./AllPlotMarkets_6.sol";

contract IMarketCreator {
  struct MarketData {
      uint64 marketTypeIndex;
      uint64 marketCurrencyIndex;
      address marketCreator;
    }

  mapping(uint256 => MarketData) public marketData;
  function getMarketCreator(uint _marketId) public view returns(address);

}

contract AllPlotMarkets_7 is AllPlotMarkets_6 {


  mapping(uint => uint) internal totalPredictions;
  mapping(uint =>mapping(uint => uint)) internal totalPredictionsOnOption;


  function getMarketParams(uint _marketId) public view returns(bool,uint32,uint,uint32,uint,uint,PredictionStatus) {
    // IMaster ms = IMaster(masterAddress);
    address creatorContract = marketDataExtended[_marketId].marketCreatorContract;
    require(creatorContract != address(0), "Invalid marketId");
   
    return (creatorContract == IMaster(masterAddress).getLatestAddress("CM"),marketBasicData[_marketId].startTime, marketExpireTime(_marketId), marketSettleTime(_marketId),totalPredictions[_marketId],marketDataExtended[_marketId].totalStaked,marketStatus(_marketId));
  }

  function getOptionSpecificData(uint _marketId) public view returns(uint[] memory plotStaked,uint64[] memory optionRanges,uint64[] memory optionPrices,uint,uint,uint,uint[] memory predictionOnOption) {

    plotStaked = new uint[](marketDataExtended[_marketId].optionRanges.length +1);
    predictionOnOption = new uint[](marketDataExtended[_marketId].optionRanges.length +1);
    for (uint i = 0; i < marketDataExtended[_marketId].optionRanges.length +1; i++) {
      plotStaked[i] = marketOptionsAvailable[_marketId][i+1].amountStaked;
      predictionOnOption[i] = totalPredictionsOnOption[_marketId][i+1];
    }
   address creatorContract = marketDataExtended[_marketId].marketCreatorContract;  
    
   return  (plotStaked, marketDataExtended[_marketId].optionRanges, IMarket(creatorContract).getAllOptionPrices(_marketId),marketDataExtended[_marketId].WinningOption,getTotalPredictionPoints(_marketId), marketDataExtended[_marketId].rewardToDistribute,predictionOnOption);

  }

  function getMarketDataExtended(uint _marketId, address _user) public view returns(address marketCreator,bool,uint64 assetType) {
    address creatorContract = marketDataExtended[_marketId].marketCreatorContract;
    IMarketCreator market = IMarketCreator(creatorContract);
    if(creatorContract == IMaster(masterAddress).getLatestAddress("CM")) {

        (,assetType,marketCreator) = market.marketData(_marketId);


      } else {
        marketCreator = market.getMarketCreator(_marketId);
      }
      bool isPredicted;
      if(_user != address(0))
      {
        isPredicted = _hasUserParticipated(_marketId,_user);
      }
      return (marketCreator,isPredicted,assetType);
  }

  function _storePredictionData(uint _marketId, uint _prediction, address _msgSenderAddress, uint64 _predictionStake, uint64 predictionPoints) internal {
      totalPredictions[_marketId] = totalPredictions[_marketId].add(1);
      totalPredictionsOnOption[_marketId][_prediction] = totalPredictionsOnOption[_marketId][_prediction].add(1);
      super._storePredictionData(_marketId, _prediction, _msgSenderAddress, _predictionStake, predictionPoints);
      
  }

}
