const Master = artifacts.require('Master');
const AllMarkets = artifacts.require('MockAllMarkets');
const BLOT = artifacts.require('BLOT');
const MockchainLink = artifacts.require('MockChainLinkAggregator');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const DisputeResolution = artifacts.require('DisputeResolution');
const CyclicMarkets = artifacts.require('MockCyclicMarkets');
const AcyclicMarkets = artifacts.require('MockAcyclicMarkets');
const Referral = artifacts.require('Referral');
const UserLevels = artifacts.require('UserLevels');
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
      let dr = await deployer.deploy(DisputeResolution);
      let cm = await deployer.deploy(CyclicMarkets);
      let ac = await deployer.deploy(AcyclicMarkets);
      let rf = await deployer.deploy(Referral);
      let ul = await deployer.deploy(UserLevels);
  });
};
