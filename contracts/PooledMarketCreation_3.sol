pragma solidity 0.5.7;

import "./PooledMarketCreation_2.sol";

contract PooledMarketCreation_3 is PooledMarketCreation_2 {

    mapping(address => bool) public isAuthorizedCreator; // Check if address is authorized to create markets

    /**
    * @dev Whitelist an address to create market
    * @param _marketCreator Address to whitelist
    */
    function whitelistMarketCreator(address _marketCreator) external onlyAuthorized {
      require(!isAuthorizedCreator[_marketCreator]);
      isAuthorizedCreator[_marketCreator] = true;
    }

    /**
    * @dev De-Whitelist an existing address to create market
    * @param _marketCreator Address to remove from whitelist
    */
    function deWhitelistMarketCreator(address _marketCreator) external onlyAuthorized {
      require(isAuthorizedCreator[_marketCreator]);
      delete isAuthorizedCreator[_marketCreator];
    }

    /**
    * @dev Creates Market for specified currenct pair and market type.
    * @param _currencyTypeIndex The index of market currency feed
    * @param _marketTypeIndex The time duration of market.
    * @param _optionRanges Option ranges array
    */ 
    function createMarketWithOptionRanges(uint32 _currencyTypeIndex, uint32 _marketTypeIndex, uint64[] memory _optionRanges) public {
        require(isAuthorizedCreator[_msgSender()]);
        uint initialLiquidity = cyclicMarkets.getInitialLiquidity(_marketTypeIndex);
        claimCreationAndParticipationReward(defaultMaxRecords);
        require(getPlotLeftInPool().sub(initialLiquidity.mul(10**predictionDecimalMultiplier)) >= minLiquidity,"Liquidity falling beyond minimum liquidity");
        uint _marketIndex = allMarkets.getTotalMarketsLength();
        cyclicMarkets.createMarketWithOptionRanges(_currencyTypeIndex,_marketTypeIndex,_optionRanges);
        uint additionalReward = marketTypeAdditionalReward[_currencyTypeIndex][_marketTypeIndex];
        if(additionalReward>0)
        {
            _addAdditionalReward(additionalReward, _marketIndex);
        }

        emit MarketCreated(_currencyTypeIndex,_marketTypeIndex,initialLiquidity, getPlotLeftInPool(), totalSupply());
    }
}
