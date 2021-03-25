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

contract ManualFeedOracle is IOracle {

  event PriceUpdated(uint256 index, uint256 price, uint256 updatedOn);

  address public authorizedAddres;

  struct FeedData {
    uint256 price;
    uint256 postedOn;
  }

  FeedData[] public feedData;

  modifier OnlyAuthorized() {
    require(msg.sender == authorizedAddres);
    _;
  }

  /**
  * @param _authorized Authorized address to post prices 
  */
  constructor(address _authorized) public {
    authorizedAddres = _authorized;
  }

  /**
  * @dev Update authorized address to post price
  */
  function changeAuthorizedAddress(address _newAuth) external OnlyAuthorized {
    require(_newAuth != address(0));
    authorizedAddres = _newAuth;
  }

  /**
  * @dev Post the latest price of currency
  */
  function postPrice(uint256 _price) external OnlyAuthorized {
    feedData.push(FeedData(_price, now));
    emit PriceUpdated(feedData.length - 1, _price, now);
  }

  /**
  * @dev Get price of the asset at given time and nearest roundId
  */
  function getSettlementPrice(uint256 _marketSettleTime, uint80 _roundId) external view returns(uint256 _value, uint256 roundId) {
    uint256 roundIdToCheck = feedData.length - 1;
    uint256 currentRoundTime = feedData[roundIdToCheck].postedOn;
    uint256 currentRoundAnswer = feedData[roundIdToCheck].price;
    
    if(roundIdToCheck == _roundId) {
      if(currentRoundTime <= _marketSettleTime) {
        return (uint256(currentRoundAnswer), roundIdToCheck);
      }
    } else {
      roundIdToCheck = _roundId + 1;
      currentRoundTime = feedData[roundIdToCheck].postedOn;
      currentRoundAnswer = feedData[roundIdToCheck].price;
      require(currentRoundTime > _marketSettleTime);
      roundIdToCheck = _roundId + 1;
    }
    while(currentRoundTime > _marketSettleTime) {
        roundIdToCheck--;
        currentRoundTime = feedData[roundIdToCheck].postedOn;
        currentRoundAnswer = feedData[roundIdToCheck].price;
    }
    return
        (uint256(currentRoundAnswer), roundIdToCheck);
  }

  /**
  * @dev Get the latest price of currency
  */
  function getLatestPrice() external view returns(uint256 _value) {
    return feedData[feedData.length - 1].price;
  }

  /**
  * @dev Get the latest round data
  */
  function getLatestRoundData() external view returns(uint256 _roundId, uint256 _postedOn, uint256 _price) {
    _roundId = feedData.length - 1;
    return (_roundId, feedData[_roundId].postedOn, feedData[_roundId].price);
  }

}