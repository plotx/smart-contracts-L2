pragma solidity 0.5.7;


import "./external/openzeppelin-solidity/token/ERC20/ERC20.sol";
import "./external/NativeMetaTransaction.sol";
import "./external/openzeppelin-solidity/access/AccessControlMixin.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./interfaces/IAuth.sol";

contract ICyclicMarkets {
    struct MarketCreationData {
      uint32 initialStartTime;
      uint64 latestMarket;
      uint64 penultimateMarket;
      bool paused;
    }
    function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public;
    function claimCreationReward() external;
    function getInitialLiquidity(uint _marketType) external view returns(uint);
    function getPendingMarketCreationRewards(address _user) external view returns(uint256 tokenIncentive);
    mapping(uint256 => mapping(uint256 => MarketCreationData)) public marketCreationData;
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
    IAuth,
    NativeMetaTransaction
{

    using SafeMath for uint;

    ERC20 plotToken;
    IMaster ms;
    uint public minLiquidity;
    uint internal predictionDecimalMultiplier;
    uint public unstakeRestrictTime;
    uint public defaultMaxRecords;
    address public rewardWallet;
    mapping(address => uint) public userLastStaked;
    mapping(uint32 => mapping(uint32 => uint)) public marketTypeAdditionalReward;

    event Staked(address _user, uint _plotAmountStaked, uint lpTokensMinted);
    event Unstaked(address _user, uint _lpAmountUnstaked, uint plotTokensTransferred);
    event MarketCreated(uint _currencyType, uint _marketType, uint _initialLiquidity);
    event Claimed(uint _amountClaimed, uint _maxRecordProcessed);
    event AddedAdditionalReward(address _user, uint _amount);

    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
        OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
        require(msg.sender == proxy.proxyOwner(),"Only callable by proxy owner");
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
        rewardWallet = _defaultAuthorizedAddress;
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

    /**
     * @dev Stakes Plot tokens in pool.
     * @param _stakePlotAmount amount of Plot tokens to stake
     */
    function stake(uint _stakePlotAmount) public {
        require(_stakePlotAmount>0,"Value can not be 0");
        address payable __msgSender = _msgSender();
        userLastStaked[__msgSender] = now;
        claimCreationAndParticipationReward(defaultMaxRecords);
        uint plotBalance = (plotToken.balanceOf(address(this)));
        require(plotToken.transferFrom(__msgSender, address(this), _stakePlotAmount),"ERC20 call Failed");
        uint mintAmount = _stakePlotAmount;
        uint lpSupply = totalSupply();
        if(lpSupply > 0) {
          mintAmount = _stakePlotAmount.mul(lpSupply).div(plotBalance);
        }
        _mint(__msgSender, mintAmount);

        emit Staked(__msgSender, _stakePlotAmount, mintAmount);

    }

    /**
     * @dev Unstakes Plot tokens from pool.
     * @param _unStakeLP amount of lp tokens to return.
     */
    function unstake(uint _unStakeLP) public {
        require(_unStakeLP>0,"Value can not be 0");
        claimCreationAndParticipationReward(defaultMaxRecords);
        address payable __msgSender = _msgSender();
        require(userLastStaked[__msgSender].add(unstakeRestrictTime) < now,"Can not unstake in restricted period");
        uint lpSupply = totalSupply();
        _burn(__msgSender, _unStakeLP);
        uint plotBalance = (plotToken.balanceOf(address(this)));
        uint returnToken = _unStakeLP.mul(plotBalance).div(lpSupply);
        require(plotToken.transfer(__msgSender,returnToken),"ERC20 call Failed");

        emit Unstaked(__msgSender, _unStakeLP, returnToken);

    }

    /**
    * @dev Creates Market for specified currenct pair and market type.
    * @param _currencyTypeIndex The index of market currency feed
    * @param _marketTypeIndex The time duration of market.
    * @param _roundId Round Id to settle previous market (If applicable, else pass 0)
    */ 
    function createMarket(uint32 _currencyTypeIndex, uint32 _marketTypeIndex, uint80 _roundId) public {
        ICyclicMarkets cm = ICyclicMarkets(ms.getLatestAddress("CM"));
        uint initialLiquidity = cm.getInitialLiquidity(_marketTypeIndex);
        claimCreationAndParticipationReward(defaultMaxRecords);
        require(plotToken.balanceOf(address(this)).sub(initialLiquidity.mul(10**predictionDecimalMultiplier)) >= minLiquidity,"Liquidity falling beyond minimum liquidity");
        cm.createMarket(_currencyTypeIndex,_marketTypeIndex,_roundId);
        uint additionalReward = marketTypeAdditionalReward[_currencyTypeIndex][_marketTypeIndex];
        if(additionalReward>0)
        {
            _addAdditionalReward(additionalReward);
        }

        emit MarketCreated(_currencyTypeIndex,_marketTypeIndex,initialLiquidity);
    }

    /**
    * @dev Approves Plot tokens to allPlotMarket contract to spend behalf of current contract
    * @param _amount amount of plot tokens
    */ 
    function approveToAllMarkets(uint _amount) external onlyAuthorized {
        require(plotToken.approve(ms.getLatestAddress("AM"),_amount),"ERC20 call Failed");
    }

    /**
    * @dev Claims reward for previously created markets
    * @param _maxRecords max number of records to process
    */ 
    function claimCreationAndParticipationReward(uint _maxRecords) public {
        IAllPlotMarkets allMarkets = IAllPlotMarkets(ms.getLatestAddress("AM"));
        ICyclicMarkets cyclicMarket = ICyclicMarkets(ms.getLatestAddress("CM"));
        uint marketcCreationReward = cyclicMarket.getPendingMarketCreationRewards(address(this));
        if(marketcCreationReward>0){
            cyclicMarket.claimCreationReward();
        }
        (uint _tokenLeft, uint _tokenReward) = allMarkets.getUserUnusedBalance(address(this));
        if(_tokenLeft.add(_tokenReward) > 0)
        {
            allMarkets.withdraw(_tokenLeft.add(_tokenReward),_maxRecords);
        }

        if(marketcCreationReward.add(_tokenLeft).add(_tokenReward)>0){

            emit Claimed(marketcCreationReward.add(_tokenLeft).add(_tokenReward),_maxRecords);
        }

    }

    /**
    * @dev Updates unstake restrict time
    * @param _val new value to be updated as time restriction for unstake since last stake
    */ 
    function updateUnstakeRestrictTime(uint _val) external onlyAuthorized {
        require(_val > 0,"Value can not be 0");
        unstakeRestrictTime = _val;
    }

    /**
    * @dev Updates minimum liquidity contract should hold for market creation
    * @param _val new value to be updated as minimum liquidity beyonf which contract balance should not fall
    */ 
    function updateMinLiquidity(uint _val) external onlyAuthorized {
        require(_val > 0,"Value can not be 0");
        minLiquidity = _val;
    }

    /**
    * @dev To add additional reward for contributors of pool
    * @param _val amount of tokens as additional reward
    */ 
    function _addAdditionalReward(uint _val) internal {
        require(plotToken.transferFrom(rewardWallet, address(this), _val),"ERC20 call Failed");
        emit AddedAdditionalReward(rewardWallet, _val);
    }

    /**
    * @dev Returns Plot worth of entered LP
    * @param _unStakeLP amount of LP tokens
    * @return  Plot worth of entered LP.
    */
    function getPlotWorthOfLP(uint _unStakeLP) external view returns(uint){
        uint plotBalance = (plotToken.balanceOf(address(this)));
        uint lpSupply = totalSupply();
        return _unStakeLP.mul(plotBalance).div(lpSupply);
    }

    /**
    * @dev Updates Additional reward to br given per market type
    * @param _currencyTypeIndex The index of market currency 
    * @param _marketTypeIndex The index of market type.
    * @param _val Additional reward to be given
    */
    function updateAdditionalRewardPerMarketType(uint32 _currencyTypeIndex, uint32 _marketTypeIndex, uint _val) external onlyAuthorized {
        ICyclicMarkets cm = ICyclicMarkets(ms.getLatestAddress("CM"));
        (, uint64 latestTime, ,) = cm.marketCreationData(_marketTypeIndex, _currencyTypeIndex);
        require(latestTime > 0, "Not valid Market type");
        marketTypeAdditionalReward[_currencyTypeIndex][_marketTypeIndex] = _val;
    }

    /**
    * @dev Updates wallet address from which addtional reward will be deducted
    * @param _wallet Wallet address
    */
    function updateWalletAddress(address _wallet) external onlyAuthorized {
        require(_wallet != address(0),"Address should not be null");
        rewardWallet = _wallet;
    }
}
