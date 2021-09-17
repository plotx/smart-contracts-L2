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

import "./AcyclicMarkets.sol";

contract AcyclicMarkets_2 is AcyclicMarkets {

    event MarketCreatorRewardPoolShare(address marketCreator, uint256 marketIndex, uint256 rewardEarned);

    mapping(address => uint) public rewardPoolShareForMarketCreator;
    uint64 public rewardPoolSharePercForMarketCreator;

    /**
    * @dev Create the market.
    */
    function createMarketWithVariableLiquidity(string memory _questionDetails, uint64[] memory _optionRanges, uint32[] memory _marketTimes,bytes8 _marketType, bytes32 _marketCurr, uint64[] memory _marketInitialLiquidities) public {
      require(!paused);
      address _marketCreator = _msgSender();
      require(whiteListedMarketCreators[_marketCreator] || oneTimeMarketCreator[_marketCreator]);
      delete oneTimeMarketCreator[_marketCreator];
    //   require(_marketInitialLiquidities >= minLiquidityByCreator);
      uint32[] memory _timesArray = new uint32[](_marketTimes.length+1);
      _timesArray[0] = uint32(now);
      _timesArray[1] = _marketTimes[0].sub(uint32(now));
      _timesArray[2] = _marketTimes[1].sub(uint32(now));
      _timesArray[3] = _marketTimes[2];
      uint64 _marketId = allMarkets.getTotalMarketsLength();
      marketData[_marketId].pricingData = PricingData(stakingFactorMinStake, stakingFactorWeightage, timeWeightage, minTimePassed);
      marketData[_marketId].marketCreator = _marketCreator;
      allMarkets.createMarketWithVariableLiquidity(_timesArray, _optionRanges, _marketCreator, _marketInitialLiquidities);

      emit MarketParams(_marketId, _questionDetails, _optionRanges,_marketTimes, stakingFactorMinStake, minTimePassed, _marketCreator, _marketType, _marketCurr);
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

    /**
    * @dev function to get integer parameters
    * @param code Code of the parameter.
    * @return codeVal Code of the parameter.
    * @return value Value of the queried parameter.
    */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value) {
      codeVal = code;
      if(code == "CPW") { // Acyclic contracts don't have Current price weighage but time weightage
        value = timeWeightage;
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
      } else if(code == "MTP") {
        value = minTimePassed;
      } else if(code == "MLC") {
        value = minLiquidityByCreator;
      } else if(code == "RPS") {
      	value = rewardPoolSharePercForMarketCreator;
      }
    }

    /**
    * @dev function to update integer parameters
    * @param code Code of the updating parameter.
    * @param value Value to which the parameter should be updated
    */
    function updateUintParameters(bytes8 code, uint256 value) external onlyAuthorized {
      if(code == "RPS") {
        require(value < 100);
        rewardPoolSharePercForMarketCreator = uint64(value); // no need to handle overflow, we are checking for <100
      } else if(code == "CPW") { // Acyclic contracts don't have Current price weighage but time weightage
        require(value <= 100);
        timeWeightage = uint32(value);
        //Staking factor weightage% = 100% - timeWeightage%
        stakingFactorWeightage = 100 - timeWeightage;
      } else if(code == "SFMS") { // Minimum amount for staking factor to apply
        stakingFactorMinStake = value;
      } else if(code == "MINP") { // Minimum prediction amount
        minPredictionAmount = value;
      } else if(code == "MAXP") { // Maximum prediction amount
        maxPredictionAmount = value;
      } else if(code == "MTP") {
        uint32 _val = uint32(value);
        require(_val == value); // to avoid overflow while type casting
        minTimePassed = _val;
      } else if(code == "MLC") {
        uint64 _val = uint64(value);
        require(_val == value); // to avoid overflow while type casting
        minLiquidityByCreator = _val;
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
     * @dev Gets price for given market and option
     * @param _marketId  Market ID
     * @param _prediction  prediction option
     * @return  option price
     **/
    function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64) {
      uint64 optionPice = super.getOptionPrice(_marketId,_prediction);
      if(optionPice < 1000)
      {
        optionPice = 1000;
      }

      return optionPice;
    }

}
