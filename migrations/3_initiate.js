const Master = artifacts.require('Master');
const AllMarkets = artifacts.require('MockAllMarkets');
const PlotusToken = artifacts.require('MockPLOT');
const BPLOT = artifacts.require('BPLOT');
const MockchainLink = artifacts.require('MockChainLinkAggregator');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const DisputeResolution = artifacts.require('DisputeResolution');
const Referral = artifacts.require('Referral');
const UserLevels = artifacts.require('UserLevels');
const CyclicMarkets = artifacts.require('MockCyclicMarkets');
const AcyclicMarkets = artifacts.require('MockAcyclicMarkets');
const EthChainlinkOracle = artifacts.require('EthChainlinkOracle');
const { assert } = require("chai");

module.exports = function(deployer, network, accounts){
  deployer.then(async () => {
    let deployPlotusToken = await deployer.deploy(PlotusToken, "PLOT", "PLOT", 18,accounts[0], accounts[0]);
    deployPlotusToken.mint(accounts[0],"30000000000000000000000000");
    let plotusToken = await PlotusToken.at(deployPlotusToken.address);
    
    let ethChainlinkOracle = await EthChainlinkOracle.deployed();
    let bPlotToken = await BPLOT.deployed();
    let masterProxy = await Master.deployed();
    let master = await OwnedUpgradeabilityProxy.deployed();

//     let allMarkets = await AllMarkets.deployed();
//     let dr = await DisputeResolution.deployed();
//     let cm = await CyclicMarkets.deployed();
//     let ac = await AcyclicMarkets.deployed();
    master = await Master.at(master.address);
//     let implementations = [allMarkets.address, bPlotToken.address, dr.address, cm.address, ac.address];
    let implementations = [bPlotToken.address];

    console.log(accounts[0])
    await master.initiateMaster(implementations, deployPlotusToken.address, accounts[0], accounts[0]);
    master = await OwnedUpgradeabilityProxy.at(master.address);
    await master.transferProxyOwnership(accounts[0]);
    master = await Master.at(master.address);

    allMarkets = await AllMarkets.deployed();
		cyclicMarkets = await CyclicMarkets.deployed();
		acyclicMarkets = await AcyclicMarkets.deployed();
		disputeResolution = await DisputeResolution.deployed();

		await master.addNewContract(web3.utils.toHex("AM"),allMarkets.address);
		await master.addNewContract(web3.utils.toHex("DR"),disputeResolution.address);
		await master.addNewContract(web3.utils.toHex("CM"),cyclicMarkets.address);
		await master.addNewContract(web3.utils.toHex("AC"),acyclicMarkets.address);

    allMarkets = await AllMarkets.at(await master.getLatestAddress(web3.utils.toHex("AM")));
		cyclicMarkets = await CyclicMarkets.at(await master.getLatestAddress(web3.utils.toHex("CM")));
		acyclicMarkets = await AcyclicMarkets.at(await master.getLatestAddress(web3.utils.toHex("AC")));
		// referral = await Referral.deployed();
		disputeResolution = await DisputeResolution.at(await master.getLatestAddress(web3.utils.toHex("DR")));
		bPlotToken = await BPLOT.at(await master.getLatestAddress(web3.utils.toHex("BL")));

    await bPlotToken.initializeDependencies();

    let allMarketsProxy = await OwnedUpgradeabilityProxy.at(
      await master.getLatestAddress(web3.utils.toHex('AM'))
      );
    var date = Date.now();
    date = Math.round(date/1000);

    allMarkets = await AllMarkets.at(allMarketsProxy.address);
    cm = await CyclicMarkets.at(await master.getLatestAddress(web3.utils.toHex('CM')));
    ac = await AcyclicMarkets.at(await master.getLatestAddress(web3.utils.toHex('AC')));
    // await allMarkets.setAssetPlotConversionRate(plotusToken.address, 1);

    assert.equal(await master.isInternal(allMarkets.address), true);
    await allMarkets.addAuthorizedMarketCreator(ac.address);
    await allMarkets.addAuthorizedMarketCreator(cm.address);
    await allMarkets.initializeDependencies();
    await plotusToken.approve(allMarkets.address, "1000000000000000000000000");
    await cm.whitelistMarketCreator(accounts[0]);
    await cm.addInitialMarketTypesAndStart(date, ethChainlinkOracle.address, ethChainlinkOracle.address);
    let rf = await deployer.deploy(Referral, master.address);
    let ul = await deployer.deploy(UserLevels, master.address);
    await cm.setReferralContract(rf.address);
    await cm.setUserLevelsContract(ul.address);
    await ac.setReferralContract(rf.address);
    await ac.setUserLevelsContract(ul.address);
  });
};