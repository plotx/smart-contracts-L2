/* Copyright (C) 2020 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IAllMarkets.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IAuth.sol";

contract UserLevels is IAuth {

    event UserLevelLog(address userAddress, uint256 userLevel, uint256 timeStamp);
    event LevelMultiplierLog(uint256[] userLevel, uint256[] multiplier, uint256 timeStamp);

    address public masterAddress;

    mapping(address => uint256) public userLevel;
    mapping(uint256 => uint256) public levelMultiplier;

    /**
     * @dev Initialize the dependencies
     * @param _masterAddress Master address of the PLOT platform.
     */
    constructor(address _masterAddress) public {
      IMaster ms = IMaster(_masterAddress);
      authorized = ms.authorized();
      masterAddress = _masterAddress;
    }

    /**
    * @dev Function to set `_user` level for prediction points multiplier
    * @param _user User address
    * @param _level user level indicator
    */
    function setUserLevel(address _user, uint256 _level) public onlyAuthorized {
      // Can set level to zero or a level that has multiplier set
      require(_level ==0 || levelMultiplier[_level] > 0);
      userLevel[_user] = _level;
      emit UserLevelLog(_user, _level, now);
    }

    /**
    * @dev Function to set multiplier per level (With 2 decimals)
    * @param _userLevels Array of levels
    * @param _multipliers Array of corresponding multipliers
    */
    function setMultiplierLevels(uint256[] memory _userLevels, uint256[] memory _multipliers) public onlyAuthorized {
      require(_userLevels.length == _multipliers.length);
      for(uint256 i = 0; i < _userLevels.length; i++) {
        levelMultiplier[_userLevels[i]] = _multipliers[i];
      }
      emit LevelMultiplierLog(_userLevels, _multipliers, now);
    }

    /**
    * @dev Get level of the user and the corresponding multiplier fo the level
    * @param _user Address of the user
    */
    function getUserLevelAndMultiplier(address _user) external view returns(uint256 _userLevel, uint256 _multiplier) {
      return (userLevel[_user], levelMultiplier[userLevel[_user]]);
    }

}