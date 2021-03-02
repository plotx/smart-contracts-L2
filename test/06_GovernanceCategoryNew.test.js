const Governance = artifacts.require('Governance');
const AllMarkets = artifacts.require('AllMarkets');
const MarketCreationRewards = artifacts.require('MarketCreationRewards');
const ProposalCategory = artifacts.require('ProposalCategory');
const MemberRoles = artifacts.require('MemberRoles');
const Master = artifacts.require('Master');
const TokenController = artifacts.require('TokenController');
const MarketConfig = artifacts.require('MarketUtility');
const PlotusToken = artifacts.require("MockPLOT");
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const gvProposal = require('./utils/gvProposal.js').gvProposalWithIncentiveViaTokenHolder;
const assertRevert = require("./utils/assertRevert.js").assertRevert;
const increaseTime = require("./utils/increaseTime.js").increaseTime;
const encode = require('./utils/encoder.js').encode;
const encode1 = require('./utils/encoder.js').encode1;
const {toHex, toWei, toChecksumAddress} = require('./utils/ethTools');
const { takeSnapshot, revertSnapshot } = require('./utils/snapshot');


let gv;
let pc;
let mr;
let tc;
let ms;
let pl;
let allMarkets, mcr;
let marketConfig;
let plotTok;
let snapshotId;

const maxAllowance = '115792089237316195423570985008687907853269984665640564039457584007913129639935';
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

contract('Configure Global Parameters', accounts => {

    const [ab1, newAB] = accounts;

    before(async function() {

      snapshotId = await takeSnapshot();
      ms = await OwnedUpgradeabilityProxy.deployed();
      ms = await Master.at(ms.address);
      mcr = await MarketCreationRewards.at(await ms.getLatestAddress(toHex("MC")));
      allMarkets = await AllMarkets.at(await ms.getLatestAddress(toHex("AM")));
      plotTok = await PlotusToken.deployed();
      await plotTok.transfer(allMarkets.address, toWei(20));
      await plotTok.transfer(newAB, toWei(20));

    });

    describe('Testing Governanace Test Cases', function() {

      it('Should Pause Market Creation', async function() {
        assert.equal(await allMarkets.marketCreationPaused(), false);
        let actionHash = encode(
          'pauseMarketCreation()'
        );
        await allMarkets.pauseMarketCreation();
        assert.equal(await allMarkets.marketCreationPaused(), true);
      });

      it('Should stay Pause Market Creation if already paused', async function() {
        assert.equal(await allMarkets.marketCreationPaused(), true);
        let actionHash = encode(
          'pauseMarketCreation()'
        );
        await assertRevert(allMarkets.pauseMarketCreation());

        assert.equal(await allMarkets.marketCreationPaused(), true);
      });

      it('Should Resume Market Creation', async function() {
        assert.equal(await allMarkets.marketCreationPaused(), true);
        let actionHash = encode(
          'resumeMarketCreation()'
        );
        await allMarkets.resumeMarketCreation();
        assert.equal(await allMarkets.marketCreationPaused(), false);
      });

      it('Should stay Resume Market Creation if already resumed', async function() {
        assert.equal(await allMarkets.marketCreationPaused(), false);
        let actionHash = encode(
          'resumeMarketCreation()'
        );
        await assertRevert(allMarkets.resumeMarketCreation());
        assert.equal(await allMarkets.marketCreationPaused(), false);
      });

      it('Transfer Plotus Assets(PlotusToken)', async function() {
        let plbalPlot = await plotTok.balanceOf(mcr.address);
        await plotTok.burnTokens(mcr.address, plbalPlot);
        await plotTok.transfer(mcr.address, 1000000000000);
        plbalPlot = await plotTok.balanceOf(mcr.address);
        let userbalPlot = await plotTok.balanceOf(newAB);
        await mcr.transferAssets(plotTok.address, newAB, 1000000000000);
        let actionHash = encode(
          'transferAssets(address,address,uint256)',
          plotTok.address,
          newAB,
          1000000000000
        );

        let plbalPlotAfter = await plotTok.balanceOf(mcr.address);
        let userbalPlotAfter = await plotTok.balanceOf(newAB);
        assert.equal(plbalPlot/1 - plbalPlotAfter/1, 1000000000000);
        assert.equal(userbalPlotAfter/1 - userbalPlot/1, 1000000000000);
      });

    after(async function () {
      await revertSnapshot(snapshotId);
    });
  });
  }
);