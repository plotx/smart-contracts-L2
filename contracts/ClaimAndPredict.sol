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
    using SafeMath64 for uint64;

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
      uint64 claimAmount;
      uint64 totalClaimed;
      uint8 v;
      bytes32 r;
      bytes32 s;
    }

    struct UserData {
      uint64 bonusClaimed;
      uint64 bonusReturned;
      uint64 claimNonce;
    }

    IAllMarkets internal allPlotMarkets;
    address internal predictionToken;
    address internal bPLOTToken;

    // mapping(address => uint) public bonusClaimed;
    // mapping(address => uint) internal returnClaimed;
    // mapping(address => uint) public userClaimNonce;
    mapping(address => UserData) public userData;

    mapping(address => bool) public allowedTokens;

    mapping(uint => uint64) public maxClaimPerStrategy;

    uint internal bonusMinClaimAmount; // 10^^8
    uint internal bonusMaxReturnBackAmount; // 10^^8
    uint internal bonusClaimFeePerc; // No decimals
    uint internal bonusClaimMaxFee; // 10^^8

    address public authorized;
    uint internal constant decimalDivider = 1e10;

    modifier onlyAuthorized() {
      require(_msgSender() == authorized);
      _;
    }

    event BonusClaimed(address userAddress, uint claimAmount, uint amountDeducted);

    function initialize(address _masterAddress, address _authorized) public {
      require(predictionToken == address(0), "Already initialized");
  
      require(_masterAddress != address(0));
      require(_authorized != address(0));

      IMaster ms = IMaster(_masterAddress);
      authorized = _authorized;
      allPlotMarkets = IAllMarkets(ms.getLatestAddress("AM"));
      predictionToken = ms.dAppToken();
      bPLOTToken = ms.getLatestAddress("BL");

      bonusMinClaimAmount = 50 * 1e8;
      bonusMaxReturnBackAmount = 50 * 1e8;
      bonusClaimFeePerc = 10;
      bonusClaimMaxFee = 10 * 1e18;

      _initializeEIP712("CP");
    }

    /**
    * @dev function to get integer parameters
    * @param code Code of the parameter.
    * @return codeVal Code of the parameter.
    * @return value Value of the queried parameter.
    */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value) {
      codeVal = code;
      if(code == "BMCA") { // bonusMinClaimAmount
        value = bonusMinClaimAmount;
      } if(code == "BMRA") { // bonusMaxReturnAmount
        value = bonusMaxReturnBackAmount;
      } else if(code == "BCFP") { // bonusClaimFeePerc
        value = bonusClaimFeePerc;
      } else if(code == "BCMF") { //bonusClaimMaxFee
        value = bonusClaimMaxFee;
      }
    }

    /**
    * @dev function to update integer parameters
    * @param code Code of the updating parameter.
    * @param value Value to which the parameter should be updated
    */
    function updateUintParameters(bytes8 code, uint256 value) external onlyAuthorized {
      if(code == "BMCA") { // bonusMinClaimAmount
        bonusMinClaimAmount = value;
      } if(code == "BMRA") { // bonusMaxReturnAmount
        bonusMaxReturnBackAmount = value;
      } else if(code == "BCFP") { // bonusClaimFeePerc
        bonusClaimFeePerc = value;
      } else if(code == "BCMF") { //bonusClaimMaxFee
        bonusClaimMaxFee = value;
      }
    }

    /**
     * @dev Update authorized address
     * @param _newAuth New authorized address 
     */
    function changeAuthorizedAddress(address _newAuth) external onlyAuthorized {
      require(_newAuth != address(0));
      authorized = _newAuth;
    }

    /**
     * @dev Update max claim amount for corresponding strategy
     * @param _strategies Array of strategy Id's to update max claim amount
     * @param _maxClaim Array of max claim amounts corresponding to the same index of strategies array 
     */
    function updateMaxClaimPerStrategy(uint[] calldata _strategies, uint64[] calldata _maxClaim) external onlyAuthorized {
      for(uint i= 0;i<_strategies.length;i++) {
        maxClaimPerStrategy[_strategies[i]] = _maxClaim[i];
      }
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

    function handleReturnClaim(address _user, uint _claimAmount) public returns(uint _finalClaim, uint amountToDeduct) {
      require(msg.sender == address(allPlotMarkets));

      uint64 bonusReturned = userData[_user].bonusReturned;
      amountToDeduct = userData[_user].bonusClaimed.sub(bonusReturned);
      if(amountToDeduct > bonusMaxReturnBackAmount) {
        amountToDeduct = bonusMaxReturnBackAmount;
      }
      userData[_user].bonusReturned = bonusReturned.add(uint64(amountToDeduct));

      amountToDeduct = decimalDivider.mul(amountToDeduct);
      if(bonusReturned == 0) {
        require(_claimAmount > decimalDivider.mul(bonusMinClaimAmount));
        uint _feeDeduction = _claimAmount.mul(bonusClaimFeePerc).div(100);
        _feeDeduction = bonusClaimMaxFee < _feeDeduction ? bonusClaimMaxFee:_feeDeduction;
        amountToDeduct = amountToDeduct + _feeDeduction;
      }
      _finalClaim = _claimAmount.sub(amountToDeduct);
      emit BonusClaimed(_user, _finalClaim, amountToDeduct);
    }

    /**
    * @dev Function to preform claim operation and 
    */
    function claimAndPredict(
      ClaimData calldata _claimData,
      MetaTxData calldata _txData
    )
      external
    {
      require(_txData.userAddress == _claimData.user);
      uint _initialbPlotBalance = getTokenBalance(address(bPLOTToken), false);
      uint _claimAmount = _verifyAndClaim(_claimData, _txData.functionSignature);
      NativeMetaTransaction(_txData.targetAddress).executeMetaTransaction(_claimData.user, _txData.functionSignature, _txData.sigR, _txData.sigS, _txData.sigV);
      require(_initialbPlotBalance.sub(_claimAmount) == getTokenBalance(address(bPLOTToken), false));
      
    }

    function _verifyAndClaim(ClaimData memory _claimData, bytes memory _functionSignature) internal returns(uint _claimedAmount){
      UserData storage _userData = userData[_claimData.user];
      require(verifySign(_claimData.user, _userData.claimNonce, _claimData.claimAmount, _claimData.strategyId, _claimData.totalClaimed, _claimData.v, _claimData.r, _claimData.s, _functionSignature));
      uint64 _maxClaim = maxClaimPerStrategy[_claimData.strategyId];
      uint64 _bonusClaimedByUser = _userData.bonusClaimed;
      // Check later=>If claimed == returned then set flag
      allPlotMarkets.setClaimFlag(_claimData.user, _userData.claimNonce);
      _userData.claimNonce++;

      if(_bonusClaimedByUser < _claimData.totalClaimed) {
          _bonusClaimedByUser = _claimData.totalClaimed;
      }

      uint64 _actualClaim = _claimData.claimAmount;
      if(_bonusClaimedByUser.add(_actualClaim) > _maxClaim) {
        _actualClaim = _maxClaim.sub(_bonusClaimedByUser);
      }

      _userData.bonusClaimed = _bonusClaimedByUser.add(_actualClaim);

      require(_actualClaim > 0);

      _claimedAmount = decimalDivider.mul(_actualClaim);
      require(IToken(bPLOTToken).transfer(_claimData.user, _claimedAmount));
      return _claimedAmount;
    }

    /** 
     * @dev Verifies signature.
     * @param _v argument from vrs hash.
     * @param _r argument from vrs hash.
     * @param _s argument from vrs hash.
     */ 
    function verifySign(
        address _user,
        uint64 _userClaimNonce,
        uint64 _claimAmount,
        uint _strategyId,
        uint64 _totalClaimed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes memory _functionSignature
        
    ) 
        public
        view
        returns(bool)
    {
        bytes32 hash = getEncodedData(_user, _userClaimNonce, _claimAmount, _totalClaimed, _strategyId, _functionSignature);
        return isValidSignature(hash, _v, _r, _s);
    }

    /**
     * @dev Gets order hash for given claim details.
     */ 
    function getEncodedData(
        address _user,
        uint64 _userClaimNonce,
        uint64 _claimAmount,
        uint64 _totalClaimed,
        uint _strategyId,
        bytes memory _functionSignature
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
                _functionSignature,
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
