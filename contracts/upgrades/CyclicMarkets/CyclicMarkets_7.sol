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

import "./CyclicMarkets_6.sol";

contract CyclicMarkets_7 is CyclicMarkets_6 {

  /**
    * @dev Internal function to deduct fee from the prediction amount
    * @param _marketId Index of the market
    * @param _cummulativeFee Total fee amount
    * @param _msgSenderAddress User address
    */
  function handleFee_2(uint _marketId, uint64 _predictionAmount, address _msgSenderAddress, address _relayer) external onlyAllMarkets returns(uint64 _cummulativeFee) {
    MarketFeeParams storage _marketFeeParams = marketFeeParams;
    uint64 _feePerc = _getFeePerc(_msgSenderAddress, _marketFeeParams.cummulativeFeePercent);
    _cummulativeFee = _calculateAmulBdivC(_feePerc, _predictionAmount, 10000);
    uint64 _referrerFee = _calculateAmulBdivC(_marketFeeParams.referrerFeePercent, _cummulativeFee, 10000);
    uint64 _refereeFee = _calculateAmulBdivC(_marketFeeParams.refereeFeePercent, _cummulativeFee, 10000);
    bool _isEligibleForReferralReward;
    if(address(referral) != address(0)) {
    _isEligibleForReferralReward = referral.setReferralRewardData(_msgSenderAddress, plotToken, _referrerFee, _refereeFee);
    }
    if(_isEligibleForReferralReward){
      _transferAsset(plotToken, address(referral), (10**predictionDecimalMultiplier).mul(_referrerFee.add(_refereeFee)));
    } else {
      _refereeFee = 0;
      _referrerFee = 0;
    }
    uint64 _daoFee = _calculateAmulBdivC(_marketFeeParams.daoCommissionPercent, _cummulativeFee, 10000);
    uint64 _marketCreatorFee = _calculateAmulBdivC(_marketFeeParams.marketCreatorFeePercent, _cummulativeFee, 10000);
    _marketFeeParams.daoFee[_marketId] = _marketFeeParams.daoFee[_marketId].add(_daoFee);
    _marketFeeParams.marketCreatorFee[_marketId] = _marketFeeParams.marketCreatorFee[_marketId].add(_marketCreatorFee);
    _setRelayerFee(_relayer, _cummulativeFee, _daoFee, _referrerFee, _refereeFee, _marketCreatorFee);
  }

  function _getFeePerc(address _user, uint64 _currentFee) internal view returns(uint64 _feePerc) {
    (, , uint64 _levelFeeDiscount) = userLevels.getUserLevelAndPerks(_user);
    _feePerc = _currentFee;
    if(_levelFeeDiscount > 0) {
      _feePerc = _feePerc.mul(10000).div(_levelFeeDiscount);
    }
  }

  /**
  * @dev Internal function to calculate prediction points
  * @param _marketId Index of the market
  * @param _prediction Option predicted by the user
  * @param _user User Address
  * @param _multiplierApplied Flag defining if user had already availed multiplier
  * @param _predictionStake Amount staked by the user
  */
  function _calculatePredictionPoints(uint _marketId, uint256 _prediction, address _user, bool _multiplierApplied, uint _predictionStake) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
    uint _stakeValue = _predictionStake.mul(1e10);
    if(_stakeValue < minPredictionAmount || _stakeValue > maxPredictionAmount) {
      return (0, isMultiplierApplied);
    }
    uint64 _optionPrice = getOptionPriceWithStake(_marketId, _prediction, _predictionStake);
    predictionPoints = uint64(_predictionStake).div(_optionPrice);
    if(!_multiplierApplied || (initialPredictionFlag)) {
      uint256 _predictionPoints = predictionPoints;
      if(address(userLevels) != address(0)) {
        (_predictionPoints, isMultiplierApplied) = checkMultiplier(_user,  predictionPoints);
      }
      predictionPoints = uint64(_predictionPoints);
    }
  }

  /**
  * @dev Check if user gets any multiplier on his positions
  * @param _user User address
  * @param _predictionPoints The actual positions user got during prediction.
  * @return uint256 representing multiplied positions
  * @return bool returns true if multplier applied
  */
  function checkMultiplier(address _user, uint _predictionPoints) internal view returns(uint, bool) {
    bool _multiplierApplied;
    uint _muliplier = 100;
    (uint256 _userLevel, uint256 _levelMultiplier, ) = userLevels.getUserLevelAndPerks(_user);
    if(_userLevel > 0) {
      _muliplier = _muliplier + _levelMultiplier;
      _multiplierApplied = true;
    }
    return (_predictionPoints.mul(_muliplier).div(100), _multiplierApplied);
  }

}
