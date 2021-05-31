pragma solidity 0.5.7;

import "../interfaces/ISwapRouter.sol";
import "../external/openzeppelin-solidity/math/SafeMath.sol";
import "../interfaces/IToken.sol";

contract MockUniswapRouter {

	using SafeMath for uint;

	uint public priceOfToken = 1e16;
	address token;
	address weth;

	constructor(address _token) public {
		token = _token;
        weth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	}

    function WETH() external view returns (address) {
    	return weth;
    }

    function setWETH(address _weth) external {
    	weth = _weth;
    }

    function setPrice(uint _newPrice) external {
    	priceOfToken = _newPrice;
    }


    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts) {
        	uint ethSent = msg.value;
        	uint tokenOutput = ethSent.mul(1e18).div(priceOfToken);
	    	IToken(token).transfer(to, tokenOutput); 
            amounts = new uint[](2);
            amounts[0] = ethSent;
            amounts[1] = tokenOutput;
        }
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts) {
        	uint tokenOutput = amountIn.mul(1e18).div(priceOfToken);
	    	IToken(path[0]).transferFrom(msg.sender, address(this), amountIn); 
	    	IToken(token).transfer(to, tokenOutput); 
            amounts = new uint[](2);
            amounts[0] = amountIn;
            amounts[1] = tokenOutput;
        }

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts) {
    	amounts = new uint[](2);
    	amounts[0] = amountIn;
    	if(path[0] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
    		amounts[1] = amountIn.mul(priceOfToken);
    	} else {
    		amounts[1] = amountIn.mul(priceOfToken).div(1e18);
    	}
    }

    function () payable external {

    }

}