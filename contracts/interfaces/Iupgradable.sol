pragma solidity 0.5.7;

contract Iupgradable {

    /**
     * @dev change master address
     */
    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public;
}
