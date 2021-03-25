pragma solidity 0.5.7;

import "../AllPlotMarkets.sol";

contract MockAllMarkets is AllPlotMarkets {

    function postResultMock(uint _val, uint _marketId) external {
        _postResult(_val, _marketId);
    } 


}