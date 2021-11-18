pragma solidity 0.5.7;

import "../AllPlotMarkets_6.sol";

contract MockAllMarkets_6 is AllPlotMarkets_6 {

    function postResultMock(uint _val, uint _marketId) external {
        _postResult(_val, _marketId);
    } 


}