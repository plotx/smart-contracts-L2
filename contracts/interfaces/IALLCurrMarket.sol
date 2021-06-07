pragma solidity 0.5.7;

contract IALLCurrMarket {
  function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64);
  function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value);
  function handleFee(uint _marketId, uint64 _cummulativeFee, address _msgSenderAddress, address _relayer,address _asset) external;
  function calculatePredictionPointsAndMultiplier(address _user, uint256 _marketId, uint256 _prediction, uint64 _stake, address _asset) external returns(uint64 predictionPoints);
}
