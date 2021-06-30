pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./interfaces/IOptionPricing.sol";
import "./interfaces/IAllMarkets.sol";

contract OptionPricing3 is IOptionPricing {
    using SafeMath32 for uint32;
    using SafeMath64 for uint64;
    using SafeMath128 for uint128;
    using SafeMath for uint;

    uint public constant OptionLength = 3;

    function calculateOptionRanges(uint currentPrice, uint _optionRangePerc, uint64 _decimals, uint8 _roundOfToNearest) public pure returns(uint64[] memory _optionRanges) {
        uint optionRangePerc = currentPrice.mul(_optionRangePerc.div(2)).div(10000);
        _optionRanges = new uint64[](2);
        _optionRanges[0] = uint64((ceil(currentPrice.sub(optionRangePerc).div(_roundOfToNearest), 10**_decimals)).mul(_roundOfToNearest));
        _optionRanges[1] = uint64((ceil(currentPrice.add(optionRangePerc).div(_roundOfToNearest), 10**_decimals)).mul(_roundOfToNearest));
    }

    /**
     * @dev Gets price for given market and option
     * @param _prediction  prediction option
     * @return  option price
     **/
    function getOptionPrice(uint _marketId, uint _currentPrice, uint _prediction, uint[] memory _marketPricingData, address _allMarketsAddress) public view returns(uint64) {
      IAllMarkets allMarkets = IAllMarkets(_allMarketsAddress); 
      (uint64[] memory _optionRanges,, uint _predictionTime,,) = allMarkets.getMarketData(_marketId);
      (uint[] memory _optionPricingParams, uint32 _startTime) = allMarkets.getMarketOptionPricingParams(_marketId,_prediction);
      uint stakingFactorConst;
      uint optionPrice; 
      uint256 totalStaked = _optionPricingParams[1];
      // Checking if current stake in market reached minimum stake required for considering staking factor.
      if(totalStaked > _marketPricingData[0])
      {
        // 10000 / staking weightage
        stakingFactorConst = uint(10000).div(_marketPricingData[1]); 
        // (stakingFactorConst x Amount staked in option x 10^18) / Total staked in market --- (1)
        optionPrice = (stakingFactorConst.mul(_optionPricingParams[0]).mul(10**18).div(totalStaked)); 
      }
      uint timeElapsed = uint(now).sub(_startTime);
      // max(timeElapsed, minTimePassed)
      if(timeElapsed < _marketPricingData[3]) {
        timeElapsed = _marketPricingData[3];
      }
      uint[] memory _distanceData = getOptionDistanceData(_currentPrice,_prediction, _optionRanges);

      // (Time Elapsed x 10000) / ((Max Distance + 1) x currentPriceWeightage)
      uint timeFactor = timeElapsed.mul(10000).div((_distanceData[0].add(1)).mul(_marketPricingData[2]));

      uint totalTime = _predictionTime;
      // (1) + ((Option Distance from max distance + 1) x timeFactor x 10^18 / Total Prediction Time)  -- (2)
      optionPrice = optionPrice.add((_distanceData[1].add(1)).mul(timeFactor).mul(10**18).div(totalTime));  
      // (2) / ((stakingFactorConst x 10^13) + timeFactor x 10^13 x (cummulative option distaance + 3) / Total Prediction Time)
      optionPrice = optionPrice.div(stakingFactorConst.mul(10**13).add(timeFactor.mul(10**13).mul(_distanceData[2].add(3)).div(totalTime)));

      // option price for `_prediction` in 10^5 format
      return uint64(optionPrice);

    }

    /**
     * @dev Gets price for given market and option
     * @param _prediction  prediction option
     * @return  Array consist of Max Distance between current option and any option, predicting Option distance from max distance, cummulative option distance
     **/
    function getOptionDistanceData(uint _currentPrice, uint _prediction,uint64[] memory _optionRanges) internal pure returns(uint[] memory) {
      // [0]--> Max Distance between current option and any option, (For 3 options, if current option is 2 it will be `1`. else, it will be `2`) 
      // [1]--> Predicting option distance from Max distance, (MaxDistance - | currentOption - predicting option |)
      // [2]--> sum of all possible option distances,  
      uint[] memory _distanceData = new uint256[](3); 

      _distanceData[0] = 2;
      // current option based on current price
      uint currentOption;
      _distanceData[2] = 3;
      if(_currentPrice < _optionRanges[0])
      {
        currentOption = 1;
      } else if(_currentPrice > _optionRanges[1]) {
        currentOption = 3;
      } else {
        currentOption = 2;
        _distanceData[0] = 1;
        _distanceData[2] = 1;
      }

      // MaxDistance - | currentOption - predicting option |
      _distanceData[1] = _distanceData[0].sub(modDiff(currentOption,_prediction)); 
      return _distanceData;
    }

    /**
     * @dev  Calculates difference between `a` and `b`.
     **/
    function modDiff(uint a, uint b) internal pure returns(uint) {
      if(a>b)
      {
        return a.sub(b);
      } else {
        return b.sub(a);
      }
    }

    /**
    * @dev Internal function to perfrom ceil operation of given params
    */
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }
}