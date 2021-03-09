const Master = artifacts.require('Master');
const AllMarkets = artifacts.require('MockAllMarkets');
const MarketCreationRewards = artifacts.require('MarketCreationRewards');
const PlotusToken = artifacts.require('MockPLOT');
const BLOT = artifacts.require('BLOT');
const MockchainLink = artifacts.require('MockChainLinkAggregator');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const ParticipationMining = artifacts.require('ParticipationMining');
const DisputeResolution = artifacts.require('DisputeResolution');
const EthChainlinkOracle = artifacts.require('EthChainlinkOracle');
const { assert } = require("chai");

module.exports = function(deployer, network, accounts){
  deployer.then(async () => {
    let deployPlotusToken = await deployer.deploy(PlotusToken, "PLOT", "PLOT", 18,accounts[0], accounts[0]);
    deployPlotusToken.mint(accounts[0],"30000000000000000000000000");
    let plotusToken = await PlotusToken.at(deployPlotusToken.address);
    
    let ethChainlinkOracle = await EthChainlinkOracle.deployed();
    let blotToken = await BLOT.deployed();
    let masterProxy = await Master.deployed();
    let master = await OwnedUpgradeabilityProxy.deployed();
    let allMarkets = await AllMarkets.deployed();
    let mcr = await MarketCreationRewards.deployed();
    let dr = await DisputeResolution.deployed();
    master = await Master.at(master.address);
    let implementations = [allMarkets.address, mcr.address, blotToken.address, dr.address];
    console.log(accounts[0])
    await master.initiateMaster(implementations, deployPlotusToken.address, accounts[0], accounts[0]);
    master = await OwnedUpgradeabilityProxy.at(master.address);
    await master.transferProxyOwnership(accounts[0]);
    master = await Master.at(master.address);
    var date = Date.now();
    date = Math.round(date/1000);

    let allMarketsProxy = await OwnedUpgradeabilityProxy.at(
      await master.getLatestAddress(web3.utils.toHex('AM'))
    );

    let mcrProxy = await OwnedUpgradeabilityProxy.at(
      await master.getLatestAddress(web3.utils.toHex('MC'))
    );
      
    allMarkets = await AllMarkets.at(allMarketsProxy.address);
    mcr = await MarketCreationRewards.at(mcrProxy.address);
    // await allMarkets.setAssetPlotConversionRate(plotusToken.address, 1);

    let participationMining = await deployer.deploy(ParticipationMining, allMarkets.address, accounts[0]);


    assert.equal(await master.isInternal(allMarkets.address), true);
    assert.equal(await master.isInternal(mcr.address), true);
    // await mcr.initialise()
    await plotusToken.approve(allMarkets.address, "1000000000000000000000000")
    await allMarkets.addInitialMarketTypesAndStart(date, ethChainlinkOracle.address, ethChainlinkOracle.address);
  });
};