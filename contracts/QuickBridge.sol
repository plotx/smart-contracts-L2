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

import "./interfaces/IToken.sol";


contract QuickBridge {
    
    address[] public tokens; 
    address public authController;
    address public migrationController; 
    /**
     * @dev Checks if msg.sender is authController.
     */
    modifier onlyAuthorized() {
        require(msg.sender == authController, "Only authorized");
        _;
    }
    
    mapping(bytes32 => MigrationStatus) public migrationStatus;
    mapping(address => TokenStatus) public tokenStatus;
    
    struct MigrationStatus{
        bool initiated;
        bool completed;
    }
    
    struct TokenStatus{
        bool whitelisted;
        bool enabled;
    }

    event MigrationAuthorised(bytes hash, address indexed to, address indexed from, uint256 value);
    event MigrationCompleted(bytes hash, address indexed to, address indexed from, uint256 value);

    constructor(address[] memory _tokens, address _authController, address _migrationController) public {
        authController = _authController;
        migrationController = _migrationController;
        whitelistNewToken(_tokens);
    }
    
    /**
     * @dev Returns the hash of given params
     */    
    function migrationHash( bytes memory _hash, address _to, address _from, uint256 _timestamp,uint256 _amount) public view returns (bytes32){
        return  keccak256(abi.encode(_hash, _to, _from, _timestamp,_amount));
    }
    
    /**
     * @dev Whitelist transaction to transfer bPlots.
     */
    function whitelistMigration(
        bytes memory _hash,
        address _to,
        address _from,
        uint256 _timestamp,
        uint256 _amount,
        address _token
    ) public onlyAuthorized returns (bytes32) {
        require(tokenStatus[_token].enabled,"Token should be enabled for migration");
        require(migrationStatus[ migrationHash(_hash, _to, _from, _timestamp,_amount)].initiated == false, "Migration already initiated");
        
        migrationStatus[ migrationHash(_hash, _to, _from, _timestamp,_amount)].initiated = true;
        emit MigrationAuthorised(_hash,_to, _from,_amount);

        return migrationHash(_hash, _to, _from, _timestamp,_amount);        
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
        uint256 _amount,
        address _token
    ) public returns (bool){
        require(msg.sender == migrationController, "sender is not migration controller");
        require(tokenStatus[_token].enabled,"Token should be enabled for migration");
        require(migrationStatus[ migrationHash(_hash, _to, _from, _timestamp,_amount)].initiated == true, "Migration not initiated");
        require(migrationStatus[ migrationHash(_hash, _to, _from, _timestamp,_amount)].completed == false, "Migration already completed");
        require(IToken(_token).transfer( _to, _amount));
        
        migrationStatus[ migrationHash(_hash, _to, _from, _timestamp,_amount)].completed = true;
        emit MigrationCompleted(_hash,_to, _from,_amount);

        return true;
    }
    
     function whitelistNewToken(address[] memory _tokens) public onlyAuthorized{
        for(uint8 i = 0; i<_tokens.length;i++){
            require(_tokens[i] != address(0),"Token should be non-zero address");
            require(tokenStatus[_tokens[i]].whitelisted == false,"Token exists in whitelist");
            
            tokens.push(_tokens[i]);
            tokenStatus[_tokens[i]].whitelisted = true;
            tokenStatus[_tokens[i]].enabled = true;
        }
       
    }
    
     function updateTokenMigrationStatus(address _token) public onlyAuthorized{
        require(_token != address(0));
        require(tokenStatus[_token].whitelisted == true,"Token not whitelisted");
        
        tokenStatus[_token].enabled = !tokenStatus[_token].enabled;
    }
   
    
}
