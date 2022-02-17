pragma solidity 0.5.7;

contract IbPLOTToken {
    function convertToPLOT(address _of, address _to, uint256 amount) public;
    function transfer(address recipient, uint256 amount) public returns (bool);
    function renounceMinter() public;
    function collectBPLOT(address _of,uint256 amount) public;
    function balanceOf(address account) external view returns (uint256);
}