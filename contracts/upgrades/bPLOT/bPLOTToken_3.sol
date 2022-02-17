/* Copyright (C) 2022 PlotX.io
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
     
    /**
     * @dev Collect bPLOT amount from the given address
     * Should only be authorized by all markets contract 
     * To be used for collecting bplot from users while predicting
     */
    function collectBPLOT(
        address _of,
        uint256 amount
    ) public onlyAuthorizedToConvert {
        _transfer(_of, authorized, amount);
    }
}
