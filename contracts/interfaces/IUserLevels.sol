pragma solidity 0.5.7;

contract IUserLevels {
    function getUserLevelAndMultiplier(address _user) external view returns(uint256 _userLevel, uint256 _multiplier);
}