pragma solidity 0.5.7;

contract IAllCurrencyMarkets {

	enum PredictionStatus {
      Live,
      InSettlement,
      Cooling,
      InDispute,
      Settled
    }

    uint public nextCurrencyIndex;
    mapping(address => uint) public currencyIndex;

    struct PredictionCurrency {
      address token;
      address _priceFeed;
    }

    function createMarket(uint32[] memory _marketTimes, uint64[] memory _optionRanges, address _createdBy, uint64 _initialLiquidity, uint _predictionCurrencyIndex) public returns(uint64 _marketIndex);

    function settleMarket(uint256 _marketId, uint256 _value) external;

    function addInitialAuthorizedAddress(address _address) external;

    function getTotalMarketsLength() external view returns(uint64);

    function getTotalPredictionPoints(uint _marketId) public view returns(uint64 predictionPoints);

    function getUserPredictionPoints(address _user, uint256 _marketId, uint256 _option) external view returns(uint64);

    function marketStatus(uint256 _marketId) public view returns(PredictionStatus);

    function marketSettleTime(uint256 _marketId) public view returns(uint32);

    function getTotalStakedValueInPLOT(uint256 _marketId) public view returns(uint256);

    function getTotalStakedWorthInPLOT(uint256 _marketId) public view returns(uint256 _tokenStakedWorth);

    function getMarketOptionPricingParams(uint _marketId, uint _option) public view returns(uint[] memory,uint32);

    function getMarketData(uint256 _marketId) external view returns
       (uint64[] memory _optionRanges, /*uint[] memory _tokenStaked,*/uint _predictionTime,uint _expireTime, PredictionStatus _predictionStatus);
 
    function setMarketStatus(uint256 _marketId, PredictionStatus _status) public;
 
    function postMarketResult(uint256 _marketId, uint256 _marketSettleValue) external;

    function getTotalOptions(uint256 _marketId) external view returns(uint);
 
    // function getTotalStakedByUser(address _user) external view returns(uint);

    mapping(uint => PredictionCurrency) public predictionCurrencies;
}
