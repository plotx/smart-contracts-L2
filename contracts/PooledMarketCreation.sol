pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/NativeMetaTransaction.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./LPToken.sol";

contract ICyclicMarkets {
  function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public;
  function claimCreationReward() external;
  function getInitialLiquidity(uint _marketType) external view returns(uint);
}

contract IMaster {
    function dAppToken() public view returns(address);
    function getLatestAddress(bytes2 _module) public view returns(address);
}

contract IToken {

    function balanceOf(address account) public view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function totalSupply() public view returns (uint256);
    function mint(address account, uint256 amount) public;
    function burnFrom(address account, uint256 amount) public;
}

contract PooledMarketCreation is NativeMetaTransaction {
  
  using SafeMath for uint;

  IToken plotToken;
  LPToken public lpToken;
  IMaster ms;
  address authorized;
  uint public minLiquidity;
  uint32 public currencyType;

  constructor(address _masterAdd, address _authorized, uint32 _currencyType) public {
    require(_masterAdd!=address(0));
    require(_authorized!=address(0));
    ms = IMaster(_masterAdd);
    plotToken = IToken(ms.dAppToken());
    lpToken = new LPToken("LP","LP",18);
    minLiquidity = 100 ether;
    authorized = _authorized;
    currencyType = _currencyType;
    _initializeEIP712("PMC");
  }

  function stake(uint _stakePlotAmount) public {
    require(_stakePlotAmount>0);
    address payable _msgSender = _msgSender();
    uint plotBalance = (plotToken.balanceOf(address(this)));
    plotToken.transferFrom(_msgSender, address(this), _stakePlotAmount);
    uint mintAmount = _stakePlotAmount;
    uint lpSupply = lpToken.totalSupply();
    if(lpSupply > 0) {
      mintAmount = _stakePlotAmount.mul(lpSupply).div(plotBalance);
    }
    lpToken.mint(_msgSender, mintAmount);

  }

  function unstake(uint _unStakeLP) public {

    require(_unStakeLP>0);
    
    address payable _msgSender = _msgSender();
    uint lpSupply = lpToken.totalSupply();
    lpToken.burnFrom(_msgSender, _unStakeLP);
    uint plotBalance = (plotToken.balanceOf(address(this)));
    uint returnToken = _unStakeLP.mul(plotBalance).div(lpSupply);
    plotToken.transfer(_msgSender,returnToken);

  }

  function createMarket(uint32 _marketTypeIndex, uint80 _roundId) public {
    ICyclicMarkets cm = ICyclicMarkets(ms.getLatestAddress("CM"));
    uint initialLiquidity = cm.getInitialLiquidity(_marketTypeIndex);
    require(plotToken.balanceOf(address(this)).sub(initialLiquidity) >= minLiquidity);
    cm.createMarket(currencyType,_marketTypeIndex,_roundId);
  }

  function approveToAllMarkets(uint _amount) public {
    require(msg.sender == authorized);
    plotToken.approve(ms.getLatestAddress("AM"),_amount);
  }

  function claimCreationReward() external {
      ICyclicMarkets(ms.getLatestAddress("CM")).claimCreationReward();
  }

}
