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

  event PriceUpdated(uint256 price, uint256 updatedOn);

  address public authorizedAddres;
  address public multiSigWallet;
  string public currencyName;

  struct FeedData {
    uint128 price;
    uint128 postedOn;
  }

  mapping(uint256 => uint256) public settlementPrice; // Settlement time to price

  FeedData internal feedData;

  modifier OnlyAuthorized() {
    require(msg.sender == authorizedAddres);
    _;
  }

  /**
  * @param _authorized Authorized address to post prices 
  */
  function initiate(address _authorized, address _multiSigWallet, string memory _currencyName) public {
    require(authorizedAddres == address(0));
    require(_authorized != address(0));
    require(_multiSigWallet != address(0));
    authorizedAddres = _authorized;
    multiSigWallet = _multiSigWallet;
    currencyName = _currencyName;
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
  function postPrice(uint128 _price) external OnlyAuthorized {
    require(_price != 0);
    feedData = FeedData(_price, uint128(now));
    // emit PriceUpdated(_price, now);
  }

  /**
  * @dev Post the settlement price of currency
  */
  function postSettlementPrice(uint256 _marketSettleTime, uint256 _price) external {
    require(msg.sender == multiSigWallet);
    require(_marketSettleTime > 0 && _price > 0, "Invalid arguments");
    require(now >= _marketSettleTime);
    settlementPrice[_marketSettleTime] = _price;
    emit PriceUpdated(_price, _marketSettleTime);
  }

  /**
  * @dev Get price of the asset at given time and nearest roundId
  */
  function getSettlementPrice(uint256 _marketSettleTime, uint80 _roundId) external view returns(uint256 _value, uint256 roundId) {
    require(settlementPrice[_marketSettleTime] > 0, "Price not yet posted for settlement");
    return (settlementPrice[_marketSettleTime], 0);
  }

  /**
  * @dev Get the latest price of currency
  */
  function getLatestPrice() external view returns(uint256 _value) {
    return feedData.price;
  }

  /**
  * @dev Get the latest round data
  */
  function getLatestRoundData() external view returns(uint256 _postedOn, uint256 _price) {
    // _roundId = feedData.length - 1;
    return (feedData.postedOn, feedData.price);
  }

}