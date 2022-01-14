pragma solidity 0.5.7;

import "./PooledMarketCreation_2.sol";

contract PooledMarketCreation_3 is PooledMarketCreation_2 {


    function createMarket(uint32 _currencyTypeIndex, uint32 _marketTypeIndex, uint80 _roundId) public {
        revert("DEPR");
    }

    /**
    * @dev Creates Market for specified currenct pair and market type.
    * @param _currencyTypeIndex The index of market currency feed
    * @param _marketTypeIndex The time duration of market.
    */ 
    function createMarketWithOptionRanges(uint32 _currencyTypeIndex, uint32 _marketTypeIndex, uint64[] memory _optionRanges) public {
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
