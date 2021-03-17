pragma solidity 0.5.7;

contract IReferral {
    
    function setReferralRewardData(address _referee, address _token, uint _referrerFee, uint _refereeFee) external;

}