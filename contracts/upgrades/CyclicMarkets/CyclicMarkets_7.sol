/* Copyright (C) 2022 PlotX.io

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
<<<<<<< HEAD
  * @dev Unset the referral contract address
  */
  function removeReferralContract() external onlyAuthorized {
    require(address(referral) != address(0) && referralReward == 0);
    delete referral;
  }

  /**
=======
>>>>>>> cb1473130210e848b07c2314ba556de756d05393
  * @dev function to reward user for initiating market creation calls as per the new incetive calculations
  */
  function claimCreationReward() external {
    address payable _msgSenderAddress = _msgSender();
    accrueRewards();
    uint256 rewardEarned = marketCreationReward[_msgSenderAddress];
    delete marketCreationReward[_msgSenderAddress];
    uint poolShareEarned = rewardPoolShareForMarketCreator[_msgSenderAddress];
    delete rewardPoolShareForMarketCreator[_msgSenderAddress];
    rewardEarned = rewardEarned.add(poolShareEarned);
    require(rewardEarned > 0, "No pending");
    _transferAsset(plotToken, _msgSenderAddress, rewardEarned);
    emit ClaimedMarketCreationReward(_msgSenderAddress, rewardEarned, plotToken);
  }

  /**
  * @dev Claim fees earned by the relayer address
  */
  function claimRelayerRewards() external {
    accrueRewards();
    uint _decimalMultiplier = 10**predictionDecimalMultiplier;
    address _relayer = msg.sender;
    uint256 _fee = (_decimalMultiplier).mul(relayerFeeEarned[_relayer]);
    delete relayerFeeEarned[_relayer];
    require(_fee > 0);
    _transferAsset(plotToken, _relayer, _fee);
  }

  /**
  * @dev Settle the market, setting the winning option
  * @param _marketId Index of market
  * @param _roundId RoundId of the feed for the settlement price
  */
  function settleMarket(uint256 _marketId, uint80 _roundId) public {
    address _feedAdd = marketCurrencies[marketData[_marketId].marketCurrencyIndex].marketFeed;
    (uint256 _value, ) = IOracle(_feedAdd).getSettlementPrice(allMarkets.marketSettleTime(_marketId), _roundId);
    allMarkets.settleMarket(_marketId, _value);
    if(allMarkets.marketStatus(_marketId) >= IAllMarkets.PredictionStatus.InSettlement) {
      _transferAsset(plotToken, masterAddress, (10**predictionDecimalMultiplier).mul(marketTempData[_marketId].daoFee));
      marketCreationReward[marketData[_marketId].marketCreator] = marketCreationReward[marketData[_marketId].marketCreator].add((10**predictionDecimalMultiplier).mul(marketTempData[_marketId].marketCreatorFee));
      emit MarketCreatorReward(marketData[_marketId].marketCreator, _marketId, (10**predictionDecimalMultiplier).mul(marketTempData[_marketId].marketCreatorFee));
      
      _transferAsset(plotToken, address(referral), referralReward);
      delete referralReward;
      delete marketTempData[_marketId];
    }
  }

  function createMarketWithOptionRanges(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint64[] calldata _optionRanges) external {
    initialPredictionFlag = true;
    address _msgSenderAddress = _msgSender();
    require(isAuthorizedCreator[_msgSenderAddress]);
    MarketTypeData storage _marketType = marketTypeArray[_marketTypeIndex];
    MarketCurrency storage _marketCurrency = marketCurrencies[_marketCurrencyIndex];
    MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
    require(!_marketType.paused && !_marketCreationData.paused);
    uint32 _startTime = _checkPreviousMarketAndGetStartTime( _marketTypeIndex, _marketCurrencyIndex, _marketType.predictionTime);
    uint32[] memory _marketTimes = new uint32[](4);
    uint64 _marketIndex = allMarkets.getTotalMarketsLength();
    uint _optionLength = marketTypeOptionPricing[_marketTypeIndex];
    marketOptionPricing[_marketIndex] = optionPricingContracts[_optionLength];
    marketTempData[_marketIndex].startTime = _startTime; // Will increase gas consumption while creation but reduces gas while prediction
    require(_optionLength - 1 == _optionRanges.length);
    //   _optionRanges = _calculateOptionRanges(marketOptionPricing[_marketIndex], _marketType.optionRangePerc, _marketCurrency.decimals, _marketCurrency.roundOfToNearest, _marketCurrency.marketFeed);
    _marketTimes[0] = _startTime; 
    _marketTimes[1] = _marketType.predictionTime;
    _marketTimes[2] = marketTypeSettlementTime[_marketTypeIndex];
    _marketTimes[3] = _marketType.cooldownTime;
    // marketPricingData[_marketIndex] = PricingData(stakingFactorMinStake, stakingFactorWeightage, currentPriceWeightage, _marketType.minTimePassed);
    marketData[_marketIndex] = MarketData(_marketTypeIndex, _marketCurrencyIndex, _msgSenderAddress);
    uint64 _initialLiquidity = mcPairInitialLiquidity[_marketTypeIndex][_marketCurrencyIndex];
    if(_initialLiquidity == 0) {
      _initialLiquidity =  _marketType.initialLiquidity;
    }
    allMarkets.createMarket(_marketTimes, _optionRanges, _msgSenderAddress, _initialLiquidity);

    _updateMarketIndexesAndEmitEvent(_marketTypeIndex, _marketCurrencyIndex, _marketIndex, _msgSenderAddress, _marketCurrency.currencyName, _marketType.minTimePassed);

    initialPredictionFlag = false;
  }

  /**
  * @dev Internal function to calculate prediction points
  * @param _marketId Index of the market
  * @param _prediction Option predicted by the user
  * @param _user User Address
  * @param _multiplierApplied Flag defining if user had already availed multiplier
  * @param _predictionStake Amount staked by the user
  */
  function calculatePredictionPoints(uint _marketId, uint256 _prediction, address _user, bool _multiplierApplied, uint _predictionStake) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
    (predictionPoints, isMultiplierApplied) = _calculatePredictionPoints(_marketId, _prediction, _user, _multiplierApplied, _predictionStake);
    uint _marketType = marketData[_marketId].marketTypeIndex;
    EarlyParticipantMultiplier memory _multiplierData = earlyParticipantMultiplier[_marketType];
    // (, uint _startTime) = allMarkets.getMarketOptionPricingParams(_marketId, _prediction);
    uint _startTime = marketTempData[_marketId].startTime;
    uint _timePassed;
    // If given market is buffer market, then the time passed should be zero, as start time will not be reached 
    if(_startTime < now) {
      _timePassed = uint(now).sub(_startTime);
    }
    if(_timePassed <= _multiplierData.cutoffTime) {
      uint64 _muliplier = 100;
      _muliplier = _muliplier.add(_multiplierData.multiplierPerc);
      predictionPoints = (predictionPoints.mul(_muliplier).div(100));
    }
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

}
