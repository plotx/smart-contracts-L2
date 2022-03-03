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

import "../../external/openzeppelin-solidity/math/SafeMath.sol";
import "../../external/proxy/OwnedUpgradeabilityProxy.sol";
import "../../interfaces/IMaster.sol";
import "../../interfaces/IAllMarkets.sol";
import "../../interfaces/IToken.sol";
import "../../interfaces/IAuth.sol";

contract UserLevels2 is IAuth {

    event UserLevelLog(address userAddress, uint256 userLevel, uint256 timeStamp);
    event LevelPerksLog(uint256 userLevel, uint256 multiplier, uint256 fee, uint256 timeStamp);

    struct LevelPerks {
        uint64 multiplier;
        uint64 feeDiscount; //With 2 decimals
    }

    address public masterAddress;

    mapping(address => uint256) public userLevel;
    mapping(uint256 => LevelPerks) public levelMultiplier;

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
      require(_level ==0 || levelMultiplier[_level].multiplier > 0 || levelMultiplier[_level].feeDiscount > 0);
      userLevel[_user] = _level;
      emit UserLevelLog(_user, _level, now);
    }

    /**
    * @dev Function to set multiplier per level (With 2 decimals)
    * @param _userLevels Array of levels
    * @param _multipliers Array of corresponding multipliers
    * @param _feeDiscountArray Array of corresponding fee discounts
    */
    function setMultiplierLevels(uint256[] memory _userLevels, uint64[] memory _multipliers, uint64[] memory _feeDiscountArray) public onlyAuthorized {
      require(_userLevels.length == _multipliers.length);
      for(uint256 i = 0; i < _userLevels.length; i++) {
        levelMultiplier[_userLevels[i]] = LevelPerks(_multipliers[i], _feeDiscountArray[i]);
        emit LevelPerksLog(_userLevels[i], _multipliers[i], _feeDiscountArray[i], now);
      }
    }

    /**
    * @dev Get level of the user and the corresponding multiplier fo the level
    * @param _user Address of the user
    */
    function getUserLevelAndPerks(address _user) external view returns(uint256 _userLevel, uint64 _multiplier, uint64 _feeDiscount) {
      _userLevel = userLevel[_user];
      return (_userLevel, levelMultiplier[_userLevel].multiplier, levelMultiplier[_userLevel].feeDiscount);
    }

}