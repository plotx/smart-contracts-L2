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

contract ClaimAndPredict is NativeMetaTransaction {
    using SafeMath for uint;

    IAllMarkets internal allPlotMarkets;
    address internal predictionToken;
    address internal bPLOTToken;

    mapping(address => uint) bonusClaimed;
    mapping(address => uint) claimCount;

    struct MetaTxData {
      address targetAddress;
      address userAddress;
      bytes functionSignature;
      bytes32 sigR;
      bytes32 sigS;
      uint8 sigV;
    }

    // struct Strategy {
    //   uint maxClaim;
    //   uint noOfClaims;
    //   uint[] claimSequence;
    // }

    // struct UserData {
    //     uint64 totalClaimed;
    //     uint nextSequence;
    // }

    // Strategy[] strategies;
    mapping(uint => uint) maxClaimPerStrategy;
    // mapping(address => UserData) userData;

    address public authorized;
    uint internal decimalDivider;

    modifier onlyAuthorized() {
      require(_msgSender() == authorized);
      _;
    }

    constructor(address _authorized, address _predictionToken, address _bPLOTToken) public {
      require(_authorized != address(0));
      authorized = _authorized;
      predictionToken =_predictionToken;
      bPLOTToken = _bPLOTToken;
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

    // function addStrategy(uint _maxClaim, uint _noOfClaims, uint[] calldata _claimSequence) external {
    //   strategies.push(Strategy(_maxClaim, _noOfClaims, _claimSequence));
    // }

    function claimAndPredictWithNativeToken(address _user, uint _userClaimNonce, uint _strategyId, uint _claimAmount, uint _totalClaimed, MetaTxData calldata txData)
      payable
      external
    {

      require(verifySign(_user, _userClaimNonce, _strategyId, _claimAmount, _totalClaimed, _v, _r, _s));
      uint _maxClaim = maxClaimPerStrategy[_strategyId];
      if(bonusClaimed[_user] < _totalClaimed) {
          bonusClaimed[_user] = _totalClaimed;
      }

      uint _actualClaim = _claimAmount;
      if(bonusClaimed[_user].add(_actualClaim) > _maxClaim) {
        _actualClaim = _maxClaim.sub(bonusClaimed[_user]);
      }

      _provideApproval(predictionToken, bPLOTToken, _actualClaim);
      require(IToken(bPLOTToken).mint(_user, _actualClaim));
      NativeMetaTransaction(txData.targetAddress).executeMetaTransaction(txData.userAddress, txData.functionSignature, txData.sigR, txData.sigS, txData.sigV);

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
        uint _strategyId,
        uint _claimAmount,
        uint _totalClaimed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) 
        public
        view
        returns(bool)
    {
        bytes32 hash = getEncodedData(coverDetails, coverPeriod, curr, smaratCA);
        return isValidSignature(hash, _v, _r, _s);
    }

    /**
     * @dev Gets order hash for given cover details.
     * @param coverDetails details realted to cover.
     * @param coverPeriod validity of cover.
     * @param smaratCA smarat contract address.
     */ 
    function getEncodedData(
        address _user,
        uint _userClaimNonce,
        uint _strategyId,
        uint _claimAmount,
        uint _totalClaimed
    ) 
        public
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _user,
                _userClaimNonce,
                _strategyId,
                _claimAmount,
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

    function claimAndPlacePrediction(address _user, uint _userClaimNonce, uint _strategyId, uint _claimAmount, uint _totalClaimed, MetaTxData calldata txData)
      external 
      onlyAuthorized
    {
      uint _maxClaim = maxClaimPerStrategy[_strategyId];
      if(bonusClaimed[_user] < _totalClaimed) {
          bonusClaimed[_user] = _totalClaimed;
      }

      uint _actualClaim = _claimAmount;
      if(bonusClaimed[_user].add(_actualClaim) > _maxClaim) {
        _actualClaim = _maxClaim.sub(bonusClaimed[_user]);
      }

      _provideApproval(predictionToken, bPLOTToken, _actualClaim);
      require(_actualClaim > 0 && IToken(bPLOTToken).mint(_user, _actualClaim));
      NativeMetaTransaction(txData.targetAddress).executeMetaTransaction(_user, txData.functionSignature, txData.sigR, txData.sigS, txData.sigV);

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

    // function renounceAsMinter

}
