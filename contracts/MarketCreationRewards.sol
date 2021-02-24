pragma solidity 0.5.7;

import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/openzeppelin-solidity/math/Math.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IAllMarkets.sol";
import "./interfaces/IMaster.sol";
import "./IAuth.sol";
import "./external/NativeMetaTransaction.sol";

contract MarketCreationRewards is IAuth, NativeMetaTransaction {

    using SafeMath for *;

	  event MarketCreatorReward(address indexed createdBy, uint256 indexed marketIndex, uint256 tokenIncentive);
    event MarketCreationReward(address indexed createdBy, uint256 marketIndex);
    event ClaimedMarketCreationReward(address indexed user, uint reward, address predictionToken);

    modifier onlyInternal() {
      IMaster(masterAddress).isInternal(msg.sender);
      _;
    }
    
    struct MarketCreationRewardData {
      uint tokenIncentive;
      address createdBy;
    }

    struct MarketCreationRewardUserData {
      uint128 lastClaimedIndex;
      uint256 rewardEarned;
      uint64[] marketsCreated;
    }
	
    address internal masterAddress;
    address internal plotToken;
    address internal predictionToken;
    uint internal predictionDecimalMultiplier;
    IAllMarkets internal allMarkets;
    mapping(uint256 => MarketCreationRewardData) internal marketCreationRewardData; //Of market
    mapping(address => MarketCreationRewardUserData) internal marketCreationRewardUserData; //Of user

    /**
     * @dev Changes the master address and update it's instance
     */
    function setMasterAddress(address _defaultAuthorizedAddress) public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner(),"not owner.");
      IMaster ms = IMaster(msg.sender);
      masterAddress = msg.sender;
      plotToken = ms.dAppToken();
      predictionToken = ms.dAppToken();
      allMarkets = IAllMarkets(ms.getLatestAddress("AM"));
      _initialise();
    }

    /**
    * @dev Function to set inital parameters of contract
    */
    function _initialise() internal {
      predictionDecimalMultiplier = 10;
      _initializeEIP712("MC");
    }

    /**
    * @dev function to calculate user incentive for market creation
    * @param _createdBy Address of market creator
    * @param _marketId Index of market
    */
    function updateMarketCreationData(address _createdBy, uint64 _marketId) external onlyInternal {
      marketCreationRewardData[_marketId].createdBy = _createdBy;
      marketCreationRewardUserData[_createdBy].marketsCreated.push(_marketId);
      emit MarketCreationReward(_createdBy, _marketId);
    }

    /**
    * @dev Function to deposit reward for market creator
    * @param _marketId Index of market
    * @param _creatorFee prediction token fee share earned by 
    */
    function depositMarketCreationReward(uint256 _marketId, uint256 _creatorFee) external onlyInternal {
    	marketCreationRewardUserData[marketCreationRewardData[_marketId].createdBy].rewardEarned = _creatorFee;
      emit MarketCreatorReward(marketCreationRewardData[_marketId].createdBy, _marketId, _creatorFee);
    } 

    /**
    * @dev function to reward user for initiating market creation calls as per the new incetive calculations
    */
    function claimCreationReward(uint256 _maxRecords) external {

      address payable _msgSender = _msgSender();
      uint256 rewardEarned = marketCreationRewardUserData[_msgSender].rewardEarned;
      require(rewardEarned > 0, "No pending");
      _transferAsset(address(predictionToken), _msgSender, rewardEarned);
      emit ClaimedMarketCreationReward(_msgSender, rewardEarned, predictionToken);
    }

    /**
    * @dev Transfer `_amount` number of market registry assets contract to `_to` address
    */
    function transferAssets(address _asset, address payable _to, uint _amount) external onlyAuthorized {
      _transferAsset(_asset, _to, _amount);
    }

    /**
    * @dev function to get pending reward of user for initiating market creation calls as per the new incetive calculations
    * @param _user Address of user for whom pending rewards to be checked
    * @return tokenIncentive Incentives given for creating market as per the gas consumed
    * @return pendingTokenReward prediction token Reward pool share of markets created by user
    */
    function getPendingMarketCreationRewards(address _user) external view returns(uint256 tokenIncentive){
      tokenIncentive = marketCreationRewardUserData[_user].rewardEarned;
      // pendingTokenReward = _getPendingRewardPoolIncentives(_user);
    }

    /**
    * @dev Transfer the assets to specified address.
    * @param _asset The asset transfer to the specific address.
    * @param _recipient The address to transfer the asset of
    * @param _amount The amount which is transfer.
    */
    function _transferAsset(address _asset, address payable _recipient, uint256 _amount) internal {
      if(_amount > 0) { 
          require(IToken(_asset).transfer(_recipient, _amount));
      }
    }

}
