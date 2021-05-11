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

import "./interfaces/IbPLOTToken.sol";


contract bPLOTMigration {
    
    address public constant bPLOTToken = 0x7a86d5eB74C84C3C094404D20c1c0A68dE84b9Fb;
    address public constant authController = 0x6f9f333de6eCFa67365916cF95873a4DC480217a;
    address public constant migrationController = 0x3A6D2faBDf51Af157F3fC79bb50346a615c08BF6;
    
    /**
     * @dev Checks if msg.sender is authController.
     */
    modifier onlyAuthorized() {
        require(msg.sender == authController, "Only authorized");
        _;
    }
    
    mapping(bytes32 => MigrationStatus) public migrationStatus;
    
    struct MigrationStatus{
        bool initiated;
        bool completed;
    }

    event MigrationAuthorised(bytes hash);
    event MigrationCompleted(bytes hash);
    
    /**
     * @dev Returns the hash of given params
     */    
    function migrationHash( bytes memory _hash, address _to, address _from, uint256 _timestamp,uint256 _amount) public view returns (bytes32){
        return  keccak256(abi.encode(_hash, _from, _to, _timestamp,_amount));
    }
    
    /**
     * @dev Whitelist transaction to transfer bPlots.
     */
    function whitelistMigration(
        bytes memory _hash,
        address _to,
        address _from,
        uint256 _timestamp,
        uint256 _amount
    ) public onlyAuthorized returns (bytes32) {
        require(migrationStatus[ migrationHash(_hash, _from, _to, _timestamp, _amount)].initiated == false, "Migration already initiated");
        
        migrationStatus[ migrationHash(_hash, _from, _to, _timestamp, _amount)].initiated = true;
        emit MigrationAuthorised(_hash);

        return migrationHash(_hash, _from, _to, _timestamp, _amount);        
    }    
   
    /**
     * @dev Transfers bPlots as per whitelisted transaction.
     *
     */
    function migrate(
        bytes memory _hash,
        address _to,
        address _from,
        uint256 _timestamp,
        uint256 _amount
    ) public returns (bool){
        require(msg.sender == migrationController, "sender is not migration controller");
        require(migrationStatus[ migrationHash(_hash, _from, _to, _timestamp, _amount)].initiated == true, "Migration not initiated");
        require(migrationStatus[ migrationHash(_hash, _from, _to, _timestamp, _amount)].completed == false, "Migration already completed");

        IbPLOTToken(bPLOTToken).transfer( _to, _amount);
        migrationStatus[ migrationHash(_hash, _from, _to, _timestamp, _amount)].completed = true;
        emit MigrationCompleted(_hash);

        return true;
    }
    
    /**
     * @dev Renounce contract from bPLOT Minter Role
     */
    function renounceMinterRole() public onlyAuthorized {
        IbPLOTToken(bPLOTToken).renounceMinter();
    }
    
    // /**
    //  * @dev Transfer tokens from contract to specified address
    //  */
    // function recover(address _address,uint256 _amount) public onlyAuthorized {
    //     require(msg.sender == authController, "msg.sender is not authController");
    //     IbPLOTToken(bPLOTToken).transfer(_address,_amount);
    // }
    
    
}
