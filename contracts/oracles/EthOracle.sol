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

import "../interfaces/IOracle.sol";
import "../interfaces/IChainLinkOracle.sol";

contract EthChainlinkOracle is IOracle {

  IChainLinkOracle internal aggregator;

  /**
  * @param _aggregator Chainlink aggregator address to fetch the price from 
  */
  constructor(address _aggregator) public {
    aggregator = IChainLinkOracle(_aggregator);
  }

  /**
  * @dev Get price of the asset at given time and nearest roundId
  */
  function getSettlementPrice(uint256 _marketSettleTime, uint80 _roundId) external view returns(uint256 _value, uint256 roundId) {
    uint80 roundIdToCheck;
    uint256 currentRoundTime;
    int256 currentRoundAnswer;
    (roundIdToCheck, currentRoundAnswer, , currentRoundTime, )= aggregator.latestRoundData();
    if(roundIdToCheck == _roundId) {
      if(currentRoundTime <= _marketSettleTime) {
        return (uint256(currentRoundAnswer), roundIdToCheck);
      }
    } else {
      (roundIdToCheck, currentRoundAnswer, , currentRoundTime, )= aggregator.getRoundData(_roundId + 1);
      require(currentRoundTime > _marketSettleTime);
      roundIdToCheck = _roundId + 1;
    }
    while(currentRoundTime > _marketSettleTime) {
        roundIdToCheck--;
        (roundIdToCheck, currentRoundAnswer, , currentRoundTime, )= aggregator.getRoundData(roundIdToCheck);
    }
    return
        (uint256(currentRoundAnswer), roundIdToCheck);
  }

  /**
  * @dev Get the latest price of currency
  */
  function getLatestPrice() external view returns(uint256 _value) {
    return uint256(aggregator.latestAnswer());
  }

}