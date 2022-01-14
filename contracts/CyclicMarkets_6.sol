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

import "./CyclicMarkets_5.sol";

contract CyclicMarkets_6 is CyclicMarkets_5 {

  mapping (bytes32=>bool) internal signatureUsed;

  address public authToPostOptionPrice; // Authorized address to post the option price

  /**
  * @dev Update the authorized address to settle markets
  * @param _newAuth Address to update
  */
  function changeOptionPriceAuthAddress(address _newAuth) external onlyAuthorized {
    require(_newAuth != address(0));
    authToPostOptionPrice = _newAuth;
  }

  function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public {
      revert("DEPR");
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

  function _updateMarketIndexesAndEmitEvent(uint _marketTypeIndex, uint _marketCurrencyIndex, uint64 _marketIndex, address _msgSenderAddress, bytes32 _currencyName, uint32 _minTimePassed) internal {
    MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
    (_marketCreationData.penultimateMarket, _marketCreationData.latestMarket) =
      (_marketCreationData.latestMarket, _marketIndex);
    emit MarketParams(_marketIndex, _msgSenderAddress, _marketTypeIndex, _currencyName, 0,0,0,0);
  }

  function calculateFeeAndPositions(address _user, uint256 _marketId, uint256 _prediction, uint64 _stake, uint32 _startTime, uint64 optionPrice, bytes calldata signature)
   external
   onlyAllMarkets
   returns(uint64 predictionPoints, uint64 predictionAmount, uint64 fee) {
    verifySign(_user, _marketId, _prediction, _stake, optionPrice, signature);
    signatureUsed[keccak256(abi.encodePacked(signature))] = true;
    address _relayer;
     if(_user != tx.origin) {
       _relayer = tx.origin;
     } else {
       _relayer = _user;
     }
    fee = _handleFee(_marketId, _stake, _user, _relayer);
    predictionAmount = _stake.sub(fee);
    predictionPoints = _calculatePredictionPointsAndMultiplier(_user, _marketId, predictionAmount, _startTime, optionPrice);
  }

  /** 
     * @dev Verifies signature.
     */ 
    function verifySign(
        address _user,
        uint256 _marketId,
        uint256 _prediction,
        uint64 _stake,
        uint64 optionPrice,
        bytes memory signature
    ) 
        internal
        view
        returns(bool)
    {
        bytes32 _hash = keccak256(
            abi.encodePacked(
                _user,
                _marketId,
                _prediction,
                _stake,
                optionPrice,
                allMarkets.getNonce(_user)
            )
        );
        uint8 v; bytes32 r; bytes32 s;
        require(signature.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(signature, 32))
            // second 32 bytes.
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(signature, 96)))
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _hash));
        address signer = ecrecover(prefixedHash, v, r, s);
        return (signer == authToPostOptionPrice);
        // return isValidSignature(hash, signature);
    }

    // /**
    //  * @dev Verifies signature.
    //  * @param _hash order hash
    //  */  
    // function isValidSignature(bytes32 _hash, bytes memory signature) internal view returns(bool) {
      
    // }

  /**
    * @dev Internal function to deduct fee from the prediction amount
    * @param _marketId Index of the market
    * @param _cummulativeFee Total fee amount
    * @param _msgSenderAddress User address
    */
  function _handleFee(uint _marketId, uint64 predictionAmount, address _msgSenderAddress, address _relayer) internal returns(uint64 _cummulativeFee) {
    MarketFeeParams storage _marketFeeParams = marketFeeParams;
      // _fee = _calculateAmulBdivC(uint64(_cummulativeFeePercent), _amount, 10000);
    _cummulativeFee = _calculateAmulBdivC(_marketFeeParams.cummulativeFeePercent, predictionAmount, 10000);
    uint64 _referrerFee = _calculateAmulBdivC(_marketFeeParams.referrerFeePercent, _cummulativeFee, 10000);
    uint64 _refereeFee = _calculateAmulBdivC(_marketFeeParams.refereeFeePercent, _cummulativeFee, 10000);
    bool _isEligibleForReferralReward;
    if(address(referral) != address(0)) {
    _isEligibleForReferralReward = referral.setReferralRewardData(_msgSenderAddress, plotToken, _referrerFee, _refereeFee);
    }
    if(_isEligibleForReferralReward){
      // referralReward =  referralReward + (10**predictionDecimalMultiplier).mul(_referrerFee.add(_refereeFee));
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

  /**
  * @dev Internal function to calculate prediction points  and multiplier
  * @param _user User Address
  * @param _marketId Index of the market
  * @param _stake Amount staked by the user
  */
  function _calculatePredictionPointsAndMultiplier(address _user, uint256 _marketId, uint64 _stake, uint _startTime, uint64 optionPrice) internal returns(uint64 predictionPoints){
    bool isMultiplierApplied;
    (predictionPoints, isMultiplierApplied) = _calculatePositions(_marketId, _user, multiplierApplied[_user][_marketId], _stake, _startTime, optionPrice);
    if(isMultiplierApplied) {
      multiplierApplied[_user][_marketId] = true; 
    }
  }

  /**
  * @dev Internal function to calculate prediction points
  * @param _marketId Index of the market
  * @param _user User Address
  * @param _multiplierApplied Flag defining if user had already availed multiplier
  * @param _predictionStake Amount staked by the user
  */
  function _calculatePositions(uint _marketId, address _user, bool _multiplierApplied, uint _predictionStake, uint _startTime, uint64 optionPrice) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
    (predictionPoints, isMultiplierApplied) = _calculatePredictionPoints(_user, _multiplierApplied, _predictionStake, optionPrice);
    uint _marketType = marketData[_marketId].marketTypeIndex;
    EarlyParticipantMultiplier memory _multiplierData = earlyParticipantMultiplier[_marketType];
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
  * @dev Internal function to calculate prediction points
  * @param _user User Address
  * @param _multiplierApplied Flag defining if user had already availed multiplier
  * @param _predictionStake Amount staked by the user
  */
  function _calculatePredictionPoints(address _user, bool _multiplierApplied, uint _predictionStake, uint64 _optionPrice) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
    uint _stakeValue = _predictionStake.mul(1e10);
    if(_stakeValue < minPredictionAmount || _stakeValue > maxPredictionAmount) {
      return (0, isMultiplierApplied);
    }
    // uint64 _optionPrice = getOptionPrice(_marketId, _prediction);
    predictionPoints = uint64(_predictionStake).div(_optionPrice);
    if(!_multiplierApplied || (initialPredictionFlag)) {
      uint256 _predictionPoints = predictionPoints;
      if(address(userLevels) != address(0)) {
        (_predictionPoints, isMultiplierApplied) = checkMultiplier(_user,  predictionPoints);
      }
      predictionPoints = uint64(_predictionPoints);
    }
  }

  function calculatePredictionPointsAndMultiplier(address _user, uint256 _marketId, uint256 _prediction, uint64 _stake) external returns(uint64 predictionPoints){
      revert("DEPR");
  }

  function calculatePredictionPoints(uint _marketId, uint256 _prediction, address _user, bool _multiplierApplied, uint _predictionStake) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
      revert("DEPR");
  }

  /**
    * @dev Gets price for all the options in a market
    * @param _marketId  Market ID
    * @return _optionPrices array consisting of prices for all available options
    **/
  function getAllOptionPrices(uint _marketId) external view returns(uint64[] memory _optionPrices) {
      revert("DEPR");
  }

  /**
  * @dev Gets price for given market and option
  * @param _marketId  Market ID
  * @param _prediction  prediction option
  * @return  option price
  **/
  function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64) {
      revert("DEPR");
  }
}
