pragma solidity 0.5.7;

contract IMarketCreationRewards {

    function updateMarketCreationData(address _createdBy, uint64 _marketId) external;    

    // function depositMarketRewardPoolShare(uint256 _marketId, uint256 _plotShare, uint64 _plotDeposit) external payable;
    function depositMarketCreationReward(uint256 _marketId, uint256 _creatorFee) external payable;

    function returnMarketRewardPoolShare(uint256 _marketId) external;

    function getMarketCreatorRPoolShareParams(uint256 _market, uint256 plotStaked) external view returns(uint16, bool);

    function transferAssets(address _asset, address _to, uint _amount) external;

}
