const { assert } = require("chai");

const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const BLOT = artifacts.require("BPLOT");
const AllMarkets = artifacts.require("MockAllMarkets");
const AcyclicMarkets = artifacts.require("MockAcyclicMarkets");
const Referral = artifacts.require("Referral");
const DisputeResolution = artifacts.require('DisputeResolution');
const BigNumber = require("bignumber.js");
const { increaseTimeTo } = require("./utils/increaseTime.js");
const encode1 = require('./utils/encoder.js').encode1;
const encode3 = require("./utils/encoder.js").encode3;
const signAndExecuteMetaTx = require("./utils/signAndExecuteMetaTx.js").signAndExecuteMetaTx;
const BN = require('bn.js');

const assertRevert = require("./utils/assertRevert.js").assertRevert;
const increaseTime = require("./utils/increaseTime.js").increaseTime;
const latestTime = require("./utils/latestTime.js").latestTime;
const encode = require("./utils/encoder.js").encode;
const gvProposal = require("./utils/gvProposal.js").gvProposalWithIncentiveViaTokenHolder;
const { toHex, toWei, toChecksumAddress } = require("./utils/ethTools");
// get etherum accounts
// swap ether with LOT
let timeNow,
	marketData,
	expireTme,
	priceOption1,
	priceOption2,
	priceOption3,
	option1RangeMIN,
	option1RangeMAX,
	option2RangeMIN,
	option2RangeMAX,
	option3RangeMIX,
	marketStatus,
	option3RangeMAX,
	disputeResolution,
	marketETHBalanceBeforeDispute,
	marketIncentives;



let privateKeyList = ["fb437e3e01939d9d4fef43138249f23dc1d0852e69b0b5d1647c087f869fabbd","7c85a1f1da3120c941b83d71a154199ee763307683f206b98ad92c3b4e0af13e","ecc9b35bf13bd5459350da564646d05c5664a7476fe5acdf1305440f88ed784c","f4470c3fca4dbef1b2488d016fae25978effc586a1f83cb29ac8cb6ab5bc2d50","141319b1a84827e1046e93741bf8a9a15a916d49684ab04925ac4ce4573eea23","d54b606094287758dcf19064a8d91c727346aadaa9388732e73c4315b7c606f9","49030e42ce4152e715a7ddaa10e592f8e61d00f70ef11f48546711f159d985df","b96761b1e7ebd1e8464a78a98fe52f53ce6035c32b4b2b12307a629a551ff7cf","d4786e2581571c863c7d12231c3afb6d4cef390c0ac9a24b243293721d28ea95","ed28e3d3530544f1cf2b43d1956b7bd13b63c612d963a8fb37387aa1a5e11460","05b127365cf115d4978a7997ee98f9b48f0ddc552b981c18aa2ee1b3e6df42c6","9d11dd6843f298b01b34bd7f7e4b1037489871531d14b58199b7cba1ac0841e6","f79e90fa4091de4fc2ec70f5bf67b24393285c112658e0d810e6bd711387fbb9","99f1fc0f09230ce745b6a256ba7082e6e51a2907abda3d9e735a5c8188bb4ba1","477f86cce983b9c91a36fdcd4a7ce21144a08dee9b1aafb91b9c70e57f717ce6","b03d2e6bb4a7d71c66a66ff9e9c93549cae4b593f634a4ea2a1f79f94200f5b4","9ddc0f53a81e631dcf39d5155f41ec12ed551b731efc3224f410667ba07b37dc","cf087ff9ae7c9954ad8612d071e5cdf34a6024ee1ae477217639e63a802a53dd","b64f62b94babb82cc78d3d1308631ae221552bb595202fc1d267e1c29ce7ba60","a91e24875f8a534497459e5ccb872c4438be3130d8d74b7e1104c5f94cdcf8c2","4f49f3d029eeeb3fed14d59625acd088b6b34f3b41c527afa09d29e4a7725c32","179795fd7ac7e7efcba3c36d539a1e8659fb40d77d0a3fab2c25562d99793086","4ba37d0b40b879eceaaca2802a1635f2e6d86d5c31e3ff2d2fd13e68dd2a6d3d","6b7f5dfba9cd3108f1410b56f6a84188eee23ab48a3621b209a67eea64293394","870c540da9fafde331a3316cee50c17ad76ddb9160b78b317bef2e6f6fc4bac0","470b4cccaea895d8a5820aed088357e380d66b8e7510f0a1ea9b575850160241","8a55f8942af0aec1e0df3ab328b974a7888ffd60ded48cc6862013da0f41afbc","2e51e8409f28baf93e665df2a9d646a1bf9ac8703cbf9a6766cfdefa249d5780","99ef1a23e95910287d39493d8d9d7d1f0b498286f2b1fdbc0b01495f10cf0958","6652200c53a4551efe2a7541072d817562812003f9d9ef0ec17995aa232378f8","39c6c01194df72dda97da2072335c38231ced9b39afa280452afcca901e73643","12097e411d948f77b7b6fa4656c6573481c1b4e2864c1fca9d5b296096707c45","cbe53bf1976aee6cec830a848c6ac132def1503cffde82ccfe5bd15e75cbaa72","eeab5dcfff92dbabb7e285445aba47bd5135a4a3502df59ac546847aeb5a964f","5ea8279a578027abefab9c17cef186cccf000306685e5f2ee78bdf62cae568dd","0607767d89ad9c7686dbb01b37248290b2fa7364b2bf37d86afd51b88756fe66","e4fd5f45c08b52dae40f4cdff45e8681e76b5af5761356c4caed4ca750dc65cd","145b1c82caa2a6d703108444a5cf03e9cb8c3cd3f19299582a564276dbbba734","736b22ec91ae9b4b2b15e8d8c220f6c152d4f2228f6d46c16e6a9b98b4733120","ac776cb8b40f92cdd307b16b83e18eeb1fbaa5b5d6bd992b3fda0b4d6de8524c","65ba30e2202fdf6f37da0f7cfe31dfb5308c9209885aaf4cef4d572fd14e2903","54e8389455ec2252de063e83d3ce72529d674e6d2dc2070661f01d4f76b63475","fbbbfb525dd0255ee332d51f59648265aaa20c2e9eff007765cf4d4a6940a849","8de5e418f34d04f6ea947ce31852092a24a705862e6b810ca9f83c2d5f9cda4d","ea6040989964f012fd3a92a3170891f5f155430b8bbfa4976cde8d11513b62d9","14d94547b5deca767137fbd14dae73e888f3516c742fad18b83be333b38f0b88","47f05203f6368d56158cda2e79167777fc9dcb0c671ef3aabc205a1636c26a29"];


contract("Rewards-Market", async function(users) {
	describe("Scenario1", async () => {
		it("0.0", async () => {
			masterInstance = await OwnedUpgradeabilityProxy.deployed();
			masterInstance = await Master.at(masterInstance.address);
			plotusToken = await PlotusToken.deployed();
			BLOTInstance = await BLOT.deployed();
			timeNow = await latestTime();

			bPlotInstance = await BLOT.at(await masterInstance.getLatestAddress(web3.utils.toHex("BL")));
			allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
			acyclicMarkets = await AcyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AC")));
			referral = await Referral.deployed();
			disputeResolution = await DisputeResolution.at(await masterInstance.getLatestAddress(web3.utils.toHex("DR")));
            await increaseTime(5 * 3600);
            await plotusToken.transfer(users[12],toWei(100000));
            await plotusToken.transfer(users[11],toWei(100000));
            // await plotusToken.transfer(marketIncentives.address,toWei(500));
            
			let nullAddress = "0x0000000000000000000000000000";
         
            await plotusToken.transfer(users[11],toWei(100));
            await plotusToken.approve(allMarkets.address,toWei(200000),{from:users[11]});
			await acyclicMarkets.setNextOptionPrice(18);
			// await acyclicMarkets.claimRelayerRewards();
			timeNow = await latestTime();
			let initialLiquidity = 100*10**8;
            await acyclicMarkets.whitelistMarketCreator(users[11]);
            await acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 100*10**8,{from:users[11],gasPrice:500000});
            
	        await assertRevert(acyclicMarkets.setReferralContract(users[0]));

            // await assertRevert(marketIncentives.setMasterAddress(users[0], users[0]));
            await assertRevert(acyclicMarkets.handleFee(1, 1, users[11], users[11]));
            await assertRevert(acyclicMarkets.setMasterAddress(users[11], users[11]));
            // await marketIncentives.claimCreationReward(100,{from:users[11]});
		});

		it("Scenario 1: Few user wins", async () => {
			let i;
			let totalDepositedPlot = toWei(1000);
			let predictionVal  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			let options=[0,2,2,2,3,1,1,2,3,3,2,1];
			let daoCommissions = [0, 1.8, 6.4, 3.36, 1.968, 8, 11.2, 3.2, 0.8, 4.8, 2.4];
			const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
			await assertRevert(referral.setReferrer(ZERO_ADDRESS, ZERO_ADDRESS));
			for(i=1; i<11;i++){
				if(i>1) {
					//Should not allow unauthorized address to set referrer
					await assertRevert(referral.setReferrer(users[1], users[i], {from:users[i]}));
					await referral.setReferrer(users[1], users[i]);
					//SHould not add referrer if already set
					await assertRevert(referral.setReferrer(users[1], users[i]));
				}
				await plotusToken.transfer(users[i], toWei(2000));
			    await plotusToken.approve(allMarkets.address, toWei(1000000), { from: users[i] });
				await acyclicMarkets.setNextOptionPrice(options[i]*9);
				// let daoBalanceBefore = await plotusToken.balanceOf(marketIncentives.address);
				// await allMarkets.depositAndPlacePrediction(totalDepositedPlot, 7, plotusToken.address, predictionVal[i]*1e8, options[i]);
			    let functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", totalDepositedPlot, 7, plotusToken.address, predictionVal[i]*1e8, options[i]);
				await signAndExecuteMetaTx(
			      privateKeyList[i],
			      users[i],
			      functionSignature,
			      allMarkets,
              	   "AM"
			      );
				
				if(i == 10) {
					await acyclicMarkets.removeReferralContract();
					await assertRevert(acyclicMarkets.removeReferralContract());
				}
			}

			let functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", totalDepositedPlot, 7, plotusToken.address, 1e7, 1);
			await assertRevert(signAndExecuteMetaTx(
			  privateKeyList[10],
			  users[10],
			  functionSignature,
			  allMarkets,
				 "AM"
			  ));

			//SHould not add referrer if already placed prediction
			await assertRevert(referral.setReferrer(users[1], users[2]));
			let relayerBalBefore = await plotusToken.balanceOf(users[0]);
			await acyclicMarkets.claimRelayerRewards();
			let relayerBalAfter = await plotusToken.balanceOf(users[0]);

			assert.equal(Math.round((relayerBalAfter-relayerBalBefore)/1e15),11.532*1e3);


			let betpoints = [0,5444.44444, 21777.77777, 11433.33333, 4464.44444, 54444.44444, 76222.22222, 10888.88888, 1814.81481, 10888.88888, 8166.66666, 1814.81481, 1814.81481, 1814.81481];


			for(i=1;i<=11;i++)
			{
				let betPointUser = (await allMarkets.getUserPredictionPoints(users[i],7,options[i]))/1e5;
				if(i == 11) {
					let betPointUser1 = (await allMarkets.getUserPredictionPoints(users[i],7,2))/1e5;
					assert.equal(betPointUser1,betpoints[i+1]);
					let betPointUser2 = (await allMarkets.getUserPredictionPoints(users[i],7,3))/1e5;
					assert.equal(betPointUser2,betpoints[i+1]);
				}
				assert.equal(betPointUser,betpoints[i]);
				let unusedBal = await allMarkets.getUserUnusedBalance(users[i]);
				if(i != 11)
				assert.equal(totalDepositedPlot/1e18-unusedBal[0]/1e18,predictionVal[i]);
			}

			let daoBalanceBefore = await plotusToken.balanceOf(masterInstance.address);
			await acyclicMarkets.settleMarket(7,0);
			await increaseTime(8*60*60);

			await acyclicMarkets.settleMarket(7,1);
			let daoFee = 5.666;
			let daoBalanceAfter = await plotusToken.balanceOf(masterInstance.address);
			assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + daoFee).toFixed(2));
			
			let marketCreatorReward = await acyclicMarkets.getPendingMarketCreationRewards(users[11]);
			assert.equal(226640000,Math.round(marketCreatorReward/1e11));

			// let creationReward = 14.3999;
			let marketCreatoFee = 22.664;
            let balanceBefore = await plotusToken.balanceOf(users[11]);
            await acyclicMarkets.claimCreationReward({ from: users[11] });
            let balanceAfter = await plotusToken.balanceOf(users[11]);
            assert.equal(~~(balanceAfter/1e15), ~~((balanceBefore/1e14  + marketCreatoFee*1e4)/10));

			// assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + marketCreatoFee+daoFee).toFixed(2));
			await plotusToken.transfer(users[12], "700000000000000000000");
			await plotusToken.approve(disputeResolution.address, "500000000000000000000", {
				from: users[12],
			});
			await disputeResolution.raiseDispute(7, "500000000000000000000", "", {from: users[12]});
			await increaseTime(604810);
			await disputeResolution.declareResult(7);
			
			await increaseTime(60*61);

			let userRewardPlot = [0,0,0,0,0,1118.14308219,1565.400315,0,0,0,0];
			for(i=1;i<11;i++)
			{
				let reward = await allMarkets.getReturn(users[i],7);
				// assert.equal(Math.round(reward/1e2),userRewardPlot[i]*1e6);
				let plotBalBefore = await plotusToken.balanceOf(users[i]);
				let plotEthUnused = await allMarkets.getUserUnusedBalance(users[i]);
				functionSignature = encode3("withdraw(uint,uint)", plotEthUnused[0].iadd(plotEthUnused[1]), 100);
				await signAndExecuteMetaTx(
			      privateKeyList[i],
			      users[i],
			      functionSignature,
			      allMarkets,
              		"AM"
			      );
				let plotBalAfter = await plotusToken.balanceOf(users[i]);
				assert.equal(Math.round((plotBalAfter-plotBalBefore)/1e18),Math.round((totalDepositedPlot/1e18-predictionVal[i])/1+reward/1e8));
			}

			// let plotBalBeforeCreator = await plotusToken.balanceOf(users[11]);
			// functionSignature = encode3("claimCreationReward()");
            // await signAndExecuteMetaTx(
            //     privateKeyList[11],
            //     users[11],
            //     functionSignature,
            //     cyclicMarkets,
            //     "CM"
            //     );

			// let plotBalAfterCreator = await plotusToken.balanceOf(users[11]);

			// assert.equal(Math.round((plotBalAfterCreator-plotBalBeforeCreator)/1e11),226640000);

				
		});

		it("Check referral fee", async () => {
			let referralRewardPlot = [10.532, 0.8, 0.42, 0.246, 1, 1.4, 0.4, 0.1, 0.6, 0.3];
			await bPlotInstance.addMinter(referral.address);
			await referral.approveToBPLOT(toWei(100000000));

			for(i=1;i<11;i++)
			{
				let reward = await referral.getReferralFees(users[i], plotusToken.address);
				if(i == 1) {
					reward = reward[0];
				} else {
					reward = reward[1];
				}
				assert.equal(reward/1,referralRewardPlot[i-1]*1e8);
				let plotBalBefore = await bPlotInstance.balanceOf(users[i]);
				functionSignature = encode3("claimReferralFee(address,address)", users[i], plotusToken.address);
                if(reward > 0)
				await signAndExecuteMetaTx(
			      privateKeyList[i],
			      users[i],
			      functionSignature,
			      referral,
              		"RF"
			      );
				let plotBalAfter = await bPlotInstance.balanceOf(users[i]);
				assert.equal(Math.round((plotBalAfter/1e13-plotBalBefore/1e13)),reward/1e3);
			}
		})

		it("Should be able to pause market creation", async() => {
			await acyclicMarkets.toggleMarketCreation(true);
			await assertRevert(acyclicMarkets.toggleMarketCreation(true));
			assert.equal(await acyclicMarkets.paused(), true);
			timeNow = await latestTime();
            await assertRevert(acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 100*10**8,{from:users[11]}));
		});

		it("Should be able to resume market creation", async() => {
			await acyclicMarkets.toggleMarketCreation(false);
			await assertRevert(acyclicMarkets.toggleMarketCreation(false));
			assert.equal(await acyclicMarkets.paused(), false);
			timeNow = await latestTime();
            await acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 100*10**8,{from:users[11]});
		});

		it("Should be able to add a temporary market creator", async() => {
            await plotusToken.transfer(users[13],toWei(10000));
			await plotusToken.approve(allMarkets.address, toWei(1000000), {from:users[13]});
            await assertRevert(acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 100*10**8,{from:users[13]}));
			await acyclicMarkets.addTemporaryMarketCreator(users[13]);
            await acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 100*10**8,{from:users[13]});
		});
		it("Access for temporary market creator should be revoked after a market is created", async() => {
            await assertRevert(acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 100*10**8,{from:users[13]}));
		});
	});
});

contract("Rewards-Market Stake less than 1 ether", async function(users) {
	describe("Scenario1", async () => {
		it("0.0", async () => {
			masterInstance = await OwnedUpgradeabilityProxy.deployed();
			masterInstance = await Master.at(masterInstance.address);
			plotusToken = await PlotusToken.deployed();
			BLOTInstance = await BLOT.deployed();
			timeNow = await latestTime();
			
			acyclicMarkets = await AcyclicMarkets.at(await masterInstance.getLatestAddress(toHex("AC")));
			allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
			await increaseTime(5 * 3600);
            await plotusToken.transfer(users[12],toWei(100000));
            await plotusToken.transfer(users[11],toWei(100000));
            await plotusToken.transfer(masterInstance.address,toWei(500));
            
			let nullAddress = "0x0000000000000000000000000000";
         
            await plotusToken.transfer(users[11],toWei(100));
            await plotusToken.approve(allMarkets.address,toWei(200000),{from:users[11]});
			await acyclicMarkets.setNextOptionPrice(18);
			// await acyclicMarkets.claimRelayerRewards();
			timeNow = await latestTime();
            await acyclicMarkets.whitelistMarketCreator(users[11]);
            await acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 100*10**8,{from:users[11],gasPrice:500000});
            // await marketIncentives.claimCreationReward(100,{from:users[11]});
		});

		it("Scenario 1: Few user wins", async () => {
			let i;
			let totalDepositedPlot = toWei(100);
			let predictionVal  = [100];
			let options=[1, 2, 3];

			let relayerBalBefore = await plotusToken.balanceOf(users[0]);
			await assertRevert(acyclicMarkets.claimRelayerRewards());
			let relayerBalAfter = await plotusToken.balanceOf(users[0]);

			assert.equal(((relayerBalAfter-relayerBalBefore)/1e18),0);

			relayerBalBefore = await plotusToken.balanceOf(users[11]);
			await acyclicMarkets.claimRelayerRewards({from:users[11]});
			relayerBalAfter = await plotusToken.balanceOf(users[11]);

			assert.equal(~~((relayerBalAfter-relayerBalBefore)/1e10),100000002);


			let betpoints = [1814.81481, 1814.81481, 1814.81481];


			for(i=0;i<3;i++)
			{
				let betPointUser = (await allMarkets.getUserPredictionPoints(users[11],7,options[i]))/1e5;
				assert.equal(betPointUser,betpoints[i]);
			}
			let unusedBal = await allMarkets.getUserUnusedBalance(users[11]);
			assert.equal(totalDepositedPlot/1e18-unusedBal[0]/1e18,100);

			await increaseTime(8*60*60);

			await acyclicMarkets.settleMarket(7, 1);
			await plotusToken.transfer(users[12], "700000000000000000000");
			await plotusToken.approve(allMarkets.address, "500000000000000000000", {
				from: users[12],
			});

			await increaseTime(4*60*61);

			let reward = await allMarkets.getReturn(users[11],7);
			// assert.equal(Math.round(reward/1e2),userRewardPlot[i]*1e6);
			let plotBalBefore = await plotusToken.balanceOf(users[11]);
			let plotEthUnused = await allMarkets.getUserUnusedBalance(users[11]);
			// await allMarkets.withdraw(plotEthUnused[0].iadd(plotEthUnused[1]), 100, {from: users[11]});
			functionSignature = encode3("withdraw(uint,uint)", plotEthUnused[0].iadd(plotEthUnused[1]), 100);
			await signAndExecuteMetaTx(
		      privateKeyList[11],
		      users[11],
		      functionSignature,
		      allMarkets,
              "AM"
		      );
			let plotBalAfter = await plotusToken.balanceOf(users[11]);
			assert.equal(Math.round((plotBalAfter-plotBalBefore)/1e18),Math.round(reward/1e8));
			let marketCreatorReward = await acyclicMarkets.getPendingMarketCreationRewards(users[11]);
			assert.equal(8000000,Math.round(marketCreatorReward/1e11));

			let plotBalBeforeCreator = await plotusToken.balanceOf(users[11]);

			functionSignature = encode3("claimCreationReward()");
            await signAndExecuteMetaTx(
                privateKeyList[11],
                users[11],
                functionSignature,
                acyclicMarkets,
              	"AC"
                );

			let plotBalAfterCreator = await plotusToken.balanceOf(users[11]);

			assert.equal(Math.round((plotBalAfterCreator-plotBalBeforeCreator)/1e11),8000000);

				
		});

	});
});

contract("Rewards-Market Raise dispute and pass the proposal ", async function(users) {
	describe("Scenario1", async () => {
		it("0.0", async () => {
			masterInstance = await OwnedUpgradeabilityProxy.deployed();
			masterInstance = await Master.at(masterInstance.address);
			plotusToken = await PlotusToken.deployed();
			BLOTInstance = await BLOT.deployed();
			timeNow = await latestTime();

			bPlotInstance = await BLOT.at(await masterInstance.getLatestAddress(web3.utils.toHex("BL")));
			acyclicMarkets = await AcyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AC")));
			allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
			disputeResolution = await DisputeResolution.at(await masterInstance.getLatestAddress(web3.utils.toHex("DR")));
            await increaseTime(5 * 3600);
            await plotusToken.transfer(users[12],toWei(100000));
            await plotusToken.transfer(users[11],toWei(100000));
            await plotusToken.transfer(masterInstance.address,toWei(500));
            
			let nullAddress = "0x0000000000000000000000000000";
         
            await plotusToken.transfer(users[11],toWei(100));
            await plotusToken.approve(allMarkets.address,toWei(200000),{from:users[11]});
			await acyclicMarkets.setNextOptionPrice(18);
			// await acyclicMarkets.claimRelayerRewards();
			timeNow = await latestTime();
            await acyclicMarkets.whitelistMarketCreator(users[11]);
            await acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 100*10**8,{from:users[11],gasPrice:500000});
            await assertRevert(acyclicMarkets.claimCreationReward({from:users[11]}));
		});

		it("Scenario 1: Few user wins", async () => {
			let i;
			let totalDepositedPlot = toWei(1000);
			let predictionVal  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			let options=[0,2,2,2,3,1,1,2,3,3,2,1];
			let daoCommissions = [0, 1.8, 6.4, 3.36, 1.968, 8, 11.2, 3.2, 0.8, 4.8, 2.4];
			for(i=1; i<11;i++){
				if(i>1) {
					await referral.setReferrer(users[1], users[i]);
					//SHould not add referrer if already set
					await assertRevert(referral.setReferrer(users[1], users[i]));
				}
				await plotusToken.transfer(users[i], toWei(2000));
			    await plotusToken.approve(allMarkets.address, toWei(1000000), { from: users[i] });
			    let functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", totalDepositedPlot, 7, plotusToken.address, predictionVal[i]*1e8, options[i]);
				await acyclicMarkets.setNextOptionPrice(options[i]*9);
				// let daoBalanceBefore = await plotusToken.balanceOf(masterInstance.address);
				// await allMarkets.depositAndPlacePrediction(totalDepositedPlot, 7, plotusToken.address, predictionVal[i]*1e8, options[i]);
				await signAndExecuteMetaTx(
			      privateKeyList[i],
			      users[i],
			      functionSignature,
			      allMarkets,
              		"AM"
			      );
				// let daoBalanceAfter = await plotusToken.balanceOf(marketIncentives.address);
				// assert.equal(daoBalanceAfter - daoBalanceBefore, daoCommissions[i]*1e18);
			}

			//SHould not add referrer if already placed prediction
			await assertRevert(referral.setReferrer(users[1], users[2]));
			let relayerBalBefore = await plotusToken.balanceOf(users[0]);
			await acyclicMarkets.claimRelayerRewards();
			let relayerBalAfter = await plotusToken.balanceOf(users[0]);

			assert.equal(Math.round((relayerBalAfter-relayerBalBefore)/1e15),11.532*1e3);


			let betpoints = [0,5444.44444, 21777.77777, 11433.33333, 4464.44444, 54444.44444, 76222.22222, 10888.88888, 1814.81481, 10888.88888, 8166.66666, 1814.81481, 1814.81481, 1814.81481];


			for(i=1;i<=11;i++)
			{
				let betPointUser = (await allMarkets.getUserPredictionPoints(users[i],7,options[i]))/1e5;
				if(i == 11) {
					let betPointUser1 = (await allMarkets.getUserPredictionPoints(users[i],7,2))/1e5;
					assert.equal(betPointUser1,betpoints[i+1]);
					let betPointUser2 = (await allMarkets.getUserPredictionPoints(users[i],7,3))/1e5;
					assert.equal(betPointUser2,betpoints[i+1]);
				}
				assert.equal(betPointUser,betpoints[i]);
				let unusedBal = await allMarkets.getUserUnusedBalance(users[i]);
				if(i != 11)
				assert.equal(totalDepositedPlot/1e18-unusedBal[0]/1e18,predictionVal[i]);
			}

			await increaseTime(8*60*60);

			await acyclicMarkets.settleMarket(7, 1);
			await plotusToken.transfer(users[12], "700000000000000000000");
			await plotusToken.approve(disputeResolution.address, "500000000000000000000", {
				from: users[12],
			});

			await disputeResolution.raiseDispute(7, "5000000000000000000000000", "", {from: users[12]});
			
			await plotusToken.transfer(users[13], "20000000000000000000000");
			await plotusToken.transfer(users[14], "20000000000000000000000");
			await plotusToken.transfer(users[15], "20000000000000000000000");
			
			await plotusToken.approve(disputeResolution.address, "20000000000000000000000", {
				from: users[13],
			});
			await plotusToken.approve(disputeResolution.address, "20000000000000000000000", {
				from: users[14],
			});
			await plotusToken.approve(disputeResolution.address, "20000000000000000000000", {
				from: users[15],
			});
			await disputeResolution.submitVote(7, "20000000000000000000000", 1, {from:users[13]});
		    await disputeResolution.submitVote(7, "20000000000000000000000", 1, {from:users[14]});
		    await disputeResolution.submitVote(7, "20000000000000000000000", 1, {from:users[15]});
		    await increaseTime(604810);
			await disputeResolution.declareResult(7);
			// await increaseTime(604800);
			// await governance.closeProposal(proposalId/1);

			await increaseTime(60*61);
		    assert.equal((await allMarkets.getMarketResults(7))[0]/1, 3);

			let userRewardPlot = [0, 0, 0, 0, 166.6424219, 0, 0, 0, 67.74082192, 406.4449315, 0];
			for(i=1;i<11;i++)
			{
				let reward = await allMarkets.getReturn(users[i],7);
				// assert.equal(Math.round(reward/1e2),userRewardPlot[i]*1e6);
				let plotBalBefore = await plotusToken.balanceOf(users[i]);
				let plotEthUnused = await allMarkets.getUserUnusedBalance(users[i]);
				functionSignature = encode3("withdraw(uint,uint)", plotEthUnused[0].iadd(plotEthUnused[1]), 100);
				await signAndExecuteMetaTx(
			      privateKeyList[i],
			      users[i],
			      functionSignature,
			      allMarkets,
              		"AM"
			      );
				let plotBalAfter = await plotusToken.balanceOf(users[i]);
				assert.equal(Math.round((plotBalAfter-plotBalBefore)/1e18),Math.round((totalDepositedPlot/1e18-predictionVal[i])/1+reward/1e8));
			}

			let marketCreatorReward = await acyclicMarkets.getPendingMarketCreationRewards(users[11]);
			assert.equal(226640000,Math.round(marketCreatorReward/1e11));

			let plotBalBeforeCreator = await plotusToken.balanceOf(users[11]);

			functionSignature = encode3("claimCreationReward()");
            await signAndExecuteMetaTx(
                privateKeyList[11],
                users[11],
                functionSignature,
                acyclicMarkets,
                "AC"
                );

			let plotBalAfterCreator = await plotusToken.balanceOf(users[11]);

			assert.equal(Math.round((plotBalAfterCreator-plotBalBeforeCreator)/1e11),226640000);

				
		});

		it("Check referral fee", async () => {
			let referralRewardPlot = [10.532, 0.8, 0.42, 0.246, 1, 1.4, 0.4, 0.1, 0.6, 0.3];
			await bPlotInstance.addMinter(referral.address);
			await referral.approveToBPLOT(toWei(100000000));

			for(i=1;i<11;i++)
			{
				let reward = await referral.getReferralFees(users[i], plotusToken.address);
				if(i == 1) {
					reward = reward[0];
				} else {
					reward = reward[1];
				}
				assert.equal(reward/1,referralRewardPlot[i-1]*1e8);
				let plotBalBefore = await bPlotInstance.balanceOf(users[i]);
				functionSignature = encode3("claimReferralFee(address,address)", users[i], plotusToken.address);
                if(reward > 0)
				await signAndExecuteMetaTx(
			      privateKeyList[i],
			      users[i],
			      functionSignature,
			      referral,
              		"RF"
			      );
				let plotBalAfter = await bPlotInstance.balanceOf(users[i]);
				assert.equal(Math.round((plotBalAfter/1e13-plotBalBefore/1e13)),reward/1e3);
			}
		})

		it("Should not be able to create market with less liquidity than fixed", async() => {
			await assertRevert(acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 100,{from:users[11]}));
		});

		it("Should not be able to create market with invalid time params", async() => {
			timeNow = await latestTime();
			await assertRevert(acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,0],toHex("NFT"),toHex("PLOT"), 1000*1e8,{from:users[11]}));
			await assertRevert(acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+3*3600,3600],toHex("NFT"),toHex("PLOT"), 1000*1e8,{from:users[11]}));
		});

		it("Should not be able to create market with invalid option range", async() => {
			timeNow = await latestTime();
			await assertRevert(acyclicMarkets.createMarket("Question1", [0,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 1000*1e8,{from:users[11]}));
			await assertRevert(acyclicMarkets.createMarket("Question1", [100,50], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 1000*1e8,{from:users[11]}));
		});

		it("Authorised user should be able to update minLiquidityByCreator", async() => {
			assert.equal((await acyclicMarkets.getUintParameters(toHex("MLC")))[1],100*1e8);
			await acyclicMarkets.updateUintParameters(toHex("MLC"),200*1e8);
			assert.equal((await acyclicMarkets.getUintParameters(toHex("MLC")))[1],200*1e8);
		});

		it("Should not be able to Whiltelist null address", async() => {
			let nullAddress = "0x0000000000000000000000000000000000000000";
			assert.equal(await acyclicMarkets.whiteListedMarketCreators(nullAddress),false);
			await assertRevert(acyclicMarkets.whitelistMarketCreator(nullAddress));
			assert.equal(await acyclicMarkets.whiteListedMarketCreators(nullAddress),false);
		});

		it("Authorised user should be able to deWhitelist creator and they should not be able to create market anymore", async() => {
			assert.equal(await acyclicMarkets.whiteListedMarketCreators(users[11]),true);
			await acyclicMarkets.deWhitelistMarketCreator(users[11]);
			assert.equal(await acyclicMarkets.whiteListedMarketCreators(users[11]),false);
			await assertRevert(acyclicMarkets.createMarket("Question1", [100,400], [timeNow/1+4*3600,timeNow/1+8*3600,3600],toHex("NFT"),toHex("PLOT"), 1000*1e8,{from:users[11]}));
			
		});

		it("Should not be able to deWhiltelist null address", async() => {
			let nullAddress = "0x0000000000000000000000000000000000000000";
			assert.equal(await acyclicMarkets.whiteListedMarketCreators(nullAddress),false);
			await assertRevert(acyclicMarkets.deWhitelistMarketCreator(nullAddress));
			assert.equal(await acyclicMarkets.whiteListedMarketCreators(nullAddress),false);
		});

		it("Authorised user should be able to update minTimePassed", async() => {
			assert.equal((await acyclicMarkets.getUintParameters(toHex("MTP")))[1],10*3600);
			await acyclicMarkets.updateUintParameters(toHex("MTP"),24*3600);
			assert.equal((await acyclicMarkets.getUintParameters(toHex("MTP")))[1],24*3600);
		});

		it("Should revert if value overflows while updating config params", async() => {
			assert.equal((await acyclicMarkets.getUintParameters(toHex("MTP")))[1],24*3600);
			await assertRevert(acyclicMarkets.updateUintParameters(toHex("MTP"),"4294967296"));
			assert.equal((await acyclicMarkets.getUintParameters(toHex("MTP")))[1],24*3600);

			assert.equal((await acyclicMarkets.getUintParameters(toHex("MLC")))[1],200*1e8);
			await assertRevert(acyclicMarkets.updateUintParameters(toHex("MLC"),"18446744073709551616"));
			assert.equal((await acyclicMarkets.getUintParameters(toHex("MLC")))[1],200*1e8);
		});
		it("Should revert if tried to pass null address as market creator", async() => {
			let nullAddress = "0x0000000000000000000000000000000000000000";
			await assertRevert(allMarkets.createMarket([],[],nullAddress,1000*1e8));
		});

	});
});
