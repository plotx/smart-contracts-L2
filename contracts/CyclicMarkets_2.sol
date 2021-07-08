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

import "./CyclicMarkets.sol";

contract CyclicMarkets_2 is CyclicMarkets {

    struct EarlyParticipantMultiplier {
      uint64 cutoffTime;
      uint64 multiplierPerc;
    }

    event MarketCreatorRewardPoolShare(address marketCreator, uint256 marketIndex, uint256 rewardEarned);

    mapping(address => uint) public rewardPoolShareForMarketCreator;
    mapping(uint => EarlyParticipantMultiplier) public earlyParticipantMultiplier;

    uint64 public rewardPoolSharePercForMarketCreator;

    /**
    * @dev Set multiplier% and cutoff time for early participant of given market type 
    * @param _marketType Index of market type
    * @param _cutoffTime Time before to provide multiplier
    * @param _multiplierPercent Multiplier to be given in percent
    */
    function setEarlyParticipantMultiplier(uint _marketType, uint64 _cutoffTime, uint64 _multiplierPercent) external onlyAuthorized {
      earlyParticipantMultiplier[_marketType] = EarlyParticipantMultiplier(_cutoffTime, _multiplierPercent);
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
      (predictionPoints, isMultiplierApplied) = super.calculatePredictionPoints(_marketId, _prediction, _user, _multiplierApplied, _predictionStake);
    	uint _marketType = marketData[_marketId].marketTypeIndex;
      EarlyParticipantMultiplier memory _multiplierData = earlyParticipantMultiplier[_marketType];
      uint _startTime = calculateStartTimeForMarket(uint32(_marketType), uint32(marketData[_marketId].marketCurrencyIndex));
      uint _timePassed = uint(now).sub(_startTime);
      if(_timePassed <= _multiplierData.cutoffTime) {
        uint64 _muliplier = 100;
        _muliplier = _muliplier + 10;
        predictionPoints = (predictionPoints.mul(_muliplier).div(100));
      }
    }

    /**
    * @dev function to update integer parameters
    * @param code Code of the updating parameter.
    * @param value Value to which the parameter should be updated
    */
    function updateUintParameters(bytes8 code, uint256 value) external onlyAuthorized {
      if(code == "CPW") { // Current price weighage
        require(value <= 100);
        currentPriceWeightage = uint32(value);
        //Staking factor weightage% = 100% - currentPriceWeightage%
        stakingFactorWeightage = 100 - currentPriceWeightage;
      } else if(code == "SFMS") { // Minimum amount for staking factor to apply
        stakingFactorMinStake = value;
      } else if(code == "MINP") { // Minimum prediction amount
        minPredictionAmount = value;
      } else if(code == "MAXP") { // Maximum prediction amount
        maxPredictionAmount = value;
      } else {
        MarketFeeParams storage _marketFeeParams = marketFeeParams;
        require(value < 10000);
        if(code == "CMFP") { // Cummulative fee percent
          _marketFeeParams.cummulativeFeePercent = uint32(value);
        } else {
          if(code == "DAOF") { // DAO Fee percent in Cummulative fee
            _marketFeeParams.daoCommissionPercent = uint32(value);
          } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
            _marketFeeParams.referrerFeePercent = uint32(value);
          } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
            _marketFeeParams.refereeFeePercent = uint32(value);
          } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
            _marketFeeParams.marketCreatorFeePercent = uint32(value);
          } else if(code == "RPS") {
          	require(value <= 100);
      		rewardPoolSharePercForMarketCreator = uint64(value); // no need to handle overflow, we are checking for <100
          } else {
            revert("Invalid code");
          } 
          require(
            _marketFeeParams.daoCommissionPercent + 
            _marketFeeParams.referrerFeePercent + 
            _marketFeeParams.refereeFeePercent + 
            _marketFeeParams.marketCreatorFeePercent
            < 10000);
        }
      }
    }

    /**
    * @dev function to get integer parameters
    * @param code Code of the parameter.
    * @return codeVal Code of the parameter.
    * @return value Value of the queried parameter.
    */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value) {
      codeVal = code;
      if(code == "CPW") { // Current price weighage
        value = currentPriceWeightage;
      } else if(code == "SFMS") { // Minimum amount for staking factor to apply
        value = stakingFactorMinStake;
      } else if(code == "MINP") { // Minimum prediction amount
        value = minPredictionAmount;
      } else if(code == "MAXP") { // Maximum prediction amount
        value = maxPredictionAmount;
      } else if(code == "CMFP") { // Cummulative fee percent
        value = marketFeeParams.cummulativeFeePercent;
      } else if(code == "DAOF") { // DAO Fee percent in Cummulative fee
        value = marketFeeParams.daoCommissionPercent;
      } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
        value = marketFeeParams.referrerFeePercent;
      } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
        value = marketFeeParams.refereeFeePercent;
      } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
        value = marketFeeParams.marketCreatorFeePercent;
      } else if(code == "RPS") {
      	value = rewardPoolSharePercForMarketCreator;
      }
    }

    function setRewardPoolShareForCreator(uint _marketId, uint _amount) external onlyAllMarkets {
    	address creator = marketData[_marketId].marketCreator;
		  rewardPoolShareForMarketCreator[creator] = rewardPoolShareForMarketCreator[creator].add(_amount);
      emit MarketCreatorRewardPoolShare(creator, _marketId, _amount);
    }

    /**
    * @dev function to reward user for initiating market creation calls as per the new incetive calculations
    */
    function claimCreationReward() external {
      address payable _msgSenderAddress = _msgSender();
      uint256 rewardEarned = marketCreationReward[_msgSenderAddress];
      delete marketCreationReward[_msgSenderAddress];
      uint poolShareEarned = rewardPoolShareForMarketCreator[_msgSenderAddress];
    	delete rewardPoolShareForMarketCreator[_msgSenderAddress];
      rewardEarned = rewardEarned.add(poolShareEarned);
      require(rewardEarned > 0, "No pending");
      _transferAsset(plotToken, _msgSenderAddress, rewardEarned);
      emit ClaimedMarketCreationReward(_msgSenderAddress, rewardEarned, plotToken);
    }

}
