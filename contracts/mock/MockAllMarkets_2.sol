pragma solidity 0.5.7;

import "../upgrades/AllPlotMarkets/AllPlotMarkets_2.sol";

contract MockAllMarkets_2 is AllPlotMarkets_2 {

    function postResultMock(uint _val, uint _marketId) external {
        _postResult(_val, _marketId);
    } 


}