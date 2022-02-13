pragma solidity 0.5.7;

import "../upgrades/AcyclicMarkets/AcyclicMarkets_2.sol";

contract MockAcyclicMarkets_2 is AcyclicMarkets_2 {

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