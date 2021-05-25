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
import "./interfaces/ISwapRouter.sol";

contract ProxyPlotPrediction is NativeMetaTransaction {

    using SafeMath for uint;

    IAllMarkets allPlotMarkets;
    IToken plotToken;
    IUniswapV2Router router;

    address public maticAddress;

    function initiate(address _allPlotMarkets, address _plotToken, address _router, address _maticAddress) external {
      allPlotMarkets = IAllMarkets(_allPlotMarkets);
      plotToken = IToken(_plotToken);
      router = IUniswapV2Router(_router);
      maticAddress = _maticAddress;
    }

    function swapAndPlacePrediction(address[] calldata _path, uint _inputAmount, address _predictFor, uint _marketId, uint _prediction, uint64 _bPLOTPredictionAmount) external payable {
      uint deadline = now*2;
      uint amountOutMin = 1;
      require(_path[_path.length-1] == address(plotToken));
      bool _isNativeToken = (_path[0] == maticAddress && msg.value >0);
      // uint _initialFromTokenBalance = getTokenBalance(_path[0], _isNativeToken);
      // uint _initialToTokenBalance = getTokenBalance(_path[_path.length-1], false);
      uint[] memory _output; 
      if(_isNativeToken) {
        _output = router.swapExactETHForTokens.value(msg.value)(
          amountOutMin,
          _path,
          address(this),
          deadline
        );
      } else {
        require(msg.value == 0);
        address payable _msgSenderAddress = _msgSender();
        IToken(_path[0]).transferFrom(_msgSenderAddress, address(this), _inputAmount);
        IToken(_path[0]).approve(address(router), _inputAmount);
        _output = router.swapExactTokensForTokens(
          _inputAmount,
          amountOutMin,
          _path,
          address(this),
          deadline
        );
      }
      uint _tokenDeposit = _output[1];
      plotToken.approve(address(allPlotMarkets), _inputAmount);
      allPlotMarkets.depositAndPredictFor(_predictFor, _tokenDeposit, _marketId, address(plotToken), _prediction, uint64(_tokenDeposit.div(10**10)), _bPLOTPredictionAmount);
      // require(_initialFromTokenBalance == getTokenBalance(_path[0], _isNativeToken));
      // require(_initialToTokenBalance == getTokenBalance(_path[_path.length-1], false));
    }

    function getTokenBalance(address _token, bool _isNativeCurrency) public returns(uint) {
      if(_isNativeCurrency) {
        return ((address(this)).balance);
      }
      return IToken(_token).balanceOf(address(this));
    }

    function transferLeftOverTokens(address _token) external {
      IToken(_token).transfer(msg.sender, getTokenBalance(_token, false));
    }
}
