pragma solidity 0.5.7;

contract IMaster {
    function authorized() public view returns(address);
    function dAppToken() public view returns(address);
    function isInternal(address _address) public view returns(bool);
    function getLatestAddress(bytes2 _module) public view returns(address);
    function isAuthorizedToGovern(address _toCheck) public view returns(bool);
    function withdrawForDRVotingRewards(uint _amount) external;
}