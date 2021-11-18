pragma solidity 0.5.7;

import "../CyclicMarkets_4.sol";

contract MockCyclicMarkets_4 is CyclicMarkets_4 {

    uint64 public nextOptionPrice;

    function setNextOptionPrice(uint64 _price) public {
        nextOptionPrice = _price;
    }

    function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64 _optionPrice) {
        if(nextOptionPrice !=0) {
            return nextOptionPrice;
        }
        else  {
            return super.getOptionPrice(_marketId, _prediction);
        }
    }

     /**
     * @dev Gets price for all the options in a market
     * @param _marketId  Market ID
     * @return _optionPrices array consisting of prices for all available options
     **/
    function getAllOptionPrices(uint _marketId) external view returns(uint64[] memory _optionPrices) {
      _optionPrices = new uint64[](3);
      for(uint i=0; i< 3; i++) {
        _optionPrices[i] = getOptionPrice(_marketId,i+1);
      }

    }
}