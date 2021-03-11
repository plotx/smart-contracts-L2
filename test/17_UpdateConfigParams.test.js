const Master = artifacts.require('Master');
const AllMarkets = artifacts.require('AllMarkets');
const CyclicMarkets = artifacts.require('CyclicMarkets');
const PlotusToken = artifacts.require("MockPLOT");
const MockchainLink = artifacts.require('MockChainLinkAggregator');
const MultiSigWallet = artifacts.require('MultiSigWallet');
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const gvProposal = require('./utils/gvProposal.js').gvProposalWithIncentiveViaTokenHolder;
const encode = require('./utils/encoder.js').encode;
const encode3 = require('./utils/encoder.js').encode3;
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
let multiSigtransactionId = 0;
const maxAllowance = '115792089237316195423570985008687907853269984665640564039457584007913129639935';
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

contract('Configure Global Parameters', accounts => {

    const [ab1] = accounts;

    before(async function() {

      snapshotId = await takeSnapshot();
      ms = await OwnedUpgradeabilityProxy.deployed();
      ms = await Master.at(ms.address);
      allMarkets = await AllMarkets.at(await ms.getLatestAddress(toHex('AM')));
      cyclicMarkets = await CyclicMarkets.at(await ms.getLatestAddress(toHex('CM')));
      plotTok = await PlotusToken.deployed();
      feedInstance = await MockchainLink.deployed();
      multiSigWallet = await MultiSigWallet.new([accounts[0], accounts[1], accounts[2]],3);
      await allMarkets.changeAuthorizedAddress(multiSigWallet.address);
      await cyclicMarkets.changeAuthorizedAddress(multiSigWallet.address);
      let owners = await multiSigWallet.getOwners();
      for(let i = 0;i<3;i++) {
        owners[i] = accounts[i];
      }
      multiSigtransactionId = 0;
    });

    async function updateParameter(
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

      let data = encode3(action, code, proposedValue);
      let transactionCount = await multiSigWallet.getTransactionCount(true, true);
      let retVal = await multiSigWallet.submitTransaction(contractInst.address, 0, data);
      await multiSigWallet.confirmTransaction(transactionCount, {from:accounts[1]});
      let confirmationCount = await multiSigWallet.getConfirmationCount(transactionCount);
      assert.equal(confirmationCount, 2);
      await multiSigWallet.confirmTransaction(transactionCount, {from:accounts[2]});
      confirmationCount = await multiSigWallet.getConfirmationCount(transactionCount);
      assert.equal(confirmationCount, 3);
      multiSigtransactionId = transactionCount + 1;
      // await contractInst[functionToCall](code, proposedValue);

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
      let data = encode3(action, code, proposedValue);
      let transactionCount = await multiSigWallet.getTransactionCount(true, true);
      let retVal = await multiSigWallet.submitTransaction(contractInst.address, 0, data);
      await multiSigWallet.confirmTransaction(transactionCount, {from:accounts[1]});
      await multiSigWallet.confirmTransaction(transactionCount, {from:accounts[2]});
      let status = await multiSigWallet.transactions(transactionCount);
      assert.equal(status.executed, false);
      multiSigtransactionId = transactionCount + 1;
      // await assertRevert(contractInst[functionToCall](code, proposedValue));
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


    describe('Update AllMarkets Parameters', async function() {
      it('Should update Cummulative fee percent', async function() {
        await updateParameter( 'CMFP', allMarkets, 'uint', '5300');
        let confirmedBy = await multiSigWallet.getConfirmations(0);
        for(let i = 0; i<3;i++) {
          assert.equal(confirmedBy[i],accounts[i]);
        }
      });
      it('Should update DAO fee percent', async function() {
        await updateParameter( 'DAOF', allMarkets, 'uint', '2500');
        let transactions = await multiSigWallet.getTransactionIds(0,2, true, true);
        assert.equal(transactions.length,2);
      });
      it('Should update Market creator fee percent', async function() {
        await updateParameter( 'MCF', allMarkets, 'uint', '1000');
      });
      it('Should update Referrer fee percent', async function() {
        await updateParameter( 'RFRRF', allMarkets, 'uint', '2600');
      });
      it('Should update Referee fee percent', async function() {
        await updateParameter( 'RFREF', allMarkets, 'uint', '1500');
      });
      it('Should update Market creator default prediction amount', async function() {
        await updateParameter( 'MDPA', allMarkets, 'uint', '123');
      });
      it('Should update minimum prediction amount', async function() {
        await updateParameter( 'MINP', allMarkets, 'uint', '123');
      });
      it('Should update maximum prediction amount', async function() {
        await updateParameter( 'MAXP', allMarkets, 'uint', '123');
      });
      it('Should update Current price weightage', async function() {
        await updateParameter( 'CPW', cyclicMarkets, 'uint', '23');
      });
      it('Should update Staking factor min stake', async function() {
        await updateParameter( 'SFMS', cyclicMarkets, 'uint', '123');
      });
      // it('Should update Multisig address', async function() {
      //   await updateParameter(26, 2, 'MULSIG', allMarkets, 'address', allMarkets.address, "authorizedMultiSig()", true);
      // });
      // it('Should not update Multisig address if invalid code passed', async function() {
      //   await updateParameter(26, 2, 'BULSIG', allMarkets, 'address', tc.address, "authorizedMultiSig()", false);
      // });
      it('Should not update if Cummulative fee percent is >= 100', async function() {
        await updateInvalidParameter('CMFP', allMarkets, 'uint', '11000');
      });
      it('Should not update if total fee percents >= 100', async function() {
        await updateInvalidParameter('DAOF', allMarkets, 'uint', '8000');
      });
      it('Should not update if total fee percents >= 100', async function() {
        await updateInvalidParameter('MCF', allMarkets, 'uint', '7000');
      });
      it('Should not update if parameter code is incorrect', async function() {
        await updateInvalidParameter('EPTIM', allMarkets, 'uint', '2');
      });
      it('Should not update if parameter code is incorrect', async function() {
        await updateInvalidParameter('EPTIM', cyclicMarkets, 'uint', '2');
      });
      it('Should not update if Current price weightage > 100', async function() {
        await updateInvalidParameter('CPW', cyclicMarkets, 'uint', '200');
      });
    }); 

    describe("MultisigWallet", async function() {
      it('Should not add owner if zero address passed', async function() {
        let data = await encode3("addOwner(address)",ZERO_ADDRESS);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, false);
        assert.equal(await multiSigWallet.isOwner(ZERO_ADDRESS), false);
      });
      it('Should add owner', async function() {
        let data = await encode3("addOwner(address)",accounts[3]);
        await assertRevert(multiSigWallet.addOwner(accounts[3]));
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, true);
        assert.equal(await multiSigWallet.isOwner(accounts[3]), true);
      });
      it('Should add owner', async function() {
        let data = await encode3("addOwner(address)",accounts[10]);
        await assertRevert(multiSigWallet.addOwner(accounts[3]));
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, true);
        assert.equal(await multiSigWallet.isOwner(accounts[10]), true);
      });
      it('Should not add owner twice', async function() {
        let data = await encode3("addOwner(address)",accounts[3]);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, false);
      });
      it('Cannot replace owner with another existing owner', async function() {
        let data = await encode3("replaceOwner(address,address)",accounts[3], accounts[3]);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.confirmTransaction(transactionCount/1 - 1, {from:accounts[1]});
        await multiSigWallet.confirmTransaction(transactionCount/1 - 1, {from:accounts[2]});
        let status = await multiSigWallet.transactions(transactionCount - 1);
        assert.equal(status.executed, false);
      });
      it('Cannot replace if the provided owner doesnt exist', async function() {
        let data = await encode3("replaceOwner(address,address)",accounts[6], accounts[4]);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, false);
        assert.equal(await multiSigWallet.isOwner(accounts[4]), false);
        assert.equal(await multiSigWallet.isOwner(accounts[6]), false);
      });
      it('Should replace owner', async function() {
        let data = await encode3("replaceOwner(address,address)",accounts[3], accounts[4]);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, true);
        assert.equal(await multiSigWallet.isOwner(accounts[4]), true);
      });
      it('Should be able to change requirement for confirmation', async function() {
        let data = await encode3("changeRequirement(uint256)",4);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await assertRevert(multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]}));
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
        await assertRevert(multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]}));
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, true);
        assert.equal(await multiSigWallet.required(), 4);
      });
      it('Should remove owner', async function() {
        let data = await encode3("removeOwner(address)",accounts[2]);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await assertRevert(multiSigWallet.revokeConfirmation(transactionCount/1, {from:accounts[10]}));
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[10]});
        await multiSigWallet.revokeConfirmation(transactionCount/1, {from:accounts[10]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[4]});
        await assertRevert(multiSigWallet.revokeConfirmation(transactionCount/1, {from:accounts[4]}));
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, true);
        assert.equal(await multiSigWallet.isOwner(accounts[2]), false);
      });
      it('Should remove owner', async function() {
        let data = await encode3("removeOwner(address)",accounts[4]);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[10]});
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[4]});
        await assertRevert(multiSigWallet.revokeConfirmation(transactionCount/1, {from:accounts[4]}));
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, true);
        assert.equal(await multiSigWallet.isOwner(accounts[4]), false);
      });
      it('Should not execute if tried to remove address which is not owner', async function() {
        assert.equal(await multiSigWallet.isOwner(accounts[3]), false);
        let data = await encode3("removeOwner(address)",accounts[3]);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        let transactions = await multiSigWallet.getTransactionIds(0,transactionCount , true, true);
        assert.equal(transactions.length,transactionCount);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[10]});
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, false);
      });
      it('Should not be able to change requirement if requirement > current owners length', async function() {
        let data = await encode3("changeRequirement(uint256)",10);
        let transactionCount = await multiSigWallet.getTransactionCount(true, true);
        await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
        await assertRevert(multiSigWallet.confirmTransaction(60, {from:accounts[10]}));
        await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[10]});
        let status = await multiSigWallet.transactions(transactionCount);
        assert.equal(status.executed, false);
        assert.equal(await multiSigWallet.required(),3);
      });
    });

    after(async function () {
      await revertSnapshot(snapshotId);
    });

  }
);