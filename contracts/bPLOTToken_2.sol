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

import "./bPLOTToken.sol";

contract BPLOT_2 is BPLOT {

    event BurntUnusedbPLOT(address indexed userAddress, uint256 burntAmount);

    address public ecosystemAddress;
    address public authToBurnbPLOT;

    modifier onlyAuthorized {
        require(msg.sender == ms.authorized());
        _;
    }

    function setEcoSystemAddres(address _ecosystemAddress) public onlyAuthorized {
        require(_ecosystemAddress != address(0));
        ecosystemAddress = _ecosystemAddress;
    }

    function setAuthToBurnbPLOT(address _authToBurnbPLOT) public onlyAuthorized {
        // Should be able to set to null address, to revoke the access to burn bPLOT
        authToBurnbPLOT = _authToBurnbPLOT;
    }

    function burnUnusedbPLOT(address[] memory _users, uint256[] memory _amounts) public {
        require(msg.sender == authToBurnbPLOT);
        for(uint i = 0; i < _users.length; i++) {
          _burn(_users[i], _amounts[i]);
          require(IERC20(plotToken).transfer(ecosystemAddress, _amounts[i]), "Error in transfer");
          emit BurntUnusedbPLOT(_users[i], _amounts[i]);
        }
    }
}
