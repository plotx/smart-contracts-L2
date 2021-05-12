pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IbPLOTToken.sol";
import "./interfaces/IAuth.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IAllMarkets.sol";
import "./interfaces/IUserLevels.sol";
import "./interfaces/IOracle.sol";

contract IMaster {
    function dAppToken() public view returns(address);
    function getLatestAddress(bytes2 _module) public view returns(address);
}
contract AcyclicMarkets is IAuth, NativeMetaTransaction {
    using SafeMath32 for uint32;
    using SafeMath64 for uint64;
    using SafeMath128 for uint128;
    using SafeMath for uint;

    enum PredictionStatus {
      Live,
      InSettlement,
      Cooling,
      InDispute,
      Settled
    }

    event MarketParams(uint256 indexed marketIndex, string _question, uint64[] _optionRanges, uint32[] _marketTimes, uint256 _stakingFactorMinStake,uint32 _minTimePassed, address marketCreator, bytes8 _marketType, bytes8 _marketCurrency);
    event MarketCreatorReward(address indexed createdBy, uint256 indexed marketIndex, uint256 tokenIncentive);
    event ClaimedMarketCreationReward(address indexed user, uint reward, address predictionToken);

    uint32 minTimePassed;

    struct PricingData {
      uint256 stakingFactorMinStake;
      uint32 stakingFactorWeightage;
      uint32 timeWeightage;
      uint32 minTimePassed;
    }

    struct MarketData {
      address marketCreator;
      PricingData pricingData;
    }

    struct MarketFeeParams {
      uint32 cummulativeFeePercent;
      uint32 daoCommissionPercent;
      uint32 referrerFeePercent;
      uint32 refereeFeePercent;
      uint32 marketCreatorFeePercent;
      mapping (uint256 => uint64) daoFee;
      mapping (uint256 => uint64) marketCreatorFee;
    }

    MarketFeeParams internal marketFeeParams;

    bool public paused;

    address internal masterAddress;
    address internal plotToken;
    IAllMarkets internal allMarkets;
    IReferral internal referral;
    IUserLevels internal userLevels;
    address internal predictionToken;

    mapping(uint256 => MarketData) internal marketData;
    mapping(address => uint256) public marketCreationReward;
    mapping (address => uint256) public relayerFeeEarned;
    mapping(address => bool) public whiteListedMarketCreators;

    mapping(address => mapping(uint256 => bool)) public multiplierApplied;

    // uint internal totalOptions;
    uint internal stakingFactorMinStake;
    uint32 internal stakingFactorWeightage;
    uint32 internal timeWeightage;
    uint internal predictionDecimalMultiplier;
    uint internal minPredictionAmount;
    uint internal maxPredictionAmount;

    modifier onlyAllMarkets {
      require(msg.sender == address(allMarkets));
      _;
    }

    /**
     * @dev Changes the master address and update it's instance
     * @param _authorizedMultiSig Authorized address to execute critical functions in the protocol.
     * @param _defaultAuthorizedAddress Authorized address to trigger initial functions by passing required external values.
     */
    function setMasterAddress(address _authorizedMultiSig, address _defaultAuthorizedAddress) public {
      OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
      require(msg.sender == proxy.proxyOwner());
      IMaster ms = IMaster(msg.sender);
      masterAddress = msg.sender;
      address _plotToken = ms.dAppToken();
      plotToken = _plotToken;
      predictionToken = _plotToken;
      allMarkets = IAllMarkets(ms.getLatestAddress("AM"));
      authorized = _authorizedMultiSig;
      stakingFactorMinStake = uint(20000).mul(10**8);
      stakingFactorWeightage = 40;
      timeWeightage = 60;
      MarketFeeParams storage _marketFeeParams = marketFeeParams;
      _marketFeeParams.cummulativeFeePercent = 200;
      _marketFeeParams.daoCommissionPercent = 1000;
      _marketFeeParams.refereeFeePercent = 1000;
      _marketFeeParams.referrerFeePercent = 2000;
      _marketFeeParams.marketCreatorFeePercent = 4000;
      minPredictionAmount = 10 ether; // Need to be updated
      maxPredictionAmount = 100000 ether; // Need to be updated
      minTimePassed = 10 hours; // need to set
      predictionDecimalMultiplier = 10;
      _initializeEIP712("AC");
    }

    /**
    * @dev Whitelisting Market Creators
    * @param _userAdd Address of the creator
    */
    function addWhiteListedAddress(address _userAdd) external onlyAuthorized {
      require(_userAdd != address(0));
      whiteListedMarketCreators[_userAdd] = true;
    }

    /**
    * @dev Removing user from whitelist
    */
    function removeFromWhitelist(address _userAdd) external onlyAuthorized {
      require(_userAdd != address(0));
      whiteListedMarketCreators[_userAdd] = false;
    }

    /**
    * @dev Set the referral contract address, to handle referrals and their fees.
    * @param _referralContract Address of the referral contract
    */
    function setReferralContract(address _referralContract) external onlyAuthorized {
      require(address(referral) == address(0));
      referral = IReferral(_referralContract);
    }

    /**
    * @dev Unset the referral contract address
    */
    function removeReferralContract() external onlyAuthorized {
      require(address(referral) != address(0));
      delete referral;
    }

    /**
    * @dev Set the User levels contract address, to handle user multiplier.
    * @param _userLevelsContract Address of the referral contract
    */
    function setUserLevelsContract(address _userLevelsContract) external onlyAuthorized {
      require(address(userLevels) == address(0));
      userLevels = IUserLevels(_userLevelsContract);
    }

    /**
    * @dev Unset the User levels contract address
    */
    function removeUserLevelsContract() external onlyAuthorized {
      require(address(userLevels) != address(0));
      delete userLevels;
    }

    /**
    * @dev Create the market.
    */
    function createMarket(string calldata _questionDetails, uint64[] calldata _optionRanges, uint32[] calldata _marketTimes,bytes8 _marketType, bytes8 _marketCurr, uint64 _marketInitialLiquidity) external {
      require(!paused);
      // address _marketCreator = _msgSender();
      require(whiteListedMarketCreators[_msgSender()]);
      uint32[] memory _timesArray = new uint32[](_marketTimes.length+1);
      _timesArray[0] = uint32(now);
      _timesArray[1] = _marketTimes[0].sub(uint32(now));
      _timesArray[2] = _marketTimes[1].sub(uint32(now));
      _timesArray[3] = _marketTimes[2];
      uint64 _marketId = allMarkets.getTotalMarketsLength();
      
      marketData[_marketId].pricingData = PricingData(stakingFactorMinStake, stakingFactorWeightage, timeWeightage, minTimePassed);
      marketData[_marketId].marketCreator = _msgSender();
      allMarkets.createMarket(_timesArray, _optionRanges, _msgSender(), _marketInitialLiquidity);

      emit MarketParams(_marketId, _questionDetails, _optionRanges,_marketTimes, stakingFactorMinStake, minTimePassed, _msgSender(), _marketType, _marketCurr);
    }

    /**
    * @dev Settle the market, setting the winning option
    * @param _marketId Index of market
    */
    function settleMarket(uint256 _marketId, uint _answer) public onlyAuthorized {
      allMarkets.settleMarket(_marketId, _answer);
      if(allMarkets.marketStatus(_marketId) >= IAllMarkets.PredictionStatus.InSettlement) {
        _transferAsset(plotToken, masterAddress, (10**predictionDecimalMultiplier).mul(marketFeeParams.daoFee[_marketId]));
        delete marketFeeParams.daoFee[_marketId];

    	  marketCreationReward[marketData[_marketId].marketCreator] = marketCreationReward[marketData[_marketId].marketCreator].add((10**predictionDecimalMultiplier).mul(marketFeeParams.marketCreatorFee[_marketId]));
        emit MarketCreatorReward(marketData[_marketId].marketCreator, _marketId, marketFeeParams.marketCreatorFee[_marketId]);
        delete marketFeeParams.marketCreatorFee[_marketId];
      }
    }


    /**
     * @dev Internal function to deduct fee from the prediction amount
     * @param _marketId Index of the market
     * @param _cummulativeFee Total fee amount
     * @param _msgSenderAddress User address
     */
    function handleFee(uint _marketId, uint64 _cummulativeFee, address _msgSenderAddress, address _relayer) external onlyAllMarkets {
      MarketFeeParams storage _marketFeeParams = marketFeeParams;
      // _fee = _calculateAmulBdivC(_marketFeeParams.cummulativeFeePercent, _amount, 10000);
      uint64 _referrerFee = _calculateAmulBdivC(_marketFeeParams.referrerFeePercent, _cummulativeFee, 10000);
      uint64 _refereeFee = _calculateAmulBdivC(_marketFeeParams.refereeFeePercent, _cummulativeFee, 10000);
      bool _isEligibleForReferralReward = referral.setReferralRewardData(_msgSenderAddress, plotToken, _referrerFee, _refereeFee);
      if(_isEligibleForReferralReward){
        _transferAsset(plotToken, address(referral), (10**predictionDecimalMultiplier).mul(_referrerFee.add(_refereeFee)));
      } else {
        _refereeFee = 0;
        _referrerFee = 0;
      }
      uint64 _daoFee = _calculateAmulBdivC(_marketFeeParams.daoCommissionPercent, _cummulativeFee, 10000);
      uint64 _marketCreatorFee = _calculateAmulBdivC(_marketFeeParams.marketCreatorFeePercent, _cummulativeFee, 10000);
      _marketFeeParams.daoFee[_marketId] = _marketFeeParams.daoFee[_marketId].add(_daoFee);
      _marketFeeParams.marketCreatorFee[_marketId] = _marketFeeParams.marketCreatorFee[_marketId].add(_marketCreatorFee);
      _setRelayerFee(_relayer, _cummulativeFee, _daoFee, _referrerFee, _refereeFee, _marketCreatorFee);
    }

    /**
    * @dev Internal function to set the relayer fee earned in the prediction 
    */
    function _setRelayerFee(address _relayer, uint _cummulativeFee, uint _daoFee, uint _referrerFee, uint _refereeFee, uint _marketCreatorFee) internal {
      relayerFeeEarned[_relayer] = relayerFeeEarned[_relayer].add(_cummulativeFee.sub(_daoFee).sub(_referrerFee).sub(_refereeFee).sub(_marketCreatorFee));
    }

    /**
    * @dev Internal function to calculate prediction points  and multiplier
    * @param _user User Address
    * @param _marketId Index of the market
    * @param _prediction Option predicted by the user
    * @param _stake Amount staked by the user
    */
    function calculatePredictionPointsAndMultiplier(address _user, uint256 _marketId, uint256 _prediction, uint64 _stake) external returns(uint64 predictionPoints){
      bool isMultiplierApplied;
      (predictionPoints, isMultiplierApplied) = calculatePredictionPoints(_marketId, _prediction, _user, multiplierApplied[_user][_marketId], _stake);
      if(isMultiplierApplied) {
        multiplierApplied[_user][_marketId] = true; 
      }
    }

    /**
    * @dev Internal function to calculate prediction points
    * @param _marketId Index of the market
    * @param _prediction Option predicted by the user
    * @param _user User Address
    * @param multiplierApplied Flag defining if user had already availed multiplier
    * @param _predictionStake Amount staked by the user
    */
    function calculatePredictionPoints(uint _marketId, uint256 _prediction, address _user, bool multiplierApplied, uint _predictionStake) internal view returns(uint64 predictionPoints, bool isMultiplierApplied) {
      uint _stakeValue = _predictionStake.mul(1e10);
      if(_stakeValue < minPredictionAmount || _stakeValue > maxPredictionAmount) {
        return (0, isMultiplierApplied);
      }
      uint64 _optionPrice = getOptionPrice(_marketId, _prediction);
      predictionPoints = uint64(_predictionStake).div(_optionPrice);
      if(!multiplierApplied) {
        uint256 _predictionPoints;
        (_predictionPoints, isMultiplierApplied) = checkMultiplier(_user,  predictionPoints);
        predictionPoints = uint64(_predictionPoints);
      }
    }

    /**
    * @dev Check if user gets any multiplier on his positions
    * @param _user User address
    * @param _predictionPoints The actual positions user got during prediction.
    * @return uint256 representing multiplied positions
    * @return bool returns true if multplier applied
    */
    function checkMultiplier(address _user, uint _predictionPoints) internal view returns(uint, bool) {
      bool _multiplierApplied;
      uint _muliplier = 100;
      (uint256 _userLevel, uint256 _levelMultiplier) = userLevels.getUserLevelAndMultiplier(_user);
      if(_userLevel > 0) {
        _muliplier = _muliplier + _levelMultiplier;
        _multiplierApplied = true;
      }
      return (_predictionPoints.mul(_muliplier).div(100), _multiplierApplied);
    }

    /**
    * @dev Claim fees earned by the relayer address
    */
    function claimRelayerRewards() external {
      uint _decimalMultiplier = 10**predictionDecimalMultiplier;
      address _relayer = msg.sender;
      uint256 _fee = (_decimalMultiplier).mul(relayerFeeEarned[_relayer]);
      delete relayerFeeEarned[_relayer];
      require(_fee > 0);
      _transferAsset(plotToken, _relayer, _fee);
    }

    /**
    * @dev Basic function to perform mathematical operation of (`_a` * `_b` / `_c`)
    * @param _a value of variable a
    * @param _b value of variable b
    * @param _c value of variable c
    */
    function _calculateAmulBdivC(uint64 _a, uint64 _b, uint64 _c) internal pure returns(uint64) {
      return _a.mul(_b).div(_c);
    }

    /**
    * @dev function to reward user for initiating market creation calls as per the new incetive calculations
    */
    function claimCreationReward() external {
      address payable _msgSenderAddress = _msgSender();
      uint256 rewardEarned = marketCreationReward[_msgSenderAddress];
      delete marketCreationReward[_msgSenderAddress];
      require(rewardEarned > 0, "No pending");
      _transferAsset(plotToken, _msgSenderAddress, rewardEarned);
      emit ClaimedMarketCreationReward(_msgSenderAddress, rewardEarned, plotToken);
    }

    /**
    * @dev Transfer the assets to specified address.
    * @param _asset The asset transfer to the specific address.
    * @param _recipient The address to transfer the asset of
    * @param _amount The amount which is transfer.
    */
    function _transferAsset(address _asset, address _recipient, uint256 _amount) internal {
      if(_amount > 0) { 
          require(IToken(_asset).transfer(_recipient, _amount));
      }
    }

    /**
    * @dev function to get pending reward of user for initiating market creation calls as per the new incetive calculations
    * @param _user Address of user for whom pending rewards to be checked
    * @return tokenIncentive Incentives given for creating market as per the gas consumed
    * @return pendingTokenReward prediction token Reward pool share of markets created by user
    */
    function getPendingMarketCreationRewards(address _user) external view returns(uint256 tokenIncentive){
      return marketCreationReward[_user];
    }

    /**
    * @dev Set the flag to pause/resume market creation of particular market type
    */
    function toggleMarketCreation(bool _flag) external onlyAuthorized {
      require(paused != _flag);
      paused = _flag;
    }

    /**
     * @dev Gets price for given market and option
     * @param _marketId  Market ID
     * @param _prediction  prediction option
     * @return  option price
     **/
    function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64) {
      uint optionLen = allMarkets.getTotalOptions(_marketId);
      (uint[] memory _optionPricingParams, uint32 _startTime) = allMarkets.getMarketOptionPricingParams(_marketId,_prediction);
      PricingData storage _marketPricingData = marketData[_marketId].pricingData;
      (,,uint _predictionTime,,) = allMarkets.getMarketData(_marketId);
      uint stakingFactorConst;
      uint optionPrice; 
      
      // Checking if current stake in market reached minimum stake required for considering staking factor.
      if(_optionPricingParams[1] < _marketPricingData.stakingFactorMinStake)
      {

        return uint64(uint(100000).div(optionLen));

      } else {
        // 10000 / staking weightage
        stakingFactorConst = uint(10000).div(_marketPricingData.stakingFactorWeightage); 
        // (stakingFactorConst x Amount staked in option x 10^18) / Total staked in market --- (1)
        optionPrice = (stakingFactorConst.mul(_optionPricingParams[0]).mul(10**18).div(_optionPricingParams[1])); 
      }
      uint timeElapsedFactor = uint(now).sub(_startTime);
      // max(timeElapsed, minTimePassed)
      if(timeElapsedFactor < _marketPricingData.minTimePassed) {
        timeElapsedFactor = _marketPricingData.minTimePassed;
      }

      // (Time Elapsed x 10000) / (Time Weightage)
      timeElapsedFactor = timeElapsedFactor.mul(10000).div(_marketPricingData.timeWeightage);

      // (1) + ( timeFactor x 10^18 / Total Prediction Time)  -- (2)
      optionPrice = optionPrice.add((timeElapsedFactor).mul(10**18).div(_predictionTime));  
      // (2) / ((stakingFactorConst x 10^13) + timeFactor x 10^13 / Total Prediction Time)
      optionPrice = optionPrice.div(stakingFactorConst.mul(10**13).add(optionLen.mul(timeElapsedFactor).mul(10**13).div(_predictionTime)));

      // option price for `_prediction` in 10^5 format
      return uint64(optionPrice);

    }

    /**
     * @dev Gets price for all the options in a market
     * @param _marketId  Market ID
     * @return _optionPrices array consisting of prices for all available options
     **/
    function getAllOptionPrices(uint _marketId) external view returns(uint64[] memory _optionPrices) {
     uint optionLen = allMarkets.getTotalOptions(_marketId);
     _optionPrices = new uint64[](optionLen);
      for(uint i=0;i<optionLen;i++) {
        _optionPrices[i] = getOptionPrice(_marketId,i+1);
      }

    }

    /**
    * @dev function to get integer parameters
    * @param code Code of the parameter.
    * @return codeVal Code of the parameter.
    * @return value Value of the queried parameter.
    */
    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint256 value) {
      codeVal = code;
      if(code == "CPW") { // Acyclic contracts don't have Current price weighage but time weightage
        value = timeWeightage;
      } else if(code == "SFMS") { // Minimum amount for staking factor to apply
        value = stakingFactorMinStake;
      } else if(code == "MINP") { // Minimum prediction amount
        value = minPredictionAmount;
      } else if(code == "MAXP") { // Maximum prediction amount
        value = maxPredictionAmount;
      } else if(code == "CMFP") { // Cummulative fee percent
        value = marketFeeParams.cummulativeFeePercent;
      } else if(code == "DAOF") { // DAO Fee percent in Cummulative fee
        value = marketFeeParams.daoCommissionPercent;
      } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
        value = marketFeeParams.referrerFeePercent;
      } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
        value = marketFeeParams.refereeFeePercent;
      } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
        value = marketFeeParams.marketCreatorFeePercent;
      }
    }

    /**
    * @dev function to update integer parameters
    * @param code Code of the updating parameter.
    * @param value Value to which the parameter should be updated
    */
    function updateUintParameters(bytes8 code, uint256 value) external onlyAuthorized {
      if(code == "CPW") { // Acyclic contracts don't have Current price weighage but time weightage
        require(value <= 100);
        timeWeightage = uint32(value);
        //Staking factor weightage% = 100% - timeWeightage%
        stakingFactorWeightage = 100 - timeWeightage;
      } else if(code == "SFMS") { // Minimum amount for staking factor to apply
        stakingFactorMinStake = value;
      } else if(code == "MINP") { // Minimum prediction amount
        minPredictionAmount = value;
      } else if(code == "MAXP") { // Maximum prediction amount
        maxPredictionAmount = value;
      } else {
        MarketFeeParams storage _marketFeeParams = marketFeeParams;
        require(value < 10000);
        if(code == "CMFP") { // Cummulative fee percent
          _marketFeeParams.cummulativeFeePercent = uint32(value);
        } else {
          if(code == "DAOF") { // DAO Fee percent in Cummulative fee
            _marketFeeParams.daoCommissionPercent = uint32(value);
          } else if(code == "RFRRF") { // Referrer fee percent in Cummulative fee
            _marketFeeParams.referrerFeePercent = uint32(value);
          } else if(code == "RFREF") { // Referee fee percent in Cummulative fee
            _marketFeeParams.refereeFeePercent = uint32(value);
          } else if(code == "MCF") { // Market Creator fee percent in Cummulative fee
            _marketFeeParams.marketCreatorFeePercent = uint32(value);
          } else {
            revert("Invalid code");
          } 
          require(
            _marketFeeParams.daoCommissionPercent + 
            _marketFeeParams.referrerFeePercent + 
            _marketFeeParams.refereeFeePercent + 
            _marketFeeParams.marketCreatorFeePercent
            < 10000);
        }
      }
    }
}
