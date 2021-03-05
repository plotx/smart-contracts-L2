const Master = artifacts.require('Master');
const AllMarkets = artifacts.require('MockAllMarkets');
const MarketCreationRewards = artifacts.require('MarketCreationRewards');
const BLOT = artifacts.require('BLOT');
const MockchainLink = artifacts.require('MockChainLinkAggregator');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const ParticipationMining = artifacts.require('ParticipationMining');
const DisputeResolution = artifacts.require('DisputeResolution');
const EthChainlinkOracle = artifacts.require('EthChainlinkOracle');
const { assert } = require("chai");
const encode1 = require('../test/utils/encoder.js').encode1;
const BN = web3.utils.BN;

module.exports = function(deployer, network, accounts){
  deployer.then(async () => {
      
      let mockchainLinkAggregaror = await deployer.deploy(MockchainLink);
      let ethChainlinkOracle = await deployer.deploy(EthChainlinkOracle, mockchainLinkAggregaror.address);

      let blotToken = await deployer.deploy(BLOT);
      let masterProxy = await deployer.deploy(Master);
      let master = await deployer.deploy(OwnedUpgradeabilityProxy, masterProxy.address);
      let allMarkets = await deployer.deploy(AllMarkets);
      let mcr = await deployer.deploy(MarketCreationRewards);
      let participationMining = await deployer.deploy(ParticipationMining);
      let dr = await deployer.deploy(DisputeResolution);
  });
};
