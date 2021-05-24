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

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IAllMarkets.sol";
import "./interfaces/IToken.sol";

contract ProxyPlotPrediction is NativeMetaTransaction {

    using SafeMath for uint;

    IAllMarkets allPlotMarkets;
    IToken plotToken;
    function swapAndPlacePrediction(address[] calldata _path, uint _inputAmount, address _predictFor, uint _marketId, uint _prediction, uint64 _bPLOTPredictionAmount) external {
      address payable _msgSenderAddress = _msgSender();
      uint _tokenDeposit = _inputAmount; // Process input amount
      allPlotMarkets.depositAndPredictFor(_predictFor, _tokenDeposit, _marketId, address(plotToken), _prediction, uint64(_tokenDeposit.div(10**10)), _bPLOTPredictionAmount);
    }
}