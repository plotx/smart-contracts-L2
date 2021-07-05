pragma solidity 0.5.7;

import "../AllPlotMultiCurrMarkets.sol";

contract MockAllCurrMarkets is AllPlotMultiCurrMarkets {

    function postResultMock(uint _val, uint _marketId) external {
        _postResult(_val, _marketId);
    } 


}