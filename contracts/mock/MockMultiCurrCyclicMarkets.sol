pragma solidity 0.5.7;

import "../CyclicMarketsMultiCurrency.sol";

contract MockMultiCurrCyclicMarkets is CyclicMarketsMultiCurr {

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
}