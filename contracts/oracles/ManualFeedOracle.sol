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

  FeedData[] internal feedData;

  modifier OnlyAuthorized() {
    require(msg.sender == authorizedAddres);
    _;
  }

  constructor(address _authorized) public {
    authorizedAddres = _authorized;
  }

  function changeAuthorizedAddress(address _newAuth) external OnlyAuthorized {
    authorizedAddres = _newAuth;
  }

  function postPrice(uint256 _price) external OnlyAuthorized {
    feedData.push(FeedData(_price, now));
    emit PriceUpdated(feedData.length - 1, _price, now);
  }

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

  function getLatestPrice() external view returns(uint256 _value) {
    return feedData[feedData.length - 1].price;
  }

}