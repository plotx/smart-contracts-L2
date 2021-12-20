pragma solidity 0.5.7;

import "../AllPlotMarkets_8.sol";

contract MockAllMarkets_8 is AllPlotMarkets_8 {

    function postResultMock(uint _val, uint _marketId) external {
        _postResult(_val, _marketId);
    } 


}