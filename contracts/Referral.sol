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

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IAllMarkets.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IAuth.sol";

contract Referral is IAuth, NativeMetaTransaction {

    event ReferralLog(address indexed referrer, address indexed referee, uint256 referredOn);
    event ClaimedReferralReward(address indexed user, uint256 amount);

    struct UserData {
      uint referrerFee; // Fee earned by referring another user
      uint refereeFee; // Fee earned after being referred by another user
      address referrer; // Address of the referrer 
    }

    IAllMarkets internal allMarkets;
    address internal masterAddress;
    address internal plotToken;

    uint internal predictionDecimalMultiplier;

    mapping (address => UserData) public userData;

    modifier onlyInternal {
      IMaster(masterAddress).isInternal(msg.sender);
      _;
    }

    /**
     * @dev Changes the master address and update it's instance
     * @param _authorizedMultiSig Authorized address to execute critical functions in the protocol.
     * @param _defaultAuthorizedAddress Authorized address to trigger initial functions by passing required external values.
     */
    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner());
      IMaster ms = IMaster(msg.sender);
      masterAddress = msg.sender;
      address _plotToken = ms.dAppToken();
      plotToken = _plotToken;
      allMarkets = IAllMarkets(ms.getLatestAddress("AM"));
      authorized = _authorizedMultiSig;
      predictionDecimalMultiplier = 10;
      _initializeEIP712("RF");
    }

    /**
    * @dev Set referrer address of a user, can be set only by the authorized users
    * @param _referrer User who is referring new user
    * @param _referee User who is referring new user
    * @return _referee User who is getting referred
    */
    function setReferrer(address _referrer, address _referee) external onlyAuthorized {
      UserData storage _userData = userData[_referee];
      require(allMarkets.getTotalStakedByUser(_referee) == 0);
      require(_userData.referrer == address(0));
      _userData.referrer = _referrer;
      emit ReferralLog(_referrer, _referee, now);
    }

    /**
    * @dev Set referrer address of a user, can be set only by the authorized users
    * @param _referee User who is referring new user
    */
    function setReferralRewardData(address _referee, uint _referrerFee, uint _refereeFee) external onlyInternal {
      UserData storage _userData = userData[_referee];
      address _referrer = _userData.referrer;
      if(_referrer != address(0)) {
        //Commission for referee
        _userData.refereeFee = _userData.refereeFee.add(_refereeFee);
        //Commission for referrer
        userData[_referrer].referrerFee = userData[_referrer].referrerFee.add(_referrerFee);
      }
    }

    /**
    * @dev Get fees earned by participating in the referral program
    * @param _user Address of the user
    * @return _referrerFee Fees earned by referring other users
    * @return _refereeFee Fees earned if referred by some one
    */
    function getReferralFees(address _user) external view returns(uint256 _referrerFee, uint256 _refereeFee) {
      UserData storage _userData = userData[_user];
      return (_userData.referrerFee, _userData.refereeFee);
    }

    /**
    * @dev Claim the fee earned by referrals
    * @param _user Address to claim the fee for
     */
    function claimReferralFee(address _user) external {
      UserData storage _userData = userData[_user];
      uint256 _referrerFee = _userData.referrerFee;
      delete _userData.referrerFee;
      uint256 _refereeFee = _userData.refereeFee;
      delete _userData.refereeFee;
      uint _tokenToTransfer = (_refereeFee.add(_referrerFee)).mul(10**predictionDecimalMultiplier);
      _transferAsset(plotToken, _user, _tokenToTransfer);
      emit ClaimedReferralReward(_user, _tokenToTransfer);
    }

    /**
    * @dev Transfer the _asset to specified address.
    * @param _recipient The address to transfer the asset of
    * @param _amount The amount which is transfer.
    */
    function _transferAsset(address _asset, address _recipient, uint256 _amount) internal {
      if(_amount > 0) { 
          require(IToken(_asset).transfer(_recipient, _amount));
      }
    }

}