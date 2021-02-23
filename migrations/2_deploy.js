const Master = artifacts.require('Master');
const AllMarkets = artifacts.require('MockAllMarkets');
const MarketCreationRewards = artifacts.require('MarketCreationRewards');
const PlotusToken = artifacts.require('MockPLOT');
const BLOT = artifacts.require('BLOT');
const MarketConfig = artifacts.require('MockConfig');
const MockchainLink = artifacts.require('MockChainLinkAggregator');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const ParticipationMining = artifacts.require('ParticipationMining');
const DisputeResolution = artifacts.require('DisputeResolution');
const { assert } = require("chai");
const encode1 = require('../test/utils/encoder.js').encode1;
const BN = web3.utils.BN;

module.exports = function(deployer, network, accounts){
  deployer.then(async () => {
      
      let deployPlotusToken = await deployer.deploy(PlotusToken, "PLOT", "PLOT", 18,accounts[0], accounts[0]);
      deployPlotusToken.mint(accounts[0],"30000000000000000000000000");
      let mockchainLinkAggregaror = await deployer.deploy(MockchainLink);
      let marketConfig = await deployer.deploy(MarketConfig);
      let plotusToken = await PlotusToken.at(deployPlotusToken.address);

      let blotToken = await deployer.deploy(BLOT);
      let masterProxy = await deployer.deploy(Master);
      let master = await deployer.deploy(OwnedUpgradeabilityProxy, masterProxy.address);
      let allMarkets = await deployer.deploy(AllMarkets);
      let mcr = await deployer.deploy(MarketCreationRewards);
      let participationMining = await deployer.deploy(ParticipationMining);
      let dr = await deployer.deploy(DisputeResolution);
      master = await Master.at(master.address);
      let implementations = [allMarkets.address, mcr.address, marketConfig.address, blotToken.address, participationMining.address, dr.address];
      await master.initiateMaster(implementations, deployPlotusToken.address, accounts[0]);
      master = await OwnedUpgradeabilityProxy.at(master.address);
      await master.transferProxyOwnership(accounts[0]);
      master = await Master.at(master.address);
      var date = Date.now();
      date = Math.round(date/1000);
      
      let _marketUtility = await master.getLatestAddress(web3.utils.toHex("MU"));
      let marketutility = await MarketConfig.at(_marketUtility); 
      await marketutility.setAssetPlotConversionRate(plotusToken.address, 1);


      let allMarketsProxy = await OwnedUpgradeabilityProxy.at(
        await master.getLatestAddress(web3.utils.toHex('AM'))
      );

      let mcrProxy = await OwnedUpgradeabilityProxy.at(
        await master.getLatestAddress(web3.utils.toHex('MC'))
      );

      allMarkets = await AllMarkets.at(allMarketsProxy.address);
      mcr = await MarketCreationRewards.at(mcrProxy.address);

      assert.equal(await master.isInternal(allMarkets.address), true);
      assert.equal(await master.isInternal(mcr.address), true);
      // await mcr.initialise()
      await plotusToken.approve(allMarkets.address, "1000000000000000000000000")
      await allMarkets.addInitialMarketTypesAndStart(date, mockchainLinkAggregaror.address, mockchainLinkAggregaror.address, accounts[0]);
  });
};
