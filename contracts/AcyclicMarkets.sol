pragma solidity 0.5.7;

import "./external/openzeppelin-solidity/math/SafeMath.sol";
import "./external/proxy/OwnedUpgradeabilityProxy.sol";
import "./external/NativeMetaTransaction.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IbLOTToken.sol";
import "./interfaces/IAuth.sol";
import "./interfaces/IAllMarkets.sol";
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

    event OptionPricingParams(uint256 indexed marketIndex, uint256 _stakingFactorMinStake,uint32 _minTimePassed);
    event QuestionInfo(string _question, uint64[] _optionRanges, uint32[] _marketTimes);
    
    uint32 minTimePassed;

    struct PricingData {
      uint256 stakingFactorMinStake;
      uint32 stakingFactorWeightage;
      uint32 timeWeightage;
      uint32 minTimePassed;
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
    address internal predictionToken;

    mapping(uint256 => PricingData) internal marketPricingData;
    mapping(address => bool) public authorizedAddresses;
    // mapping(uint256 => uint) public marketMaxOption;

    // uint internal totalOptions;
    uint internal stakingFactorMinStake;
    uint32 internal stakingFactorWeightage ;
    uint32 internal timeWeightage ;

    modifier onlyAuthorizedUsers() {
        require(authorizedAddresses[msg.sender]);
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
      authorizedAddresses[_defaultAuthorizedAddress] = true;
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
      minTimePassed = 10 hours; // need to set
      _initializeEIP712("AC");
    }

    /**
    * @dev Function to set authorized address
    **/
    function addAuthorizedAddress(address _address) external onlyAuthorizedUsers {
        authorizedAddresses[_address] = true;
    }

    /**
    * @dev Create the market.
    */
    function createMarket(string calldata _question, uint64[] calldata _optionRanges, uint32[] calldata _marketTimes) external {
      require(!paused);
      require(_marketTimes[0] >= now);
      uint64 _marketIndex = allMarkets.createMarket(_marketTimes, _optionRanges, _msgSender());
      
      marketPricingData[_marketIndex] = PricingData(stakingFactorMinStake, stakingFactorWeightage, timeWeightage, minTimePassed);
      
      emit OptionPricingParams(_marketIndex, stakingFactorMinStake, minTimePassed);
      emit QuestionInfo(_question,_optionRanges,_marketTimes);
    }


    /**
    * @dev Internal function to perfrom ceil operation of given params
    */
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }

    /**
    * @dev Settle the market, setting the winning option
    * @param _marketId Index of market
    */
    function settleMarket(uint256 _marketId, uint _answer) public onlyAuthorized {
      allMarkets.settleMarket(_marketId, _answer);
    }


    /**
    * @dev Set the flag to pause/resume market creation of particular market type
    */
    function toggleMarketCreationType(bool _flag) external onlyAuthorized {
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
      (uint[] memory _optionPricingParams, uint32 _startTime) = allMarkets.getMarketOptionPricingParams(_marketId,_prediction);
      PricingData storage _marketPricingData = marketPricingData[_marketId];
      (,,uint _predictionTime,,) = allMarkets.getMarketData(_marketId);
      uint stakingFactorConst;
      uint optionPrice; 
      uint256 totalStaked = _optionPricingParams[1];
      // Checking if current stake in market reached minimum stake required for considering staking factor.
      if(totalStaked > _marketPricingData.stakingFactorMinStake)
      {
        // 10000 / staking weightage
        stakingFactorConst = uint(10000).div(_marketPricingData.stakingFactorWeightage); 
        // (stakingFactorConst x Amount staked in option x 10^18) / Total staked in market --- (1)
        optionPrice = (stakingFactorConst.mul(_optionPricingParams[0]).mul(10**18).div(totalStaked)); 
      }
      uint timeElapsed = uint(now).sub(_startTime);
      // max(timeElapsed, minTimePassed)
      if(timeElapsed < _marketPricingData.minTimePassed) {
        timeElapsed = _marketPricingData.minTimePassed;
      }

      // (Time Elapsed x 10000) / (currentPriceWeightage)
      uint timeFactor = timeElapsed.mul(10000).div(_marketPricingData.timeWeightage);

      uint totalTime = _predictionTime;

      // (1) + ( timeFactor x 10^18 / Total Prediction Time)  -- (2)
      optionPrice = optionPrice.add((timeFactor).mul(10**18).div(totalTime));  
      // (2) / ((stakingFactorConst x 10^13) + timeFactor x 10^13 / Total Prediction Time)
      optionPrice = optionPrice.div(stakingFactorConst.mul(10**13).add(timeFactor.mul(10**13).div(totalTime)));

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
}
