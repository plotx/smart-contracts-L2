pragma solidity 0.5.7;
import "../external/openzeppelin-solidity/token/ERC20/ERC20.sol";

contract MockPLOT is ERC20 {

	constructor(string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address _operator,
        address childChainManager) public ERC20(name_,symbol_) {
    }

    function mint(address user, uint amount) public returns(bool) {
    	_mint(user,amount);
    }

	function burnTokens(address _of, uint _amount) external {
        _burn(_of, _amount);
	}

	function burn(uint _amount) external {
        _burn(msg.sender, _amount);
	}
}