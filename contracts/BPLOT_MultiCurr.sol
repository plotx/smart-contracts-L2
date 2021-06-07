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

import "./bPLOTToken.sol";


contract BPLOT_MultiCurr is BPLOT {

  mapping(address => bool) allowedAuth;

  /**
     * @dev Checks if msg.sender is address to convert bPLOT to PLOT.
     */
    modifier onlyAuthorizedToConvert() {
        require(allowedAuth[msg.sender], "Only authorized");
        _;
    }

    function addAuthorised(address _add) public {
      require(ms.initialAuthorizedAddress() == msg.sender);
      allowedAuth[_add] = true;
    }

    function removeAuthorised(address _add) public {
      require(ms.initialAuthorizedAddress() == msg.sender);
      allowedAuth[_add] = false;
    }

}