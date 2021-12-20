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

import "./AllPlotMarkets_7.sol";

contract AllPlotMarkets_8 is AllPlotMarkets_7 {

  address internal authToForceWithdraw;

  function setAuthToWithdrawFor(address _authToForceWithdraw) public onlyAuthorized {
      authToForceWithdraw = _authToForceWithdraw;
  }
  
  /**
  * @dev Withdraw pending balance for giver user
  * @param _userAddress Address of the user to withdraw tokens for
  */
  function withdrawForInactiveUser(address _userAddress) public {
    _withdraw(userData[_userAddress].unusedBalance, 1, 0, _userAddress);
  }

  /**
  * @dev Internal function to withdraw deposited and available assets
  * @param _token Amount of prediction token to withdraw
  * @param _maxRecords Maximum number of records to check
  * @param _tokenLeft Amount of prediction token left unused for user
  */
  function _withdraw(uint _token, uint _maxRecords, uint _tokenLeft, address _msgSenderAddress) internal {
    _withdrawReward(_maxRecords, _msgSenderAddress);
    userData[_msgSenderAddress].unusedBalance = userData[_msgSenderAddress].unusedBalance.sub(_token);
    require(_token > 0);
    uint _userClaim = _token;
    if(userBonusClaimedFlag[_msgSenderAddress] && address(trailBonusHandler) != address(0)) {
      uint _deduction;
      bool _forceClaimFlag;
      if(_msgSender() == authToForceWithdraw) {
        _forceClaimFlag = true;
      }
      (_userClaim, _deduction) = trailBonusHandler.handleReturnClaim_2(_msgSenderAddress, _userClaim, _forceClaimFlag);
      require((_userClaim.add(_deduction)) == _token);
      _transferAsset(predictionToken, address(trailBonusHandler), _deduction);
      delete userBonusClaimedFlag[_msgSenderAddress];
    }
    _transferAsset(predictionToken, _msgSenderAddress, _userClaim);
    emit Withdrawn(_msgSenderAddress, _userClaim, now);
  }
}
