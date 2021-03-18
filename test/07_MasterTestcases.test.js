const Master = artifacts.require('Master');
const AllMarkets = artifacts.require("AllMarkets");
const Referral = artifacts.require("Referral");
const UserLevels = artifacts.require("UserLevels");
const DisputeResolution = artifacts.require("DisputeResolution");
const CyclicMarkets = artifacts.require("CyclicMarkets");
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
    rf = await Referral.at(await ms.getLatestAddress(toHex("RF")));
    ul = await UserLevels.at(await ms.getLatestAddress(toHex("UL")));
    dr = await DisputeResolution.at(await ms.getLatestAddress(toHex("DR")));
    cm = await CyclicMarkets.at(await ms.getLatestAddress(toHex("CM")));
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
          [toHex('UL')],
          [ul.address, allMarkets.address]
        ]
      );

      await assertRevert(ms.upgradeMultipleImplementations([toHex('UL')],
                [ul.address, allMarkets.address]));
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
        mas.initiateMaster([mas.address, mas.address, mas.address, mas.address, mas.address, mas.address, mas.address, mas.address], mas.address, mas.address, mas.address, {from: newOwner})
      );
      await assertRevert(rf.setMasterAddress(mas.address, mas.address));
    });
    it('Should revert if caller is default address passed is null address', async function() {
      mas = await Master.new();
      mas = await OwnedUpgradeabilityProxy.new(mas.address);
      mas = await Master.at(mas.address);
      await assertRevert(
        mas.initiateMaster([mas.address, mas.address, mas.address, mas.address, mas.address, mas.address, mas.address, mas.address], mas.address, ZERO_ADDRESS, mas.address)
      );
    });
    it('Should revert if caller is multisig auth address passed is null address', async function() {
      mas = await Master.new();
      mas = await OwnedUpgradeabilityProxy.new(mas.address);
      mas = await Master.at(mas.address);
      await assertRevert(
        mas.initiateMaster([mas.address, mas.address, mas.address, mas.address, mas.address, mas.address, mas.address, mas.address], mas.address, mas.address, ZERO_ADDRESS)
      );
    });
    it('Should revert if length of implementation array and contract array are not same', async function() {
      await assertRevert(
        mas.initiateMaster([mas.address, mas.address, mas.address, mas.address], mas.address, mas.address, mas.address)
      );
    });
    it('Should revert if master already initiated', async function() {
      await assertRevert(
        ms.initiateMaster([mas.address, mas.address, mas.address, mas.address, mas.address, mas.address, mas.address, mas.address], mas.address, mas.address, mas.address, {from: newOwner})
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

    it('Check if other contract is working after updating master', async function() {
      await cm.updateUintParameters(toHex("CPW"),65);
      assert.equal(
        (await cm.getUintParameters(toHex('CPW')))[1].toNumber(),
        65
      );
    });

    it('Sending funds to funds to master', async function() {
      await plotTok.transfer(ms.address, toWei(1));
      await plotTok.transfer(allMarkets.address, toWei(1));
    });


    it('Upgrade multiple contract implemenations', async function() {
      oldAM = await AllMarkets.at(
        await ms.getLatestAddress(toHex('AM'))
      );
      oldCM = await CyclicMarkets.at(
        await ms.getLatestAddress(toHex('CM'))
      );
      oldDR = await DisputeResolution.at(
        await ms.getLatestAddress(toHex('DR'))
      );
      oldRF = await Referral.at(
        await ms.getLatestAddress(toHex('RF'))
      );
      oldUL = await UserLevels.at(
        await ms.getLatestAddress(toHex('UL'))
      );
      let plbalPlot = await plotTok.balanceOf(
        await ms.getLatestAddress(toHex('MC'))
      );
      let relayerFeePercent = (await oldCM.getUintParameters(toHex("DAOF")))[1];
      let newAllMarkets = await AllMarkets.new();
      await increaseTime(100);
      let newDR = await DisputeResolution.new();
      let newCM = await CyclicMarkets.new();
      let newRF = await Referral.new();
      let newUL = await UserLevels.new();

      await ms.upgradeMultipleImplementations(
          [toHex('AM'), toHex("CM"), toHex("DR"), toHex("RF"), toHex("UL")],
          [newAllMarkets.address, newCM.address, newDR.address, newRF.address, newUL.address]
      );

      let oldAMImpl = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('AM'))
      );
      let oldCMImpl = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('CM'))
      );
      let oldDRImpl = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('DR'))
      );
      let oldRFImpl = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('RF'))
      );
      let oldULImpl = await OwnedUpgradeabilityProxy.at(
        await ms.getLatestAddress(toHex('UL'))
      );

      // Checking Upgraded Contract addresses
      assert.equal(newDR.address, await oldDRImpl.implementation());
      assert.equal(newCM.address, await oldCMImpl.implementation());
      assert.equal(newRF.address, await oldRFImpl.implementation());
      assert.equal(newUL.address, await oldULImpl.implementation());
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
      assert.equal(((await oldCM.getUintParameters(toHex("DAOF")))[1]).toString(), relayerFeePercent.toString());
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