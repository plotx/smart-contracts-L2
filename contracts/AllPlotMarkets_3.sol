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

import "./AllPlotMarkets_2.sol";

contract AllPlotMarkets_3 is AllPlotMarkets_2 {

    mapping(uint => uint) creatorRewardFromRewadPool;

    function claimReturn(address _user, uint _marketId) internal view returns(uint256, uint256) {

      if(!marketSettleEventEmitted[_marketId]) {
        return (0, 0);
      }
      return (2, getReturn(_user, _marketId));
    }

    function getReturn(address _user, uint _marketId) public view returns (uint returnAmount){
      if(!marketSettleEventEmitted[_marketId] || getTotalPredictionPoints(_marketId) == 0) {
       return (returnAmount);
      }
      uint256 _winningOption = marketDataExtended[_marketId].WinningOption;
      UserData storage _userData = userData[_user];
      returnAmount = _userData.userMarketData[_marketId].predictionData[_winningOption].amountStaked;
      uint256 userPredictionPointsOnWinngOption = _userData.userMarketData[_marketId].predictionData[_winningOption].predictionPoints;
      if(userPredictionPointsOnWinngOption > 0) {
        returnAmount = _addUserReward(_marketId, returnAmount, _winningOption, userPredictionPointsOnWinngOption);
      }
      return returnAmount;
    }

    function _postResult(uint256 _value, uint256 _marketId) internal {
      require(now >= marketSettleTime(_marketId));
      require(_value > 0);
      MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
      if(_marketDataExtended.predictionStatus != PredictionStatus.InDispute) {
        _marketDataExtended.settleTime = uint32(now);
      } else {
        delete _marketDataExtended.settleTime;
      }
      _marketDataExtended.predictionStatus = PredictionStatus.Settled;
      uint32 _winningOption;
      for(uint32 i = 0; i< _marketDataExtended.optionRanges.length;i++) {
        if(_value < _marketDataExtended.optionRanges[i]) {
          _winningOption = i+1;
          break;
        }
      }
      if(_winningOption == 0) {
        _winningOption = uint32(_marketDataExtended.optionRanges.length + 1);
      }
      _marketDataExtended.WinningOption = _winningOption;
      uint64 totalReward = _calculateRewardTally(_marketId, _winningOption);
      (,uint RPS) = IMarket(_marketDataExtended.marketCreatorContract).getUintParameters("RPS");
      uint64 rewardForCreator = 0;
      if(RPS>0)
      {
        rewardForCreator = uint64(RPS).mul(totalReward).div(100);
        creatorRewardFromRewadPool[_marketId] = rewardForCreator;
      }
      _marketDataExtended.rewardToDistribute = totalReward.sub(rewardForCreator);
      emit MarketResult(_marketId, _marketDataExtended.rewardToDistribute, _winningOption, _value);
    }

    function emitMarketSettledEvent(uint256 _marketId) external {
      require(marketStatus(_marketId) == PredictionStatus.Settled);
      require(!marketSettleEventEmitted[_marketId]);
      marketSettleEventEmitted[_marketId] = true;
      uint creatorReward = creatorRewardFromRewadPool[_marketId].mul(10**predictionDecimalMultiplier);
      if(creatorReward>0)
      {
        delete creatorRewardFromRewadPool[_marketId];
        MarketDataExtended storage _marketDataExtended = marketDataExtended[_marketId];
        _transferAsset(plotToken,_marketDataExtended.marketCreatorContract,creatorReward);
        IMarket(_marketDataExtended.marketCreatorContract).setRewardPoolShareForCreator(_marketId, creatorReward);
      }

      emit MarketSettled(_marketId);
    }

    /**
    * @dev Withdraw provided amount of deposited and available prediction token
    * @param _token Amount of prediction token to withdraw
    * @param _maxRecords Maximum number of records to check
    */
    function withdraw(uint _token, uint _maxRecords) public {
      address payable _msgSenderAddress = _msgSender();
      // (uint _tokenLeft, uint _tokenReward) = getUserUnusedBalance(_msgSenderAddress);
      // _tokenLeft = _tokenLeft.add(_tokenReward);
      _withdraw(_token, _maxRecords, 0, _msgSenderAddress);
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
      _transferAsset(predictionToken, _msgSenderAddress, _token);
      emit Withdrawn(_msgSenderAddress, _token, now);
    }

    function _withdrawReward(uint256 maxRecords, address _msgSenderAddress) internal {
      uint256 i;
      UserData storage _userData = userData[_msgSenderAddress];
      uint[] memory _marketsParticipated = _userData.marketsParticipated;
      uint len = _marketsParticipated.length;
      uint count;
      uint tokenReward =0;
      uint lastClaimedIndex = _userData.lastClaimedIndex;
      require(!marketCreationPaused);

      uint tempArrayCount;
      if(lastClaimedIndex == 0) {
        tempArrayCount = len;
      } else {
        tempArrayCount = _marketsParticipated[len -1] - _marketsParticipated[lastClaimedIndex];
      }
      // uint tempArrayLength = len < tempArrayCount? len: tempArrayCount;
      uint[] memory unsettledMarkets =  new uint[](tempArrayCount);
      //tempArrayCount will now act as a counter for temporary array i.e: unsettledMarkets;
      tempArrayCount = 0;
      for(i = lastClaimedIndex; i < len && count < maxRecords; i++) {
        (uint claimed, uint tempTokenReward) = claimReturn(_msgSenderAddress, _marketsParticipated[i]);
        if(claimed > 0) {
          tokenReward = tokenReward.add(tempTokenReward);
          count++;
        } else {
          if(_marketsParticipated[i] > 0) {
            unsettledMarkets[tempArrayCount] = _marketsParticipated[i];
            tempArrayCount++;
          }
        }
      }
      delete _userData.marketsParticipated;
      delete _userData.lastClaimedIndex;
      _userData.marketsParticipated = unsettledMarkets;
      if(unsettledMarkets.length != tempArrayCount) {
        _userData.marketsParticipated.length = tempArrayCount;
      }
      emit ReturnClaimed(_msgSenderAddress, tokenReward);
      _userData.unusedBalance = _userData.unusedBalance.add(tokenReward.mul(10**predictionDecimalMultiplier));
    }

}
