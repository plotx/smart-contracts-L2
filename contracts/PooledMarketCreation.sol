pragma solidity 0.5.7;


import "./external/openzeppelin-solidity/token/ERC20/ERC20.sol";
import "./external/NativeMetaTransaction.sol";
import "./external/openzeppelin-solidity/access/AccessControlMixin.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";

contract ICyclicMarkets {
  function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public;
  function claimCreationReward() external;
  function getInitialLiquidity(uint _marketType) external view returns(uint);
}

contract IMaster {
    function dAppToken() public view returns(address);
    function getLatestAddress(bytes2 _module) public view returns(address);
}

contract IAllPlotMarkets {
  function withdraw(uint _token, uint _maxRecords) public;

  function getUserUnusedBalance(address _user) public view returns(uint256, uint256);
}


contract PooledMarketCreation is
    ERC20,
    NativeMetaTransaction
{

    using SafeMath for uint;

    ERC20 plotToken;
    IMaster ms;
    address authorized;
    uint public minLiquidity;
    uint internal predictionDecimalMultiplier;
    uint public unstakeRestrictTime;
    uint public defaultMaxRecords;
    mapping(address => uint) public userLastStaked;

    event Staked(address _user, uint _plotAmountStaked, uint lpTokensMinted);
    event Unstaked(address _user, uint _lpAmountUnstaked, uint plotTokensTransferred);
    event MarketCreated(uint _currencyType, uint _marketType, uint _initialLiquidity);
    event Claimed(uint _amountClaimed, uint _maxRecordProcessed);
    event AddedAdditionalReward(address _user, uint _amount);

    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
        OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
        require(msg.sender == proxy.proxyOwner());
        ms = IMaster(msg.sender);
        plotToken = ERC20(ms.dAppToken());
        _name = "LP";
        _symbol = "LP";
        _setupDecimals(18);
        minLiquidity = 100 ether;
        authorized = _authorizedMultiSig;
        predictionDecimalMultiplier = 10;
        unstakeRestrictTime = 1 days;
        defaultMaxRecords=10;
        _initializeEIP712("PMC");
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        view
        returns (address payable sender)
    {
        return NativeMetaTransaction._msgSender();
    }

    function stake(uint _stakePlotAmount) public {
        require(_stakePlotAmount>0);
        claimCreationAndParticipationReward(defaultMaxRecords);
        address payable _msgSender = _msgSender();
        userLastStaked[_msgSender] = now;
        uint plotBalance = (plotToken.balanceOf(address(this)));
        plotToken.transferFrom(_msgSender, address(this), _stakePlotAmount);
        uint mintAmount = _stakePlotAmount;
        uint lpSupply = totalSupply();
        if(lpSupply > 0) {
          mintAmount = _stakePlotAmount.mul(lpSupply).div(plotBalance);
        }
        _mint(_msgSender, mintAmount);

        emit Staked(_msgSender, _stakePlotAmount, mintAmount);

    }

    function unstake(uint _unStakeLP) public {
        require(_unStakeLP>0);
        claimCreationAndParticipationReward(defaultMaxRecords);
        address payable _msgSender = _msgSender();
        require(userLastStaked[_msgSender].add(unstakeRestrictTime) < now);
        uint lpSupply = totalSupply();
        _burn(_msgSender, _unStakeLP);
        uint plotBalance = (plotToken.balanceOf(address(this)));
        uint returnToken = _unStakeLP.mul(plotBalance).div(lpSupply);
        plotToken.transfer(_msgSender,returnToken);

        emit Unstaked(_msgSender, _unStakeLP, returnToken);

    }

    function createMarket(uint32 _currencyTypeIndex, uint32 _marketTypeIndex, uint80 _roundId) public {
        ICyclicMarkets cm = ICyclicMarkets(ms.getLatestAddress("CM"));
        uint initialLiquidity = cm.getInitialLiquidity(_marketTypeIndex);
        claimCreationAndParticipationReward(defaultMaxRecords);
        require(plotToken.balanceOf(address(this)).sub(initialLiquidity.mul(10**predictionDecimalMultiplier)) >= minLiquidity);
        cm.createMarket(_currencyTypeIndex,_marketTypeIndex,_roundId);

        emit MarketCreated(_currencyTypeIndex,_marketTypeIndex,initialLiquidity);
    }

    function approveToAllMarkets(uint _amount) public {
        require(msg.sender == authorized);
        plotToken.approve(ms.getLatestAddress("AM"),_amount);
    }

    function claimCreationAndParticipationReward(uint _maxRecords) public {
        IAllPlotMarkets allMarkets = IAllPlotMarkets(ms.getLatestAddress("AM"));
        ICyclicMarkets(ms.getLatestAddress("CM")).claimCreationReward();
        (uint _tokenLeft, uint _tokenReward) = allMarkets.getUserUnusedBalance(address(this));
        if(_tokenLeft.add(_tokenReward) == 0)
        {
            return;
        }
        allMarkets.withdraw(_tokenLeft.add(_tokenReward),_maxRecords);

        emit Claimed(_tokenLeft.add(_tokenReward),_maxRecords);

    }

    function updateUnstakeRestrictTime(uint _val) external {
        require(msg.sender == authorized);
        require(_val > 0);
        unstakeRestrictTime = _val;
    }

    function updateMinLiquidity(uint _val) external {
        require(msg.sender == authorized);
        require(_val > 0);
        minLiquidity = _val;
    }

    function addAdditionalReward(address _user, uint _val) public {

        require(_user != address(0));
        require(_val != 0);
        require(plotToken.transferFrom(_user, address(this), _val));
        emit AddedAdditionalReward(_user, _val);
    }
}
