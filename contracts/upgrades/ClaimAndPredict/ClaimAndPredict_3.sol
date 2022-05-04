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
pragma experimental ABIEncoderV2;

import "./ClaimAndPredict_2.sol";

contract ClaimAndPredict_3 is ClaimAndPredict_2 {

  /**
  * @dev Function to preform claim operation and 
  */
  function mintbPLOT(
    uint _amount
  )
    external
  {
    require(authorized == _msgSender());
    require(IToken(predictionToken).approve(bPLOTToken, _amount);
    require(IToken(bPLOTToken).mint(address(this), _amount));
  }

}
