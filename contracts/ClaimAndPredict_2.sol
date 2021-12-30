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

import "./ClaimAndPredict.sol";

contract ClaimAndPredict_2 is ClaimAndPredict {

    function handleReturnClaim(address _user, uint _claimAmount) public returns(uint _finalClaim, uint amountToDeduct) {
      revert("DEPR");//Deprecated
    }

    /**
    * @dev function to update integer parameters
    * @param code Code of the updating parameter.
    * @param value Value to which the parameter should be updated
    */
    function updateUintParameters(bytes8 code, uint256 value) external onlyAuthorized {
      require(value == uint64(value)); // Shouldn't overflow with uint 64 as we are maintaining all our storage with uint 64
      if(code == "BMCA") { // bonusMinClaimAmount
        bonusMinClaimAmount = value;
      } if(code == "BMRA") { // bonusMaxReturnAmount
        bonusMaxReturnBackAmount = value;
      } else if(code == "BCFP") { // bonusClaimFeePerc
        require(value < 100); // Fee should be less than 100%
        bonusClaimFeePerc = value;
      } else if(code == "BCMF") { //bonusClaimMaxFee
        bonusClaimMaxFee = value;
      }
    }

    function handleReturnClaim_2(address _user, uint _claimAmount, bool _forceClaimFlag) public returns(uint _finalClaim, uint amountToDeduct) {
      require(msg.sender == address(allPlotMarkets));
      uint64 bonusReturned = userData[_user].bonusReturned;
      amountToDeduct = userData[_user].bonusClaimed.sub(bonusReturned);
      if(amountToDeduct > bonusMaxReturnBackAmount) {
        amountToDeduct = bonusMaxReturnBackAmount;
      }
      userData[_user].bonusReturned = bonusReturned.add(uint64(amountToDeduct));

      amountToDeduct = decimalDivider.mul(amountToDeduct);
      if(bonusReturned == 0) {
        require(_claimAmount > decimalDivider.mul(bonusMinClaimAmount) || _forceClaimFlag);
        uint _feeDeduction = _claimAmount.mul(bonusClaimFeePerc).div(100);
        _feeDeduction = bonusClaimMaxFee < _feeDeduction ? bonusClaimMaxFee:_feeDeduction;
        amountToDeduct = amountToDeduct + _feeDeduction;
      }
      if(_claimAmount > amountToDeduct) {
        _finalClaim = _claimAmount.sub(amountToDeduct);
      } else {
        require(_forceClaimFlag);
        _finalClaim = 0;
        amountToDeduct = _claimAmount;
      }
      emit BonusClaimed(_user, _finalClaim, amountToDeduct);
    }

}
