pragma solidity 0.5.7;

import "./Market.sol";

contract MarketHourly is Market {

    function initiate(
     uint[] memory _uintparams,
     string memory _feedsource,
     address payable[] memory _addressParams
    ) 
    public
    payable
    {
      expireTime = _uintparams[0] + 1 hours;
      super.initiate(_uintparams, _feedsource, _addressParams);
      betType = uint(IPlotus.MarketType.HourlyMarket);
    }

    function getPrice(uint _prediction) public view returns(uint) {
      return optionPrice[_prediction];
    }

    function setPrice(uint _prediction) public {
      optionPrice[_prediction] = _calculateOptionPrice(_prediction, address(this).balance);
    }

    function _calculateOptionPrice(uint _option, uint _totalStaked) internal view returns(uint _optionPrice) {
      _optionPrice = 0;
      if(address(this).balance > 20 ether) {
        _optionPrice = (optionsAvailable[_option].ethStaked).mul(1000000)
                      .div(_totalStaked.mul(40));
      }

      uint distance = _getDistance(_option);
      uint maxDistance = currentPriceLocation > 3? (currentPriceLocation-1): (7-currentPriceLocation);
      uint timeElapsed = now - startTime;
      timeElapsed = timeElapsed > 10 minutes ? timeElapsed: 10 minutes;
      _optionPrice = _optionPrice.add((
              (maxDistance + 1 - distance).mul(1000000).mul(timeElapsed.div(10 minutes))
             )
             .div(
              (maxDistance+1) * 60 * 60
             ));
      _optionPrice = _optionPrice.div(100);
    }
}
