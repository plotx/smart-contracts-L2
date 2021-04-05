pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/NativeMetaTransaction.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";

contract ICyclicMarkets {
  function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public;
  function claimCreationReward() external;
}

contract IAcyclicMarkets {
  function createMarket(string calldata _question, uint64[] calldata _optionRanges, uint32[] calldata _marketTimes) external;
  function claimCreationReward() external;
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
  IToken lpToken;
  IMaster ms;
  address authorized;
  uint public minLiquidity;


  function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner());
      ms = IMaster(msg.sender);
      plotToken = IToken(ms.dAppToken());
      authorized = _authorizedMultiSig;
      _initializeEIP712("PC");
  }

  function initializeLPToken(address _lpToken) external {
    require(_lpToken!=address(0));
    require(address(lpToken)==address(0));
    require(IToken(_lpToken).totalSupply() == 0);
    require(msg.sender == authorized);

    lpToken = IToken(_lpToken);
    
  }

  function stake(uint _stakePlotAmount) public {
    require(_stakePlotAmount>0);
    address payable _msgSender = _msgSender();
    uint plotBalance = (plotToken.balanceOf(address(this)));
    plotToken.transferFrom(_msgSender, address(this), _stakePlotAmount);
    uint mintAmount = _stakePlotAmount;
    uint lpSupply = lpToken.totalSupply();
    if(plotBalance > 0) {
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

  function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public {
    //Add check for liquidity in contract
    ICyclicMarkets(ms.getLatestAddress("CM")).createMarket(_marketCurrencyIndex,_marketTypeIndex,_roundId);
  }

  function createMarket(string calldata _question, uint64[] calldata _optionRanges, uint32[] calldata _marketTimes) external {
    //Add check for liquidity in contract
    IAcyclicMarkets(ms.getLatestAddress("AC")).createMarket(_question,_optionRanges,_marketTimes);
  }

  function approveToAllMarkets(uint _amount) public {

    require(msg.sender == authorized);
    plotToken.approve(ms.getLatestAddress("AM"),_amount);
  }

  function claimCreationReward() external {
      IAcyclicMarkets(ms.getLatestAddress("CM")).claimCreationReward();
      IAcyclicMarkets(ms.getLatestAddress("AC")).claimCreationReward();
  }
  


}
