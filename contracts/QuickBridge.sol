    /* Copyright (C) 2021 PlotX.io
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


contract IChildChainManager {

    mapping(address => address) public rootToChildToken;

}


contract QuickBridge {
    
    address public  authController;
    address public  migrationController; 
    IChildChainManager public childChainManager;

    /**
     * @dev Checks if msg.sender is authController.
     */
    modifier onlyAuthorized() {
        require(msg.sender == authController, "Only callable by authorized");
        _;
    }
    
    mapping(bytes32 => MigrationStatus) public migrationStatus;
    mapping(address => bool) public tokenStatus;
    
    struct MigrationStatus{
        bool initiated;
        bool completed;
    }
    
    event MigrationAuthorised(bytes hash, address indexed to, address indexed from,uint256 timestamp, uint256 value, address token);
    event MigrationCompleted(bytes hash, address indexed to, address indexed from,uint256 timestamp, uint256 value, address token);

    constructor(address[] memory _tokens, address _migrationController, address _childChainManager) public {
        authController = msg.sender;
        migrationController = _migrationController;
        childChainManager = IChildChainManager(_childChainManager);
        whitelistNewToken(_tokens);
    }
    
    /**
     * @dev Returns the hash of given params
     */    
    function migrationHash( bytes memory _hash, address _to, address _from, uint256 _timestamp,uint256 _amount,address _token) public pure returns (bytes32){
        return  keccak256(abi.encode(_hash, _to, _from, _timestamp,_amount,_token));
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
        require(_to != address(0), "Can't be null address");
        require(_from != address(0), "Can't be null address");
        require(_timestamp != 0, "Can't be Zero");
        require(_amount != 0, "Can't be Zero");
        require(_token != address(0), "Can't be null address");
        bytes32 hash =  migrationHash(_hash, _to, _from, _timestamp,_amount,_token);
        require(tokenStatus[_token],"Token should be enabled for migration");
        require(migrationStatus[hash].initiated == false, "Migration already initiated");
        
        migrationStatus[hash].initiated = true;
        emit MigrationAuthorised(_hash,_to, _from, _timestamp, _amount, _token);

        return hash;        
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
        bytes32 hash =  migrationHash(_hash, _to, _from, _timestamp,_amount,_token);
        require(msg.sender == migrationController, "sender is not migration controller");
        require(tokenStatus[_token],"Token should be enabled for migration");
        require(migrationStatus[hash].initiated == true, "Migration not initiated");
        require(migrationStatus[hash].completed == false, "Migration already completed");
        address childToken = childChainManager.rootToChildToken(_token);
        require(childToken != address(0),"Invalid Root token");
        migrationStatus[hash].completed = true;
        require(IToken(childToken).transfer(_to, _amount), "ERC20:Transfer Failed");
        
        emit MigrationCompleted(_hash,_to, _from,_timestamp,_amount,_token);

        return true;
    }
    
     function whitelistNewToken(address[] memory _tokens) public onlyAuthorized{
        for(uint i = 0; i<_tokens.length;i++){
            require(_tokens[i] != address(0),"Token should be non-zero address");
            require(!tokenStatus[_tokens[i]],"Token exists in whitelist");
            
            tokenStatus[_tokens[i]] = true;
        }
       
    }
    
    function disableToken(address _token) external onlyAuthorized{
        require(_token != address(0), "Can't be null address");
        require(tokenStatus[_token],"Token doesn't exists in whitelist");
        tokenStatus[_token] = false;
    }

    function updateAuthController(address _add) external onlyAuthorized {
        require(_add != address(0), "Can't be null address");
        authController = _add;
    }

    function updateMigrationController(address _add) external {
        require(_add != address(0), "Can't be null address");
        require(msg.sender == migrationController, "Only callable by migration controller");
        migrationController = _add;
    }
   
    
}
