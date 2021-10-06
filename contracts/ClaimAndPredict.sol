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

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IAllMarkets.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IbPLOTToken.sol";
import "./interfaces/IMaster.sol";

contract ClaimAndPredict is NativeMetaTransaction {
    using SafeMath for uint;

    event SwapAndPredictFor(address predictFor, uint marketId, address swapFromToken, address swapToToken, uint inputAmount, uint outputAmount);

    struct MetaTxData {
      address targetAddress;
      address userAddress;
      bytes functionSignature;
      bytes32 sigR;
      bytes32 sigS;
      uint8 sigV;
    }

    struct ClaimData {
      address user;
      uint userClaimNonce;
      uint strategyId;
      uint claimAmount;
      uint totalClaimed;
      uint8 v;
      bytes32 r;
      bytes32 s;
    }

    IUniswapV2Router internal router;
    IAllMarkets internal allPlotMarkets;
    address internal predictionToken;
    address internal bPLOTToken;

    mapping(address => uint) public bonusClaimed;
    mapping(address => uint) public userClaimNonce;

    mapping(address => bool) public allowedTokens;

    mapping(uint => uint) public maxClaimPerStrategy;

    address public nativeCurrencyAddress;
    address public authorized;
    uint internal constant decimalDivider = 1e10;

    modifier onlyAuthorized() {
      require(_msgSender() == authorized);
      _;
    }

    modifier holdNoFunds(address[] memory _path) {
      bool _isNativeToken = (_path[0] == nativeCurrencyAddress && msg.value >0);
      uint _initialFromTokenBalance = getTokenBalance(_path[0], _isNativeToken);
      uint _initialToTokenBalance = getTokenBalance(_path[_path.length-1], false);
      _;  
      require(_initialFromTokenBalance.sub(msg.value) == getTokenBalance(_path[0], _isNativeToken));
      require(_initialToTokenBalance == getTokenBalance(_path[_path.length-1], false));
    }

    constructor(address _masterAddress, address _router, address _nativeCurrencyAddress) public {
      require(_masterAddress != address(0));
      require(_router != address(0));
      require(_nativeCurrencyAddress != address(0));

      IMaster ms = IMaster(_masterAddress);
      authorized = ms.authorized();
      allPlotMarkets = IAllMarkets(ms.getLatestAddress("AM"));
      predictionToken = ms.dAppToken();
      bPLOTToken = ms.getLatestAddress("BL");

      router = IUniswapV2Router(_router);
      nativeCurrencyAddress = _nativeCurrencyAddress;

      _initializeEIP712("CP");
    }

    function changeAuthorizedAddress(address _newAuth) external onlyAuthorized {
      require(_newAuth != address(0));
      authorized = _newAuth;
    }

    function updateMaxClaimPerStrategy(uint[] calldata _strategies, uint[] calldata _maxClaim) external onlyAuthorized {
      for(uint i= 0;i<_strategies.length;i++) {
        maxClaimPerStrategy[_strategies[i]] = _maxClaim[i];
      }
    }

    /**
     * @dev Allow a token to be used for swap and placing prediction
     * @param _token Address of token contract
     */
    function whitelistTokenForSwap(address _token) external onlyAuthorized {
      require(_token != address(0));
      require(!allowedTokens[_token]);
      allowedTokens[_token] = true;
    }

    /**
     * @dev Remove a token from whitelist to be used for swap and placing prediction
     * @param _token Address of token contract
     */
    function deWhitelistTokenForSwap(address _token) external onlyAuthorized {
      require(allowedTokens[_token]);
      allowedTokens[_token] = false;
    }

    /**
     * @dev Withdraw any left tokens in the contract
     * @param _tokenAddress Address of the ERC20 token
     * @param _recipient Address, indented to recieve the tokens
     * @param _amount Amount of tokens to provide approval for. In Wei
     */
    function withdrawToken(address _tokenAddress, address _recipient, uint256 _amount) public 
    onlyAuthorized
    {
      require(IToken(_tokenAddress).transfer(_recipient, _amount));
    }

    /**
    * @dev Renounce this contract as minter
     */
    function renounceAsMinter() public onlyAuthorized {
      IbPLOTToken(bPLOTToken).renounceMinter();
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

    function claimAndPredict(
      ClaimData calldata _claimData,
      MetaTxData calldata _txData
    )
      external
    {
      require(_txData.userAddress == _claimData.user);
      _verifyAndClaim(_claimData);
      //If placePRediction is called plot should be transferred from this contract, not from user 
      //doMetaTx here
      NativeMetaTransaction(_txData.targetAddress).executeMetaTransaction(_claimData.user, _txData.functionSignature, _txData.sigR, _txData.sigS, _txData.sigV);
      
    }

    function claimSwapAndPredict(
      ClaimData calldata _claimData,
      address[] calldata _path,
      uint _inputAmount,
      uint _marketId,
      uint _prediction,
      uint64 _bPLOTPredictionAmount,
      uint _minOutput
    )
      payable
      external
      holdNoFunds(_path)
    {
      _verifyAndClaim(_claimData);

      _swapAndPlacePrediction(_path, _inputAmount, _minOutput, _claimData.user, _marketId, _prediction, _bPLOTPredictionAmount);
      
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
      require(allowedTokens[_path[0]],"Not allowed");
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
      _placePrediction(_predictFor, _output[_output.length - 1], _marketId, _prediction, _bPLOTPredictionAmount);
      emit SwapAndPredictFor(_predictFor, _marketId, _path[0], predictionToken, _inputAmount, _inputAmount);
    }

    /**
    * @dev Internal function to place prediction in given market
    */
    function _placePrediction(address _predictFor, uint _tokenDeposit, uint _marketId, uint _prediction, uint64 _bPLOTPredictionAmount) internal {
      _provideApproval(predictionToken, address(allPlotMarkets), _tokenDeposit);
      allPlotMarkets.depositAndPredictFor(_predictFor, _tokenDeposit, _marketId, predictionToken, _prediction, uint64(_tokenDeposit.div(decimalDivider)), _bPLOTPredictionAmount);
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

    function _verifyAndClaim(ClaimData memory _claimData) internal returns(uint _claimedAmount){
      require(verifySign(_claimData.user, userClaimNonce[_claimData.user], _claimData.claimAmount, _claimData.strategyId, _claimData.totalClaimed, _claimData.v, _claimData.r, _claimData.s));
      userClaimNonce[_claimData.user]++;
      uint _maxClaim = maxClaimPerStrategy[_claimData.strategyId];
      if(bonusClaimed[_claimData.user] < _claimData.totalClaimed) {
          bonusClaimed[_claimData.user] = _claimData.totalClaimed;
      }

      uint _actualClaim = _claimData.claimAmount;
      if(bonusClaimed[_claimData.user].add(_actualClaim) > _maxClaim) {
        _actualClaim = _maxClaim.sub(bonusClaimed[_claimData.user]);
      }

      bonusClaimed[_claimData.user] = bonusClaimed[_claimData.user].add(_actualClaim);

      require(_actualClaim > 0);

      _provideApproval(predictionToken, bPLOTToken, _actualClaim);
      require(IToken(bPLOTToken).mint(_claimData.user, _actualClaim));
      return _actualClaim;
    }

    /** 
     * @dev Verifies signature.
     * @param _v argument from vrs hash.
     * @param _r argument from vrs hash.
     * @param _s argument from vrs hash.
     */ 
    function verifySign(
        address _user,
        uint _userClaimNonce,
        uint _claimAmount,
        uint _strategyId,
        uint _totalClaimed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) 
        public
        view
        returns(bool)
    {
        bytes32 hash = getEncodedData(_user, _userClaimNonce, _claimAmount, _totalClaimed, _strategyId);
        return isValidSignature(hash, _v, _r, _s);
    }

    /**
     * @dev Gets order hash for given claim details.
     */ 
    function getEncodedData(
        address _user,
        uint _userClaimNonce,
        uint _claimAmount,
        uint _totalClaimed,
        uint _strategyId
    ) 
        public
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _user,
                _userClaimNonce,
                _claimAmount,
                _strategyId,
                _totalClaimed,
                address(this)
            )
        );
    }

    /**
     * @dev Verifies signature.
     * @param _hash order hash
     * @param _v argument from vrs hash.
     * @param _r argument from vrs hash.
     * @param _s argument from vrs hash.
     */  
    function isValidSignature(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) public view returns(bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _hash));
        address a = ecrecover(prefixedHash, _v, _r, _s);
        return (a == authorized);
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

}
