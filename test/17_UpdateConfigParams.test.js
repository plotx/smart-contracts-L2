const Master = artifacts.require('Master');
const AllMarkets = artifacts.require('MockAllMarkets');
const CyclicMarkets = artifacts.require('CyclicMarkets');
const CyclicMarkets_2 = artifacts.require('CyclicMarkets_2');
const AcyclicMarkets = artifacts.require('AcyclicMarkets');
const DisputeResolution = artifacts.require('DisputeResolution');
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

      let cyclicMarketsV2Impl = await CyclicMarkets_2.new();
			await ms.upgradeMultipleImplementations([toHex("CM")], [cyclicMarketsV2Impl.address]);
			cyclicMarkets = await CyclicMarkets_2.at(await ms.getLatestAddress(web3.utils.toHex("CM")));

      allMarkets = await AllMarkets.at(await ms.getLatestAddress(toHex('AM')));
      cyclicMarkets = await CyclicMarkets.at(await ms.getLatestAddress(toHex('CM')));
      acyclicMarkets = await AcyclicMarkets.at(await ms.getLatestAddress(toHex('AC')));
      disputeResolution = await DisputeResolution.at(await ms.getLatestAddress(toHex('DR')));
      plotTok = await PlotusToken.deployed();
      feedInstance = await MockchainLink.deployed();
      multiSigWallet = await MultiSigWallet.new([accounts[0], accounts[1], accounts[2]],3);
      await allMarkets.changeAuthorizedAddress(multiSigWallet.address);
      await cyclicMarkets.changeAuthorizedAddress(multiSigWallet.address);
      await acyclicMarkets.changeAuthorizedAddress(multiSigWallet.address);
      await disputeResolution.changeAuthorizedAddress(multiSigWallet.address);
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


    describe('Update Cyclic Markets Parameters', async function() {
      it('Should update Cummulative fee percent', async function() {
        await updateParameter( 'CMFP', cyclicMarkets, 'uint', '5300');
        let confirmedBy = await multiSigWallet.getConfirmations(0);
        for(let i = 0; i<3;i++) {
          assert.equal(confirmedBy[i],accounts[i]);
        }
      });
      it('Should update DAO fee percent', async function() {
        await updateParameter( 'DAOF', cyclicMarkets, 'uint', '2500');
        let transactions = await multiSigWallet.getTransactionIds(0,2, true, true);
        assert.equal(transactions.length,2);
      });
      it('Should update Market creator fee percent', async function() {
        await updateParameter( 'MCF', cyclicMarkets, 'uint', '1000');
      });
      it('Should update Referrer fee percent', async function() {
        await updateParameter( 'RFRRF', cyclicMarkets, 'uint', '2600');
      });
      it('Should update Referee fee percent', async function() {
        await updateParameter( 'RFREF', cyclicMarkets, 'uint', '1500');
      });
      it('Should update minimum prediction amount', async function() {
        await updateParameter( 'MINP', cyclicMarkets, 'uint', '123');
      });
      it('Should update maximum prediction amount', async function() {
        await updateParameter( 'MAXP', cyclicMarkets, 'uint', '123');
      });
      it('Should update Current price weightage', async function() {
        await updateParameter( 'CPW', cyclicMarkets, 'uint', '23');
      });
      it('Should update Staking factor min stake', async function() {
        await updateParameter( 'SFMS', cyclicMarkets, 'uint', '123');
      });
      it('Should update reward pool share', async function() {
        await updateParameter( 'RPS', cyclicMarkets, 'uint', '20');
      });
      // it('Should update Multisig address', async function() {
      //   await updateParameter(26, 2, 'MULSIG', allMarkets, 'address', allMarkets.address, "authorizedMultiSig()", true);
      // });
      // it('Should not update Multisig address if invalid code passed', async function() {
      //   await updateParameter(26, 2, 'BULSIG', allMarkets, 'address', tc.address, "authorizedMultiSig()", false);
      // });
      it('Should not update if Cummulative fee percent is >= 100', async function() {
        await updateInvalidParameter('CMFP', cyclicMarkets, 'uint', '11000');
      });
      it('Should not update if total fee percents >= 100', async function() {
        await updateInvalidParameter('DAOF', cyclicMarkets, 'uint', '8000');
      });
      it('Should not update if total fee percents >= 100', async function() {
        await updateInvalidParameter('MCF', cyclicMarkets, 'uint', '7000');
      });
      it('Should not update if parameter code is incorrect', async function() {
        await updateInvalidParameter('EPTIM', cyclicMarkets, 'uint', '2');
      });
      it('Should not update if parameter code is incorrect', async function() {
        await updateInvalidParameter('EPTIM', cyclicMarkets, 'uint', '2');
      });
      it('Should not update if Current price weightage > 100', async function() {
        await updateInvalidParameter('CPW', cyclicMarkets, 'uint', '200');
      });
      it('Should not update if reward pool share > 100', async function() {
        await updateInvalidParameter('RPS', cyclicMarkets, 'uint', '200');
      });
    });

    // describe('Update Acyclic Markets Parameters', async function() {
    //   it('Should update Cummulative fee percent', async function() {
    //     await updateParameter( 'CMFP', acyclicMarkets, 'uint', '5300');
    //     let confirmedBy = await multiSigWallet.getConfirmations(0);
    //     for(let i = 0; i<3;i++) {
    //       assert.equal(confirmedBy[i],accounts[i]);
    //     }
    //   });
    //   it('Should update DAO fee percent', async function() {
    //     await updateParameter( 'DAOF', acyclicMarkets, 'uint', '2500');
    //     let transactions = await multiSigWallet.getTransactionIds(0,2, true, true);
    //     assert.equal(transactions.length,2);
    //   });
    //   it('Should update Market creator fee percent', async function() {
    //     await updateParameter( 'MCF', acyclicMarkets, 'uint', '1000');
    //   });
    //   it('Should update Referrer fee percent', async function() {
    //     await updateParameter( 'RFRRF', acyclicMarkets, 'uint', '2600');
    //   });
    //   it('Should update Referee fee percent', async function() {
    //     await updateParameter( 'RFREF', acyclicMarkets, 'uint', '1500');
    //   });
    //   it('Should update minimum prediction amount', async function() {
    //     await updateParameter( 'MINP', acyclicMarkets, 'uint', '123');
    //   });
    //   it('Should update maximum prediction amount', async function() {
    //     await updateParameter( 'MAXP', acyclicMarkets, 'uint', '123');
    //   });
    //   it('Should update Current price weightage', async function() {
    //     await updateParameter( 'CPW', acyclicMarkets, 'uint', '23');
    //   });
    //   it('Should update Staking factor min stake', async function() {
    //     await updateParameter( 'SFMS', acyclicMarkets, 'uint', '123');
    //   });
    //   it('Should not update if Cummulative fee percent is >= 100', async function() {
    //     await updateInvalidParameter('CMFP', acyclicMarkets, 'uint', '11000');
    //   });
    //   it('Should not update if total fee percents >= 100', async function() {
    //     await updateInvalidParameter('DAOF', acyclicMarkets, 'uint', '8000');
    //   });
    //   it('Should not update if total fee percents >= 100', async function() {
    //     await updateInvalidParameter('MCF', acyclicMarkets, 'uint', '7000');
    //   });
    //   it('Should not update if parameter code is incorrect', async function() {
    //     await updateInvalidParameter('EPTIM', acyclicMarkets, 'uint', '2');
    //   });
    //   it('Should not update if parameter code is incorrect', async function() {
    //     await updateInvalidParameter('EPTIM', acyclicMarkets, 'uint', '2');
    //   });
    //   it('Should not update if Current price weightage > 100', async function() {
    //     await updateInvalidParameter('CPW', acyclicMarkets, 'uint', '200');
    //   });
    // })

    // describe('Update Dispute Resolution Parameters', async function() {
    //   it('Should update tokenStakeForDispute', async function() {
    //     await updateParameter( 'TSD', disputeResolution, 'uint', '5300');
    //   });
    //   it('Should update rewardForVoting', async function() {
    //     await updateParameter( 'REWARD', disputeResolution, 'uint', '2500');
    //   });
    //   it('Should update drTokenLockPeriod', async function() {
    //     await updateParameter( 'DRLOCKP', disputeResolution, 'uint', '1000');
    //   });
    //   it('Should update voteThresholdMultiplier', async function() {
    //     await updateParameter( 'THMUL', disputeResolution, 'uint', '2600');
    //   });
    //   it('Should update drVotePeriod', async function() {
    //     await updateParameter( 'VOTETIME', disputeResolution, 'uint', '1500');
    //   });
    //   it('Should not update if parameter code is incorrect', async function() {
    //     await updateInvalidParameter('ASDF', disputeResolution, 'uint', '2');
    //   });
    // })

    // describe("MultisigWallet", async function() {
    //   it('Should not add owner if zero address passed', async function() {
    //     let data = await encode3("addOwner(address)",ZERO_ADDRESS);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, false);
    //     assert.equal(await multiSigWallet.isOwner(ZERO_ADDRESS), false);
    //   });
    //   it('Should add owner', async function() {
    //     let data = await encode3("addOwner(address)",accounts[3]);
    //     await assertRevert(multiSigWallet.addOwner(accounts[3]));
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, true);
    //     assert.equal(await multiSigWallet.isOwner(accounts[3]), true);
    //   });
    //   it('Should add owner', async function() {
    //     let data = await encode3("addOwner(address)",accounts[10]);
    //     await assertRevert(multiSigWallet.addOwner(accounts[3]));
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, true);
    //     assert.equal(await multiSigWallet.isOwner(accounts[10]), true);
    //   });
    //   it('Should not add owner twice', async function() {
    //     let data = await encode3("addOwner(address)",accounts[3]);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, false);
    //   });
    //   it('Cannot replace owner with another existing owner', async function() {
    //     let data = await encode3("replaceOwner(address,address)",accounts[3], accounts[3]);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.confirmTransaction(transactionCount/1 - 1, {from:accounts[1]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1 - 1, {from:accounts[2]});
    //     let status = await multiSigWallet.transactions(transactionCount - 1);
    //     assert.equal(status.executed, false);
    //   });
    //   it('Cannot replace if the provided owner doesnt exist', async function() {
    //     let data = await encode3("replaceOwner(address,address)",accounts[6], accounts[4]);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, false);
    //     assert.equal(await multiSigWallet.isOwner(accounts[4]), false);
    //     assert.equal(await multiSigWallet.isOwner(accounts[6]), false);
    //   });
    //   it('Should replace owner', async function() {
    //     let data = await encode3("replaceOwner(address,address)",accounts[3], accounts[4]);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, true);
    //     assert.equal(await multiSigWallet.isOwner(accounts[4]), true);
    //   });
    //   it('Should be able to change requirement for confirmation', async function() {
    //     let data = await encode3("changeRequirement(uint256)",4);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await assertRevert(multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]}));
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
    //     await assertRevert(multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]}));
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, true);
    //     assert.equal(await multiSigWallet.required(), 4);
    //   });
    //   it('Should remove owner', async function() {
    //     let data = await encode3("removeOwner(address)",accounts[2]);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await assertRevert(multiSigWallet.revokeConfirmation(transactionCount/1, {from:accounts[10]}));
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[10]});
    //     await multiSigWallet.revokeConfirmation(transactionCount/1, {from:accounts[10]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[2]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[4]});
    //     await assertRevert(multiSigWallet.revokeConfirmation(transactionCount/1, {from:accounts[4]}));
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, true);
    //     assert.equal(await multiSigWallet.isOwner(accounts[2]), false);
    //   });
    //   it('Should remove owner', async function() {
    //     let data = await encode3("removeOwner(address)",accounts[4]);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[10]});
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[4]});
    //     await assertRevert(multiSigWallet.revokeConfirmation(transactionCount/1, {from:accounts[4]}));
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, true);
    //     assert.equal(await multiSigWallet.isOwner(accounts[4]), false);
    //   });
    //   it('Should not execute if tried to remove address which is not owner', async function() {
    //     assert.equal(await multiSigWallet.isOwner(accounts[3]), false);
    //     let data = await encode3("removeOwner(address)",accounts[3]);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     let transactions = await multiSigWallet.getTransactionIds(0,transactionCount , true, true);
    //     assert.equal(transactions.length,transactionCount);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[10]});
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, false);
    //   });
    //   it('Should not be able to change requirement if requirement > current owners length', async function() {
    //     let data = await encode3("changeRequirement(uint256)",10);
    //     let transactionCount = await multiSigWallet.getTransactionCount(true, true);
    //     await multiSigWallet.submitTransaction(multiSigWallet.address, 0, data);
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[1]});
    //     await assertRevert(multiSigWallet.confirmTransaction(60, {from:accounts[10]}));
    //     await multiSigWallet.confirmTransaction(transactionCount/1, {from:accounts[10]});
    //     let status = await multiSigWallet.transactions(transactionCount);
    //     assert.equal(status.executed, false);
    //     assert.equal(await multiSigWallet.required(),3);
    //   });
    // });

    after(async function () {
      await revertSnapshot(snapshotId);
    });

  }
);