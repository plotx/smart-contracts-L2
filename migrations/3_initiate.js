const Master = artifacts.require('Master');
const AllMarkets = artifacts.require('MockAllMarkets');
const PlotusToken = artifacts.require('MockPLOT');
const BLOT = artifacts.require('BLOT');
const AcyclicMarkets = artifacts.require('MockAcyclicMarkets');
const MockchainLink = artifacts.require('MockChainLinkAggregator');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const DisputeResolution = artifacts.require('DisputeResolution');
const Referral = artifacts.require('Referral');
const UserLevels = artifacts.require('UserLevels');
const CyclicMarkets = artifacts.require('MockCyclicMarkets');
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
    let dr = await DisputeResolution.deployed();
    let cm = await CyclicMarkets.deployed();
    let ac = await AcyclicMarkets.deployed();
    let rf = await Referral.deployed();
    let ul = await UserLevels.deployed();
    master = await Master.at(master.address);
    let implementations = [allMarkets.address, blotToken.address, rf.address, ul.address, dr.address, cm.address, ac.address];
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

    allMarkets = await AllMarkets.at(allMarketsProxy.address);
    cm = await CyclicMarkets.at(await master.getLatestAddress(web3.utils.toHex('CM')));
    ac = await AllMarkets.at(await master.getLatestAddress(web3.utils.toHex('AC')));
    // await allMarkets.setAssetPlotConversionRate(plotusToken.address, 1);

    assert.equal(await master.isInternal(allMarkets.address), true);
    await allMarkets.addAuthorizedMarketCreator(cm.address);
    await allMarkets.addAuthorizedMarketCreator(ac.address);
    await allMarkets.initializeDependencies();
    await plotusToken.approve(allMarkets.address, "1000000000000000000000000");
    await cm.addInitialMarketTypesAndStart(date, ethChainlinkOracle.address, ethChainlinkOracle.address);
  });
};