pragma solidity 0.5.7;

import "../upgrades/AllPlotMarkets/AllPlotMarkets_3.sol";

contract MockAllMarkets_3 is AllPlotMarkets_3 {

    function postResultMock(uint _val, uint _marketId) external {
        _postResult(_val, _marketId);
    } 


}