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
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IAllMarkets.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IAuth.sol";

contract SwapAndPredictWithPlot is NativeMetaTransaction, IAuth {

    using SafeMath for uint;

    event SwapAndPredictFor(address predictFor, uint marketId, address swapFromToken, address swapToToken, uint inputAmount, uint outputAmount);
    
    IAllMarkets allPlotMarkets;
    IToken predictionToken;
    IUniswapV2Router router;

    address public nativeCurrencyAddress;
    address public defaultAuthorized;

    /**
     * @dev Changes the master address and update it's instance
     * @param _authorizedMultiSig Authorized address to execute critical functions in the protocol.
     * @param _defaultAuthorizedAddress Authorized address to trigger initial functions by passing required external values.
     */
    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner());
      authorized = _authorizedMultiSig;
      defaultAuthorized = _defaultAuthorizedAddress;
      _initializeEIP712("SP");
    }

    /**
     * @dev Initiate the contract with required addresses
     * @param _allPlotMarkets AllPlotMarkets contract address
     * @param _predictionToken Address of token used for placing predictions
     * @param _router Router address of exchange to be used for swap transactions
     * @param _nativeCurrencyAddress Wrapped token address of Native currency of network/chain
     */
    function initiate(address _allPlotMarkets, address _predictionToken, address _router, address _nativeCurrencyAddress) external {
      require(msg.sender == defaultAuthorized);
      allPlotMarkets = IAllMarkets(_allPlotMarkets);
      predictionToken = IToken(_predictionToken);
      router = IUniswapV2Router(_router);
      nativeCurrencyAddress = _nativeCurrencyAddress;
    }

    /**
    * @dev Swap any allowed token to prediction token and then place prediction
    * @param _path Order path for swap transaction
    * @param _inputAmount Input amount for swap transaction
    * @param _predictFor Address of user on whose behalf the prediction should be placed
    * @param _marketId Index of the market to place prediction
    * @param _prediction Option in the market to place prediction
    * @param _bPLOTPredictionAmount Bplot amount of `_predictFor` user to be used for prediction
    */
    function swapAndPlacePrediction(address[] calldata _path, uint _inputAmount, address _predictFor, uint _marketId, uint _prediction, uint64 _bPLOTPredictionAmount) external payable {
      uint deadline = now*2;
      uint amountOutMin = 1;
      require(_path[_path.length-1] == address(predictionToken));
      if(_bPLOTPredictionAmount > 0) {
        // bPLOT can not be used if another user is placing proxy prediction
        require(_msgSender() == _predictFor);
      }
      bool _isNativeToken = (_path[0] == nativeCurrencyAddress && msg.value >0);
      // uint _initialFromTokenBalance = getTokenBalance(_path[0], _isNativeToken);
      // uint _initialToTokenBalance = getTokenBalance(_path[_path.length-1], false);
      uint[] memory _output; 
      if(_isNativeToken) {
        require(_inputAmount == msg.value);
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
      uint _tokenDeposit = _output[_output.length - 1];
      emit SwapAndPredictFor(_predictFor, _marketId, _path[0], address(predictionToken), _inputAmount, _output[1]);
      predictionToken.approve(address(allPlotMarkets), _tokenDeposit);
      allPlotMarkets.depositAndPredictFor(_predictFor, _tokenDeposit, _marketId, address(predictionToken), _prediction, uint64(_tokenDeposit.div(10**10)), _bPLOTPredictionAmount);
      // require(_initialFromTokenBalance == getTokenBalance(_path[0], _isNativeToken));
      // require(_initialToTokenBalance == getTokenBalance(_path[_path.length-1], false));
    }

    /**
    * @dev Get contract balance of the given token
    * @param _token Address of token to query balance for 
    * @param _isNativeCurrency Falg defining if the balance needed to be fetched for native currency of the network/chain
    */
    function getTokenBalance(address _token, bool _isNativeCurrency) public returns(uint) {
      if(_isNativeCurrency) {
        return ((address(this)).balance);
      }
      return IToken(_token).balanceOf(address(this));
    }

    /**
    * @dev Transfer any left over token in contract to given address
    * @param _token Address of token to transfer 
    * @param _recipient Address of token recipient
    */
    function transferLeftOverTokens(address _token, address _recipient) external onlyAuthorized {
      require(_token != address(0));
      IToken(_token).transfer(_recipient, getTokenBalance(_token, false));
    }
}
