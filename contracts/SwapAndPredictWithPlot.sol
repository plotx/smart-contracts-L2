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
import "./interfaces/IMaster.sol";

contract SwapAndPredictWithPlot is NativeMetaTransaction, IAuth {

    using SafeMath for uint;

    event SwapAndPredictFor(address predictFor, uint marketId, address swapFromToken, address swapToToken, uint inputAmount, uint outputAmount);
    
    IAllMarkets internal allPlotMarkets;
    IUniswapV2Router internal router;
    address internal predictionToken;
    IMaster internal master;

    address public nativeCurrencyAddress;
    address public defaultAuthorized;
    uint internal decimalDivider;

    modifier holdNoFunds(address[] memory _path) {
      bool _isNativeToken = (_path[0] == nativeCurrencyAddress && msg.value >0);
      uint _initialFromTokenBalance = getTokenBalance(_path[0], _isNativeToken);
      uint _initialToTokenBalance = getTokenBalance(_path[_path.length-1], false);
      _;  
      require(_initialFromTokenBalance.sub(msg.value) == getTokenBalance(_path[0], _isNativeToken));
      require(_initialToTokenBalance == getTokenBalance(_path[_path.length-1], false));
    }

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
      master = IMaster(msg.sender);
      _initializeEIP712("SP");
    }

    /**
     * @dev Initiate the contract with required addresses
     * @param _router Router address of exchange to be used for swap transactions
     * @param _nativeCurrencyAddress Wrapped token address of Native currency of network/chain
     */
    function initiate(address _router, address _nativeCurrencyAddress) external {
      require(msg.sender == defaultAuthorized);
      require(_router != address(0));
      require(_nativeCurrencyAddress != address(0));
      require(predictionToken == address(0));// Already Initialized
      allPlotMarkets = IAllMarkets(master.getLatestAddress("AM"));
      predictionToken = master.dAppToken();
      router = IUniswapV2Router(_router);
      nativeCurrencyAddress = _nativeCurrencyAddress;
      //Prediction decimals are 10^8, so to convert standard decimal count to prediction supported decimals
      decimalDivider = 10**10;
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
    function swapAndPlacePrediction(
      address[] memory _path,
      uint _inputAmount,
      address _predictFor,
      uint _marketId,
      uint _prediction,
      uint64 _bPLOTPredictionAmount,
      uint _minOutput
    ) public payable
      // Contract should not hold any of input/output tokens provided in transaction
      holdNoFunds(_path)
    {
      if(_bPLOTPredictionAmount > 0) {
        // bPLOT can not be used if another user is placing proxy prediction
        require(_msgSender() == _predictFor);
      }

      _swapAndPlacePrediction(_path, _inputAmount, _minOutput, _predictFor, _marketId, _prediction, _bPLOTPredictionAmount);
    }

    /**
    * @dev Internal function to swap given user tokens to desired preditcion token and place prediction
    * @param _path Order path to follow for swap transaction
    * @param _inputAmount Amount of tokens to swap from. In Wei
    * @param _minOutput Minimum output amount expected in swap
    */
    function _swapAndPlacePrediction(address[] memory _path, uint256 _inputAmount, uint _minOutput, address _predictFor, uint _marketId, uint _prediction, uint64 _bPLOTPredictionAmount) internal {
      address payable _msgSenderAddress = _msgSender();
      uint[] memory _output; 
      uint deadline = now*2;
      require(_path[_path.length-1] == predictionToken);
      if((_path[0] == nativeCurrencyAddress && msg.value >0)) {
        require(_inputAmount == msg.value);
        _output = router.swapExactETHForTokens.value(msg.value)(
          _minOutput,
          _path,
          address(this),
          deadline
        );
      } else {
        require(msg.value == 0);
        _transferTokenFrom(_path[0], _msgSenderAddress, address(this), _inputAmount);
        _provideApproval(_path[0], address(router), _inputAmount);
        _output = router.swapExactTokensForTokens(
          _inputAmount,
          _minOutput,
          _path,
          address(this),
          deadline
        );
      }
      require(_output[_output.length - 1] >= _minOutput);
      // return _output[_output.length - 1];
      _placePrediction(_predictFor, _path[0], _output[_output.length - 1], _marketId, _prediction, _inputAmount, _bPLOTPredictionAmount);
    }

    /**
    * @dev Internal function to place prediction in given market
    */
    function _placePrediction(address _predictFor, address _swapFrom, uint _tokenDeposit, uint _marketId, uint _prediction, uint _inputAmount, uint64 _bPLOTPredictionAmount) internal {
      _provideApproval(predictionToken, address(allPlotMarkets), _tokenDeposit);
      allPlotMarkets.depositAndPredictFor(_predictFor, _tokenDeposit, _marketId, predictionToken, _prediction, uint64(_tokenDeposit.div(decimalDivider)), _bPLOTPredictionAmount);
      emit SwapAndPredictFor(_predictFor, _marketId, _swapFrom, predictionToken, _inputAmount, _tokenDeposit);
    }

    /**
    * @dev Internal function to provide approval to external address from this contract
    * @param _tokenAddress Address of the ERC20 token
    * @param _spender Address, indented to spend the tokens
    * @param _amount Amount of tokens to provide approval for. In Wei
    */
    function _provideApproval(address _tokenAddress, address _spender, uint256 _amount) internal {
        IToken(_tokenAddress).approve(_spender, _amount);
    }

    /**
    * @dev Internal function to call transferFrom function of a given token
    * @param _token Address of the ERC20 token
    * @param _from Address from which the tokens are to be received
    * @param _to Address to which the tokens are to be transferred
    * @param _amount Amount of tokens to transfer. In Wei
    */
    function _transferTokenFrom(address _token, address _from, address _to, uint256 _amount) internal {
      require(IToken(_token).transferFrom(_from, _to, _amount));
    }

    /**
    * @dev Get contract balance of the given token
    * @param _token Address of token to query balance for 
    * @param _isNativeCurrency Falg defining if the balance needed to be fetched for native currency of the network/chain
    */
    function getTokenBalance(address _token, bool _isNativeCurrency) public view returns(uint) {
      if(_isNativeCurrency) {
        return ((address(this)).balance);
      }
      return IToken(_token).balanceOf(address(this));
    }

}
