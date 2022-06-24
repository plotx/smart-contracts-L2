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

import "./AllPlotMarkets_10.sol";

contract AllPlotMarkets_11 is AllPlotMarkets_10 {

    mapping(address=>bool) public authorizedRelayer;

    /**
    * @dev Set/Remove authorized relayer address
    * @param _relayer Authorized relayer address
    * @param _flag True to add authorized relayer, false to remove aithorized relayer address
    */
    function toggleAuthorizedRelayer(address _relayer, bool _flag) public onlyAuthorized {
        authorizedRelayer[_relayer] = _flag;
    }
    
    /**
    * @dev Place prediction on the available options of the market.
    * @param _marketId Index of the market
    * @param _asset The asset used by user during prediction whether it is prediction token address or in Bonus token.
    * @param _predictionStake The amount staked by user at the time of prediction.
    * @param _prediction The option on which user placed prediction.
    * _predictionStake should be passed with 8 decimals, reduced it to 8 decimals to reduce the storage space of prediction data
    */
    function _placePrediction(uint _marketId, address _msgSenderAddress, address _asset, uint64 _predictionStake, uint256 _prediction) internal {
      address _relayer = tx.origin;
      require(now >= marketBasicData[_marketId].startTime && (now <= marketExpireTime(_marketId) || (authorizedRelayer[_relayer] && now <= marketSettleTime(_marketId))));
      if(userData[_msgSenderAddress].marketsParticipated.length > maxPendingClaims) {
        _withdrawReward(defaultMaxRecords, _msgSenderAddress);
      }

      uint64 _predictionStakePostDeduction = _predictionStake;
      uint decimalMultiplier = 10**predictionDecimalMultiplier;
      UserData storage _userData = userData[_msgSenderAddress];
      if(_asset == predictionToken) {
        uint256 unusedBalance = _userData.unusedBalance;
        unusedBalance = unusedBalance.div(decimalMultiplier);
        if(_predictionStake > unusedBalance)
        {
          _withdrawReward(defaultMaxRecords, _msgSenderAddress);
          unusedBalance = _userData.unusedBalance;
          unusedBalance = unusedBalance.div(decimalMultiplier);
        }
        require(_predictionStake <= unusedBalance);
        _userData.unusedBalance = (unusedBalance.sub(_predictionStake)).mul(decimalMultiplier);
      } else {
        require(_asset == address(bPLOTInstance));
        require(!_userData.userMarketData[_marketId].predictedWithBlot);
        _userData.userMarketData[_marketId].predictedWithBlot = true;
        bPLOTInstance.convertToPLOT(_msgSenderAddress, address(this), (decimalMultiplier).mul(_predictionStake));
        _asset = plotToken;
      }
      _predictionStakePostDeduction = _deductFee(_marketId, _predictionStake, _msgSenderAddress);
      
      uint64 predictionPoints = IMarket(marketDataExtended[_marketId].marketCreatorContract).calculatePredictionPointsAndMultiplier(_msgSenderAddress, _marketId, _prediction, _predictionStakePostDeduction);
      require(predictionPoints > 0);

      _storePredictionData(_marketId, _prediction, _msgSenderAddress, _predictionStakePostDeduction, predictionPoints);
      emit PlacePrediction(_msgSenderAddress, _predictionStake, predictionPoints, _asset, _prediction, _marketId);
  
    }
}