pragma solidity 0.5.7;

contract IMarket {
  function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64);
  function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value);
  function depositMarketCreationReward(uint256 _marketId, uint256 _creatorFee) external;
  function handleFee(uint _marketId, uint64 _cummulativeFee, address _msgSenderAddress, address _relayer) external;
  function calculatePredictionPointsAndMultiplier(address _user, uint256 _marketId, uint256 _prediction, uint64 _stake) external returns(uint64 predictionPoints);
}
