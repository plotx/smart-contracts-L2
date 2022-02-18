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

import "./AcyclicMarkets_4.sol";

contract AcyclicMarkets_5 is AcyclicMarkets_4 {
  
  struct MarketTempData {
    uint32 startTime;
    uint64 daoFee;
    uint64 marketCreatorFee;
  }

  mapping(uint256 => MarketTempData) internal marketTempData;
  uint internal referralReward;

  function accrueRewards() public {
    allMarkets.transferAccumulatedRewards();
    _transferAsset(plotToken, address(referral), referralReward);
    delete referralReward;
  }

  /**
    * @dev Internal function to deduct fee from the prediction amount
    * @param _marketId Index of the market
    * @param _cummulativeFee Total fee amount
    * @param _msgSenderAddress User address
    */
  function handleFee(uint _marketId, uint64 _cummulativeFee, address _msgSenderAddress, address _relayer) external onlyAllMarkets {
    MarketFeeParams storage _marketFeeParams = marketFeeParams;
    uint64 _referralReward;
    if(address(referral) != address(0)) {
      uint64 _referrerFee = _calculateAmulBdivC(_marketFeeParams.referrerFeePercent, _cummulativeFee, 10000);
      uint64 _refereeFee = _calculateAmulBdivC(_marketFeeParams.refereeFeePercent, _cummulativeFee, 10000);
      bool _isEligibleForReferralReward = referral.setReferralRewardData(_msgSenderAddress, plotToken, _referrerFee, _refereeFee);
      if(_isEligibleForReferralReward){
        _referralReward = _referrerFee.add(_refereeFee);
        referralReward =  referralReward.add(_referralReward);
        // _transferAsset(plotToken, address(referral), (10**predictionDecimalMultiplier).mul(_referrerFee.add(_refereeFee)));
      }
    }

    uint64 _daoFee = _calculateAmulBdivC(_marketFeeParams.daoCommissionPercent, _cummulativeFee, 10000);
    uint64 _marketCreatorFee = _calculateAmulBdivC(_marketFeeParams.marketCreatorFeePercent, _cummulativeFee, 10000);
    MarketTempData storage _marketTempData = marketTempData[_marketId];
    _marketTempData.daoFee = _marketTempData.daoFee.add(_daoFee);
    _marketTempData.marketCreatorFee = _marketTempData.marketCreatorFee.add(_marketCreatorFee);
    _setRelayersFee(_relayer, _cummulativeFee, _daoFee, _referralReward, _marketCreatorFee);
  }

  /**
  * @dev Internal function to set the relayer fee earned in the prediction 
  */
  function _setRelayersFee(address _relayer, uint _cummulativeFee, uint _daoFee, uint _referralFee, uint _marketCreatorFee) internal {
    relayerFeeEarned[_relayer] = relayerFeeEarned[_relayer].add(_cummulativeFee.sub(_daoFee).sub(_referralFee).sub(_marketCreatorFee));
  }

  /**
  * @dev Settle the market, setting the winning option
  * @param _marketId Index of market
  */
  function settleMarket(uint256 _marketId, uint _answer) public {
    require(_msgSender() ==  authToSettleMarkets);
    allMarkets.settleMarket(_marketId, _answer);
    if(allMarkets.marketStatus(_marketId) >= IAllMarkets.PredictionStatus.InSettlement) {
      _transferAsset(plotToken, masterAddress, (10**predictionDecimalMultiplier).mul(marketTempData[_marketId].daoFee));
      delete marketTempData[_marketId].daoFee;

      marketCreationReward[marketData[_marketId].marketCreator] = marketCreationReward[marketData[_marketId].marketCreator].add((10**predictionDecimalMultiplier).mul(marketTempData[_marketId].marketCreatorFee));
      emit MarketCreatorReward(marketData[_marketId].marketCreator, _marketId, marketTempData[_marketId].marketCreatorFee);
      delete marketTempData[_marketId].marketCreatorFee;

      _transferAsset(plotToken, address(referral), referralReward);
      delete referralReward;
      delete marketTempData[_marketId];
    }
  }
}
