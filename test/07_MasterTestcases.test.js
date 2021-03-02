const Master = artifacts.require('Master');
const AllMarkets = artifacts.require("AllMarkets");
const MarketCreationRewards = artifacts.require("MarketCreationRewards");
const DisputeResolution = artifacts.require("DisputeResolution");
const ParticipationMining = artifacts.require("ParticipationMining");
const PlotusToken = artifacts.require("MockPLOT");
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const NewProxyInternalContract = artifacts.require('NewProxyInternalContract');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

const {ether, toHex, toWei} = require('./utils/ethTools');
const {increaseTime, duration} = require('./utils/increaseTime');
const {assertRevert} = require('./utils/assertRevert');
const gvProp = require('./utils/gvProposal.js').gvProposalWithIncentiveViaTokenHolder;
const encode = require('./utils/encoder.js').encode;
const encode1 = require('./utils/encoder.js').encode1;
const { takeSnapshot, revertSnapshot } = require('./utils/snapshot');

const BN = web3.utils.BN;


let ms;
let tc;
let addr = [];
let memberRoles;
let gov;
let propCat;
let nxmMas;
let allMarkets;
let plotTok;
let snapshotId;

contract('Master', function(accounts) {

  const [owner, newOwner, govVoter4] = accounts;

  before(async function() {

    snapshotId = await takeSnapshot();
    plotTok = await PlotusToken.deployed();
    ms = await OwnedUpgradeabilityProxy.deployed();
    ms = await Master.at(ms.address);
    allMarkets = await AllMarkets.at(await ms.getLatestAddress(toHex('AM')));
    mcr = await MarketCreationRewards.at(await ms.getLatestAddress(toHex("MC")));
    dr = await DisputeResolution.at(await ms.getLatestAddress(toHex("DR")));
    pm = await ParticipationMining.at(await ms.getLatestAddress(toHex("PM")));
  });

    describe('Negative Test Cases', function() {
    it('Upgrade contract should revert if called directly by unauthorized address', async function() {
      await assertRevert(
        ms.upgradeMultipleImplementations([toHex('AM')], [allMarkets.address], {from: accounts[1]})
      );
    });
    it('Upgrade contract should revert if array length is different for contract code and address', async function() {
      actionHash = encode1(
        ['bytes2[]', 'address[]'],
        [
          [toHex('MC')],
          [mcr.address, allMarkets.address]
        ]
      );

      await assertRevert(ms.upgradeMultipleImplementations([toHex('MC')],
                [mcr.address, allMarkets.address]));
      // await gvProp(
      //   6,
      //   actionHash,
      //   await MemberRoles.at(await ms.getLatestAddress(toHex('MR'))),
      //   await Governance.at(await ms.getLatestAddress(toHex('GV'))),
      //   2,
      //   0
      // );
    });
    it('Add internal contract should revert if called directly', async function() {
      let ps = await AllMarkets.new();
      await assertRevert(
        ms.addNewContract(toHex('PS'), ps.address, {from:accounts[1]})
      );
    });
    it('Add internal contract should revert if contract address already exists', async function() {
      await assertRevert(
        ms.addNewContract(toHex('PS'), allMarkets.address)
      );
    });
    it('Add internal contract should revert if new contract code already exist', async function() {
      await assertRevert(
        ms.addNewContract(toHex('AM'), allMarkets.address)
      );
    });
    it('Add internal contract should revert if new contract address is null', async function() {
      await assertRevert(
        ms.addNewContract(toHex('AZ'), ZERO_ADDRESS)
      );
    });
    it('Add internal contract should revert if new contract code is MS', async function() {
      let ps = await AllMarkets.new();
      await assertRevert(
        ms.addNewContract(toHex('MS'), ps.address)
      );
    });
    it('Upgrade contract implementation should revert if new address is null', async function() {
      await assertRevert(ms.upgradeMultipleImplementations([toHex("GV")],[ZERO_ADDRESS]));
    });
    it('Should revert if caller is not proxyOwner', async function() {
      mas = await Master.new();
      mas = await OwnedUpgradeabilityProxy.new(mas.address);
      mas = await Master.at(mas.address);
      await assertRevert(
        mas.initiateMaster([mas.address, mas.address, mas.address, mas.address, mas.address], mas.address, mas.address, mas.address, {from: newOwner})
      );
    });
    it('Should revert if length of implementation array and contract array are not same', async function() {
      await assertRevert(
        mas.initiateMaster([mas.address, mas.address, mas.address], mas.address, mas.address, mas.address)
      );
    });
    it('Should revert if master already initiated', async function() {
      await assertRevert(
        ms.initiateMaster([mas.address, mas.address, mas.address, mas.address, mas.address], mas.address, mas.address, mas.address, {from: newOwner})
      );
    });
  });

  describe('Update master address', function() {
    it('Update master address', async function() {
      let newMaster = await Master.new();
      let actionHash = encode1(['address'], [newMaster.address]);
      let implInc = await OwnedUpgradeabilityProxy.at(ms.address);
      await implInc.upgradeTo(newMaster.address);
      // let implInc = await OwnedUpgradeabilityProxy.at(ms.address);
      assert.equal(await implInc.implementation(), newMaster.address);
    });

    it('Create a sample proposal after updating master', async function() {
      let actionHash = encode(
        'updateUintParameters(bytes8,uint256)',
        toHex('REJCOUNT'),
        2
      );
      await allMarkets.updateUintParameters(toHex("MDPA"),65);
      assert.equal(
        (await allMarkets.getUintParameters(toHex('MDPA')))[1].toNumber(),
        65
      );
    });

    it('Sending funds to funds to MCR', async function() {
      mcr = await MarketCreationRewards.at(
        await ms.getLatestAddress(toHex('MC'))
      );
      await plotTok.transfer(mcr.address, toWei(1));
      await plotTok.transfer(allMarkets.address, toWei(1));
    });


    it('Upgrade multiple contract implemenations', async function() {
      oldAM = await AllMarkets.at(
        await ms.getLatestAddress(toHex('AM'))
      );
      oldMCR = await MarketCreationRewards.at(
        await ms.getLatestAddress(toHex('MC'))
      );
      oldPM = await ParticipationMining.at(
        await ms.getLatestAddress(toHex('PM'))
      );
      oldDR = await ParticipationMining.at(
        await ms.getLatestAddress(toHex('DR'))
      );
      let plbalPlot = await plotTok.balanceOf(
        await ms.getLatestAddress(toHex('MC'))
      );
      let relayerFeePercent = (await oldAM.getUintParameters(toHex("DAOF")))[1];
      let newAllMarkets = await AllMarkets.new();
      await increaseTime(100);
      let newMC = await MarketCreationRewards.new();
      let newDR = await DisputeResolution.new();
      let newPM = await ParticipationMining.new();
      actionHash = encode1(
        ['bytes2[]', 'address[]'],
        [
          [toHex('AM'), toHex("MC"), toHex("PM"), toHex("DR")],
          [newAllMarkets.address, newMC.address, newPM.address, newDR.address]
        ]
      );
      await ms.upgradeMultipleImplementations(
        [toHex('AM'), toHex("MC"), toHex("PM"), toHex("DR")],
          [newAllMarkets.address, newMC.address, newPM.address, newDR.address]
      );

      let oldAMImpl = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('AM'))
      );
      let oldMCImpl = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('MC'))
      );
      let oldPMImpl = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('PM'))
      );
      let oldDRImpl = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('DR'))
      );

      // Checking Upgraded Contract addresses
      assert.equal(newMC.address, await oldMCImpl.implementation());
      assert.equal(newDR.address, await oldDRImpl.implementation());
      assert.equal(newPM.address, await oldPMImpl.implementation());
      assert.equal(newAllMarkets.address, await oldAMImpl.implementation());
      
      // Checking Master address in upgraded Contracts
      // assert.equal(ms.address, await oldAM.masterAddress());
      // assert.equal(ms.address, await oldMCR.masterAddress());
      // assert.equal(ms.address, await oldDR.masterAddress());
      // assert.equal(ms.address, await oldPM.masterAddress());
      
      // Checking Funds transfer in upgraded Contracts
      assert.equal(
        (await plotTok.balanceOf(await ms.getLatestAddress(toHex('MC')))) / 1,
        plbalPlot / 1
      );

      // Checking getters in upgraded Contracts
      assert.equal(((await oldAM.getUintParameters(toHex("DAOF")))[1]).toString(), relayerFeePercent.toString());
    });
    it('Add new Proxy Internal contract', async function() {
      let nic = await NewProxyInternalContract.new();
      // Creating proposal for adding new proxy internal contract
      actionHash = encode1(
        ['bytes2','address'],
        [toHex('NP'),
        nic.address]
      );
      await ms.addNewContract(
        toHex('NP'),
        nic.address
      );
      let proxyINS = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('NP'))
      );
      assert.equal(nic.address, await proxyINS.implementation());

      proxyINS = await NewProxyInternalContract.at(proxyINS.address);
      
      assert.equal(ms.address, await proxyINS.ms());
      assert.equal(await ms.isInternal(nic.address), false);
      assert.equal(await ms.isInternal(proxyINS.address), true);
      // assert.notEqual(await tc.bit(), 200);
      // await proxyINS.callDummyOnlyInternalFunction(200);
      // assert.equal(await tc.bit(), 200);
    });
    // it('Check if new master is updated properly', async function() {
    //   let amProxy = await AllMarkets.at(
    //     await ms.getLatestAddress(toHex('AM'))
    //   );
    //   assert.equal(ms.address, await amProxy.masterAddress());
    // });
  });

  after(async function () {
    await revertSnapshot(snapshotId);
  });

});