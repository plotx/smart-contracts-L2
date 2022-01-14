pragma solidity 0.5.7;

contract IAllMarkets {

	enum PredictionStatus {
      Live,
      InSettlement,
      Cooling,
      InDispute,
      Settled
    }

    function createMarket(uint32[] memory _marketTimes, uint64[] memory _optionRanges, address _createdBy, uint64 _initialLiquidity) public returns(uint64 _marketIndex);

    function createMarketWithVariableLiquidity(uint32[] memory _marketTimes, uint64[] memory _optionRanges, address _marketCreator, uint64[] memory _initialLiquidities) 
    public 
    returns(uint64 _marketIndex);

    function settleMarket(uint256 _marketId, uint256 _value) external;

    function addInitialAuthorizedAddress(address _address) external;

    function getTotalMarketsLength() external view returns(uint64);

    function getTotalPredictionPoints(uint _marketId) public view returns(uint64 predictionPoints);

    function getUserPredictionPoints(address _user, uint256 _marketId, uint256 _option) external view returns(uint64);

    function marketStatus(uint256 _marketId) public view returns(PredictionStatus);

    function marketSettleTime(uint256 _marketId) public view returns(uint32);

    function burnDisputedProposalTokens(uint _proposaId) external;

    function getTotalStakedValueInPLOT(uint256 _marketId) public view returns(uint256);

    function getTotalStakedWorthInPLOT(uint256 _marketId) public view returns(uint256 _tokenStakedWorth);

    function getMarketCurrencyData(bytes32 currencyType) external view returns(address);

    function getMarketOptionPricingParams(uint _marketId, uint _option) public view returns(uint[] memory,uint32);

    function getMarketData(uint256 _marketId) external view returns
       (uint64[] memory _optionRanges, uint[] memory _tokenStaked,uint _predictionTime,uint _expireTime, PredictionStatus _predictionStatus);
 
    function setMarketStatus(uint256 _marketId, PredictionStatus _status) public;
 
    function postMarketResult(uint256 _marketId, uint256 _marketSettleValue) external;

    function getTotalOptions(uint256 _marketId) external view returns(uint);
 
    function getTotalStakedByUser(address _user) external view returns(uint);

    function depositAndPredictFor(address _predictFor, uint _tokenDeposit, uint _marketId, address _asset, uint256 _prediction, uint64 _plotPredictionAmount, uint64 _bPLOTPredictionAmount) external;

    function setClaimFlag(address _user, uint _userNonce) public;

    function getNonce(address user) public view returns (uint256 nonce);
}
