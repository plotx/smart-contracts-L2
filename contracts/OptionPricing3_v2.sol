pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/logOperations/LogarithmLib.sol";
import "./interfaces/IOptionPricing.sol";
import "./interfaces/IAllMarkets.sol";

contract OptionPricing3_v2 is IOptionPricing {
    using SafeMath32 for uint32;
    using SafeMath64 for uint64;
    using SafeMath128 for uint128;
    using SafeMath for uint;

    uint internal constant _optionLength = 3;
    uint internal constant vopUpperBoundary = 98; // With 2 decimals
    uint internal constant vopLowerBoundary = 2; // With 2 decimals

    function optionLength() public view returns(uint) {
      return _optionLength;
    }

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

        // uint _stakeOnOppOption = _optionPricingParams[1].sub(_optionPricingParams[0]);
        // uint _tso = ;
        // uint _pa = _marketPricingData[4].mul(1e16);
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
        int256 _logOperation = LogarithmLib.ln(int256(_tso.add(_pa))) - LogarithmLib.ln(int256(_tso));
        uint64 _logOutput = uint64(_logOperation/1e16);
        // uint _operation_2 = _stakeOnOppOption.mul(_logOutput).div(1e8);
        uint _operation_2 = _predictionAmount + _stakeOnOppOption.mul(_logOutput).div(1e8);
        uint vop = _predictionAmount.mul(1e5)/_operation_2;
        vop = vop.add(vopLowerBoundary);
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