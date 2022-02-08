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

import "./CyclicMarkets_4.sol";

contract CyclicMarkets_5 is CyclicMarkets_4 {

  function updateCurrencyPriceFeed(uint32 _currencyIndex, address _marketFeed) public onlyAuthorized {
      require(_marketFeed != address(0));
      require(_currencyIndex<marketCurrencies.length);
      marketCurrencies[_currencyIndex].marketFeed = _marketFeed;
      emit MarketCurrencies(_currencyIndex, _marketFeed, marketCurrencies[_currencyIndex].currencyName, true);
  }

}
