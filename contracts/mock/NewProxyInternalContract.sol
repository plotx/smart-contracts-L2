pragma solidity 0.5.7;

import "../Master.sol";
import "../interfaces/Iupgradable.sol";

contract NewProxyInternalContract is Iupgradable {
	Master public ms;

    function setMasterAddress(address _auth, address _authMultisig) public {
    	ms = Master(msg.sender);
    }

    function callDummyOnlyInternalFunction(uint _val) public {
    }

    function changeDependentContractAddress() public {
        require(ms.isInternal(msg.sender));
    }
}