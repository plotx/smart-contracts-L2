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
  uint internal constant vopUpperBoundary = 98; // With 2 decimals
  uint internal constant vopLowerBoundary = 2; // With 2 decimals

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
    return _optionPriceInternal(_optionPricingParams[0].mul(1e16), _marketPricingData[4].mul(1e16), _optionPricingParams[1].sub(_optionPricingParams[0]), _marketPricingData[4]);
  }

  /**
    * @dev Gets price for given market and option
    * @param _tso Total Staked on selected option raised by 24 decimals
    * @param _pa Prediction amount raised by 24 decimals
    * @param _stakeOnOppOption Total staked on rest of the options with 8 decimals
    * @param _predictionAmount Prediction amount with 8 decimals
    * @return  Array consist of Max Distance between current option and any option, predicting Option distance from max distance, cummulative option distance
    **/
  function _optionPriceInternal(uint _tso, uint _pa, uint _stakeOnOppOption, uint _predictionAmount) internal pure returns(uint64) {
    // log operation : ln(1+_tso/_pa)
    // Simplified to ln(_tso+_pa)-ln(_tso)
    int256 _logOperation = LogarithmLib.ln(int256(_tso.add(_pa))) - LogarithmLib.ln(int256(_tso));
    uint64 _logOutput = uint64(_logOperation/1e16);
    // Operation 2: _predictionAmount + _stake on opposite option * logOperation
    uint _operation_2 = _predictionAmount + _stakeOnOppOption.mul(_logOutput).div(1e8);
    // VOP: _predictionAmount/(Operation 2), Added 5 decimals
    uint vop = _predictionAmount.mul(1e5)/_operation_2;
    // VOP: VOP+=0.02
    vop = vop.add(vopLowerBoundary);
    // VOP: if vop > 0.98=>vop=0.98
    if(vop > vopUpperBoundary) {
        vop = vopUpperBoundary;
    }
    return uint64(vop);
  }

  /**
  * @dev Internal function to perfrom ceil operation of given params
  */
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
      return ((a + m - 1) / m) * m;
  }
}