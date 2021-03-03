const Master = artifacts.require('Master');
const AllMarkets = artifacts.require('AllMarkets');
const PlotusToken = artifacts.require("MockPLOT");
const MockchainLink = artifacts.require('MockChainLinkAggregator');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const gvProposal = require('./utils/gvProposal.js').gvProposalWithIncentiveViaTokenHolder;
const encode = require('./utils/encoder.js').encode;
const assertRevert = require("./utils/assertRevert").assertRevert;
const {toHex, toWei, toChecksumAddress} = require('./utils/ethTools');
const { takeSnapshot, revertSnapshot } = require('./utils/snapshot');


let gv;
let pc;
let mr;
let tc;
let ms;
let pl;
let marketConfig;
let plotTok;
let feedInstance;
let snapshotId;

const maxAllowance = '115792089237316195423570985008687907853269984665640564039457584007913129639935';
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

contract('Configure Global Parameters', accounts => {

    const [ab1] = accounts;

    before(async function() {

      snapshotId = await takeSnapshot();
      ms = await OwnedUpgradeabilityProxy.deployed();
      ms = await Master.at(ms.address);
      allMarkets = await AllMarkets.at(await ms.getLatestAddress(toHex('AM')));
      plotTok = await PlotusToken.deployed();
      feedInstance = await MockchainLink.deployed()

    });

    async function updateParameter(
      cId,
      mrSequence,
      code,
      contractInst,
      type,
      proposedValue,
      getFunction,
      actionStatus
    ) {
      code = toHex(code);
      let getterFunction;
      if (type == 'uint') {
        action = 'updateUintParameters(bytes8,uint)';
        functionToCall = 'updateUintParameters';
        getterFunction = 'getUintParameters';
      } else if (type == 'address') {
        action = 'updateAddressParameters(bytes8,address)';
        functionToCall = 'updateAddressParameters';
        getterFunction = getFunction;
      } else if (type == 'configUint') {
        action = 'updateConfigUintParameters(bytes8,uint256)';
        functionToCall = 'updateConfigUintParameters';
        getterFunction = '';
      }

      await contractInst[functionToCall](code, proposedValue);

      // let actionHash = encode(action, code, proposedValue);
      // await gvProposal(cId, actionHash, mr, gv, mrSequence, 0);
      if (code == toHex('MASTADD')) {
        let newMaster = await NXMaster.at(proposedValue);
        contractInst = newMaster;
      }
      let parameter;
      if(type == 'uint') {
        parameter = await contractInst[getterFunction](code);
      }
      try {
        parameter[1] = parameter[1].toNumber();
      } catch (err) {}
      if(type == 'uint') {
        assert.equal(parameter[1], proposedValue, 'Not updated');
      }
      if(type == 'address') {
        parameter = await contractInst.authorized();
        if(actionStatus) {
          assert.equal(parameter, proposedValue, 'Not updated');
        } else {
          assert.notEqual(parameter, proposedValue, 'Updated');
        }
      }
    }
    async function updateInvalidParameter(
      cId,
      mrSequence,
      code,
      contractInst,
      type,
      proposedValue
    ) {
      code = toHex(code);
      let getterFunction;
      if (type == 'uint') {
        functionToCall = 'updateUintParameters';
        action = 'updateUintParameters(bytes8,uint)';
        getterFunction = 'getUintParameters';
      }
      await assertRevert(contractInst[functionToCall](code, proposedValue));
      // let actionHash = encode(action, code, proposedValue);
      // await gvProposal(cId, actionHash, mr, gv, mrSequence, 0);
      if (code == toHex('MASTADD') && proposedValue != ZERO_ADDRESS) {
        let newMaster = await NXMaster.at(proposedValue);
        contractInst = newMaster;
      }
      let parameter = await contractInst[getterFunction](code);
      try {
        parameter[1] = parameter[1].toNumber();
      } catch (err) {}
      assert.notEqual(parameter[1], proposedValue);
    }



    // describe('Update Market Config Params', function() {

    //   it('Should update Min PredictionAmount', async function() {
    //     await updateParameter(24, 2, 'MINPRD', marketConfig, 'configUint', 75);
    //     let configData = await marketConfig.getBasicMarketDetails();
    //     assert.equal(configData[0], 75, 'Not updated');
    //   });

    //   it('Should update Max PredictionAmount', async function() {
    //     await updateParameter(24, 2, 'MAXPRD', marketConfig, 'configUint', 80);
    //     let configData = await marketConfig.getBasicMarketDetails();
    //     assert.equal(configData[2]/1, 80, 'Not updated');
    //   });

    //   it('Should update Position Decimals', async function() {
    //     await updateParameter(24, 2, 'PDEC', marketConfig, 'configUint', 19);
    //     let configData = await marketConfig.getBasicMarketDetails();
    //     assert.equal(configData[1]/1, 19, 'Not updated');
    //   });

    //   it('Should update Token Stake For Dispute', async function() {
    //     await updateParameter(24, 2, 'TSDISP', pl, 'configUint', 26);
    //     let configData = await marketConfig.getDisputeResolutionParams();
    //     assert.equal(configData, 26, 'Not updated');
    //   });

    //   it('Should update Min Stake For Multiplier', async function() {
    //     await updateParameter(24, 2, 'SFMS', marketConfig, 'configUint', 23);
    //     let configData = await marketConfig.getPriceCalculationParams();
    //     assert.equal(configData[0], 23, 'Not updated');
    //   });

    //   it('Should Staking Factor Weightage and Current Price weightage', async function() {
    //     await updateParameter(24, 2, 'SFCPW', marketConfig, 'configUint', 24);
    //     let configData = await marketConfig.getPriceCalculationParams();
    //     assert.equal(configData[1], 24, 'Not updated');
    //     assert.equal(configData[2], 100-24, 'Not updated');
    //   });

    //   it('Should not update if invalid code is passed', async function() {
    //     await updateParameter(24, 2, 'CDTIM1', pl, 'configUint', 28);
    //   });

    //   it('Should not allow to update if unauthorized call', async function() {
    //     await assertRevert(marketConfig.updateUintParameters(toHex("UNIFAC"),100));
    //   });


    // });

    describe('Update AllMarkets Parameters', function() {
      it('Should update Cummulative fee percent', async function() {
        await updateParameter(19, 2, 'CMFP', allMarkets, 'uint', '5300');
      });
      it('Should update DAO fee percent', async function() {
        await updateParameter(19, 2, 'DAOF', allMarkets, 'uint', '2500');
      });
      it('Should update Market creator fee percent', async function() {
        await updateParameter(19, 2, 'MCF', allMarkets, 'uint', '1000');
      });
      it('Should update Referrer fee percent', async function() {
        await updateParameter(19, 2, 'RFRRF', allMarkets, 'uint', '2600');
      });
      it('Should update Referee fee percent', async function() {
        await updateParameter(19, 2, 'RFREF', allMarkets, 'uint', '1500');
      });
      it('Should update Market creator default prediction amount', async function() {
        await updateParameter(19, 2, 'MDPA', allMarkets, 'uint', '123');
      });
      // it('Should update Multisig address', async function() {
      //   await updateParameter(26, 2, 'MULSIG', allMarkets, 'address', allMarkets.address, "authorizedMultiSig()", true);
      // });
      // it('Should not update Multisig address if invalid code passed', async function() {
      //   await updateParameter(26, 2, 'BULSIG', allMarkets, 'address', tc.address, "authorizedMultiSig()", false);
      // });
      it('Should not update if Cummulative fee percent is >= 100', async function() {
        await updateInvalidParameter(19, 2, 'CMFP', allMarkets, 'uint', '11000');
      });
      it('Should not update if total fee percents >= 100', async function() {
        await updateInvalidParameter(19, 2, 'DAOF', allMarkets, 'uint', '8000');
      });
      it('Should not update if total fee percents >= 100', async function() {
        await updateInvalidParameter(19, 2, 'MCF', allMarkets, 'uint', '7000');
      });
      it('Should not update if parameter code is incorrect', async function() {
        await updateInvalidParameter(19, 2, 'EPTIM', allMarkets, 'uint', '2');
      });
    }); 

    after(async function () {
      await revertSnapshot(snapshotId);
    });

  }
);