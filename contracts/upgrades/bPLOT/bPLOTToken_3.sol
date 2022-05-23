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

import "./bPLOTToken_2.sol";

contract BPLOT_3 is BPLOT_2 {

    mapping(address => bool) public allowedToConvert;

    /**
     * @dev Checks if msg.sender is address to convert bPLOT to PLOT.
     */
    modifier onlyAuthorizedToConvert() {
        require(allowedToConvert[msg.sender], "Only authorized");
        _;
    }

    function whiteListAuthToconvert(address _add) public onlyAuthorized {
        allowedToConvert[_add]=true;
    }

    function dewhiteListAuthToconvert(address _add) public onlyAuthorized {
        allowedToConvert[_add]=false;
    }
}
