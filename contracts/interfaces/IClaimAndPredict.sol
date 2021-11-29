pragma solidity 0.5.7;

contract IClaimAndPredict {
    function handleReturnClaim(address _user, uint _claimAmount) public returns(uint _finalClaim, uint amountToDeduct);
}