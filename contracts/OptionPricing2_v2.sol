pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/logOperations/LogarithmLib.sol";
import "./interfaces/IOptionPricing.sol";
import "./interfaces/IAllMarkets.sol";

contract OptionPricing2_v2 is IOptionPricing {
  using SafeMath32 for uint32;
  using SafeMath64 for uint64;
  using SafeMath128 for uint128;
  using SafeMath for uint;

  uint internal constant _optionLength = 2;

  function optionLength() public view returns(uint) {
    return _optionLength;
  }

  function calculateOptionRanges(uint currentPrice, uint _optionRangePerc, uint64 _decimals, uint8 _roundOfToNearest) public pure returns(uint64[] memory _optionRanges) {
    _optionRanges = new uint64[](_optionLength - 1);
    uint _option = (ceil(currentPrice.div(_roundOfToNearest), 10**_decimals)).mul(_roundOfToNearest);
    require(_option == uint64(_option), "Uint 64 Overflow");
    _optionRanges[0] = uint64(_option);
  }

  /**
    * @dev Gets price for given market and option
    * @param _prediction  prediction option
    * @return  option price
    **/
  function getOptionPrice(uint _marketId, uint _currentPrice, uint _prediction, uint[] memory _marketPricingData, address _allMarketsAddress) public view returns(uint64 _optionPrice) {
    IAllMarkets allMarkets = IAllMarkets(_allMarketsAddress); 
    (uint[] memory _optionPricingParams,) = allMarkets.getMarketOptionPricingParams(_marketId,_prediction);
    // For initial predictions
    if(_optionPricingParams[0] == 0)
    {

      return uint64(uint(100000).div(_optionLength));

    }
    //  else {
    //   uint _value = uint(100000).mul(_optionPricingParams[0]).div(_optionPricingParams[1]);
    //   require(_value == uint64(_value), "Uint 64 Overflow");
    //   return uint64(_value);
    // }

    uint _stakeOnOppOption = _optionPricingParams[1].sub(_optionPricingParams[0]);
    uint _tso = _optionPricingParams[0].mul(1e16);
    uint _pa = _marketPricingData[4].mul(1e16);
    int256 _logOperation = LogarithmLib.ln(int256(_tso.add(_pa))) - LogarithmLib.ln(int256(_tso));
    uint64 _logOutput = uint64(_logOperation/1e16);
    // uint _operation_2 = _stakeOnOppOption.mul(_logOutput).div(1e8);
    return uint64(_marketPricingData[4] + _stakeOnOppOption.mul(_logOutput).div(1e8));
  }

  /**
  * @dev Internal function to perfrom ceil operation of given params
  */
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
      return ((a + m - 1) / m) * m;
  }
}