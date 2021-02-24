pragma solidity 0.5.7;

import "../AllMarkets.sol";

contract MockAllMarkets is AllMarkets {

    uint64 public nextOptionPrice;

    function postResultMock(uint _val, uint _marketId) external {
        _postResult(_val, 0 , _marketId);
    } 

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