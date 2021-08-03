pragma solidity 0.5.7;



contract MockChildChainManager {

    mapping(address => address) public rootToChildToken;

    function setRootToChildToken(address _rootToken, address _childToken) public {
        rootToChildToken[_rootToken] = _childToken;
    }

}