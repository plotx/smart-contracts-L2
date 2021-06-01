const AllPlotMarkets_2 = artifacts.require('MockAllMarkets_2');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const Master = artifacts.require('Master');
const SwapAndPredictWithPlot = artifacts.require('SwapAndPredictWithPlot');
const MockUniswapRouter = artifacts.require('MockUniswapRouter');
const SampleERC = artifacts.require('SampleERC');
const { assert } = require("chai");

module.exports = function(deployer, network, accounts){
    deployer.then(async () => {
        let master = await OwnedUpgradeabilityProxy.deployed();
        master = await Master.at(master.address);
        let allMarketsNewImpl = await deployer.deploy(AllPlotMarkets_2);
        let spImpl = await deployer.deploy(SwapAndPredictWithPlot);
        await master.upgradeMultipleImplementations(
            [web3.utils.toHex("AM")],
            [allMarketsNewImpl.address]
        );
        await master.addNewContract(web3.utils.toHex("SP"), spImpl.address)
        let swapAnPredict = await SwapAndPredictWithPlot.at(await master.getLatestAddress(web3.utils.toHex('SP')));
        allMarkets = await AllPlotMarkets_2.at(await master.getLatestAddress(web3.utils.toHex('AM')));
        await allMarkets.addAuthorizedProxyPreditictor(swapAnPredict.address);
        let router = await deployer.deploy(MockUniswapRouter, await master.dAppToken());
        _weth = await SampleERC.new("WETH", "WETH");
        await router.setWETH(_weth.address);
        await swapAnPredict.initiate(
            router.address,
            await router.WETH()
        );
    });
};