const { assert, use } = require("chai");

const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const AllMarkets = artifacts.require("AllPlotMarkets_2");
const AllMarkets_V3 = artifacts.require("AllPlotMarkets_3");
const CyclicMarkets = artifacts.require("MockCyclicMarkets");
const CyclicMarkets_V2 = artifacts.require("MockCyclicMarkets_2");
const MockUniswapRouter = artifacts.require('MockUniswapRouter');
const Referral = artifacts.require("Referral");
const DisputeResolution = artifacts.require('DisputeResolution');
const SwapAndPredictWithPlot = artifacts.require('SwapAndPredictWithPlot');
const SampleERC = artifacts.require('SampleERC');
const MockchainLink = artifacts.require('MockChainLinkAggregator');
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
			timeNow = await latestTime();
            router = await MockUniswapRouter.deployed();
			allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
			cyclicMarkets = await CyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
			referral = await Referral.deployed();
			disputeResolution = await DisputeResolution.at(await masterInstance.getLatestAddress(web3.utils.toHex("DR")));
			spInstance = await SwapAndPredictWithPlot.at(await masterInstance.getLatestAddress(web3.utils.toHex("SP")));
			mockChainlink = await MockchainLink.deployed();

			nullAddress = await masterInstance.getLatestAddress("0x0000");
			await assertRevert(allMarkets.addAuthorizedProxyPreditictor(nullAddress));
            await assertRevert(spInstance.initiate(
                nullAddress,
                await router.WETH()
            ));
            await assertRevert(spInstance.initiate(
                router.address,
                nullAddress
            ));
            await assertRevert(spInstance.initiate(
                router.address,
                await router.WETH()
            ));
			await assertRevert(spInstance.initiate(users[0], users[1], {from:users[1]}));
            externalToken = await SampleERC.new("USDP", "USDP");
            _weth = await SampleERC.at(await spInstance.nativeCurrencyAddress());
			await router.setWETH(_weth.address);
            await _weth.mint(users[0], toWei(1000000));
            await externalToken.mint(users[0], toWei(1000000));
            plotTokenPrice = 0.01;
            externalTokenPrice = 1/plotTokenPrice; 
            await plotusToken.transfer(router.address,toWei(10000));
            await increaseTime(5 * 3600);
            await plotusToken.transfer(users[12],toWei(100000));
            await plotusToken.transfer(users[11],toWei(100000));
            // await plotusToken.transfer(marketIncentives.address,toWei(500));
            
         
            await plotusToken.transfer(users[11],toWei(100));
            await plotusToken.approve(allMarkets.address,toWei(200000),{from:users[11]});
			await cyclicMarkets.setNextOptionPrice(18);
			await cyclicMarkets.claimRelayerRewards();
            await cyclicMarkets.whitelistMarketCreator(users[11]);
            await cyclicMarkets.createMarket(0, 0, 0,{from:users[11],gasPrice:500000});
            // await assertRevert(marketIncentives.setMasterAddress(users[0], users[0]));
            await assertRevert(allMarkets.setMasterAddress(users[0], users[0]));
            await assertRevert(spInstance.setMasterAddress(users[0], users[0]));
            await assertRevert(allMarkets.setMarketStatus(6, 1));
	        await assertRevert(cyclicMarkets.setReferralContract(users[0]));
			var date = Date.now();
			date = Math.round(date/1000);
    		await assertRevert(cyclicMarkets.addInitialMarketTypesAndStart(date, users[0], users[0], {from:users[10]}));
    		await assertRevert(cyclicMarkets.handleFee(100, 1, users[0], users[0], {from:users[10]}));
			// await marketIncentives.claimCreationReward(100,{from:users[11]});
		});

		it("Scenario 1: Rewards with existing contract", async () => {
			let i;
			totalDepositedPlot  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			predictionVal  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			let options=[0,2,2,2,3,1,1,2,3,3,2,1];
			let daoCommissions = [0, 1.8, 6.4, 3.36, 1.968, 8, 11.2, 3.2, 0.8, 4.8, 2.4];
			const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
			await assertRevert(referral.setReferrer(ZERO_ADDRESS, ZERO_ADDRESS));
			await spInstance.whitelistTokenForSwap(await router.WETH());
			await assertRevert(spInstance.whitelistTokenForSwap(nullAddress));
			await assertRevert(spInstance.whitelistTokenForSwap(await router.WETH()));
			for(i=1; i<11;i++){
				await spInstance.whitelistTokenForSwap(externalToken.address);
				if(i>1) {
					//Should not allow unauthorized address to set referrer
					await assertRevert(referral.setReferrer(users[1], users[i], {from:users[i]}));
					await referral.setReferrer(users[1], users[i]);
					//SHould not add referrer if already set
					await assertRevert(referral.setReferrer(users[1], users[i]));
				}
				if(i == 10) {
					await cyclicMarkets.removeReferralContract();
					await assertRevert(cyclicMarkets.removeReferralContract());
				}
                let _inputAmount = toWei(predictionVal[i]*plotTokenPrice);
                await externalToken.approve(spInstance.address, _inputAmount, {from:users[i]});
                await externalToken.transfer(users[i], _inputAmount);
				await cyclicMarkets.setNextOptionPrice(options[i]*9);
                let spPlotBalanceBefore = await plotusToken.balanceOf(spInstance.address); 
                let spTokenBalanceBefore = await externalToken.balanceOf(spInstance.address); 
                // await spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], 0)
				if(i == 2) {
					//Predict with eth
					await assertRevert(allMarkets.depositAndPredictFor(users[0], _inputAmount, 7, plotusToken.address, 1, _inputAmount, 0));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, 1, {from:users[i], value:_inputAmount*2}));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, toWei(1000), {from:users[i], value:_inputAmount}));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, nullAddress, 7, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
					await spInstance.deWhitelistTokenForSwap(await router.WETH());
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
					await spInstance.whitelistTokenForSwap(await router.WETH());
					await spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount});
			} else {
					if(i == 3) {
						//Predict with WETH
						await _weth.approve(spInstance.address, _inputAmount, {from:users[i]});
						await _weth.transfer(users[i], _inputAmount);
						// await spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, {from:users[i], value:_inputAmount});
						functionSignature = encode3("swapAndPlacePrediction(address[],uint256,address,uint256,uint256,uint64,uint256)", [await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i]);
					} else {
						await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, externalToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i], {from:users[i]}));
						await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
						functionSignature = encode3("swapAndPlacePrediction(address[],uint256,address,uint256,uint256,uint64,uint256)", [externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i]);
					}  
					await signAndExecuteMetaTx(
						privateKeyList[i],
						users[i],
						functionSignature,
						spInstance,
							"SP"
					);
				}
                let spPlotBalanceAfter = await plotusToken.balanceOf(spInstance.address); 
                let spTokenBalanceAfter = await externalToken.balanceOf(spInstance.address); 
                await assert.equal(spPlotBalanceAfter/1, spPlotBalanceBefore/1);
                await assert.equal(spTokenBalanceAfter/1, spTokenBalanceBefore/1);
				await spInstance.deWhitelistTokenForSwap(externalToken.address);
			}
			await assertRevert(spInstance.deWhitelistTokenForSwap(externalToken.address));

			//SHould not add referrer if already placed prediction
			await assertRevert(referral.setReferrer(users[1], users[2]));
			let relayerBalBefore = await plotusToken.balanceOf(users[0]);
			await cyclicMarkets.claimRelayerRewards();
			let relayerBalAfter = await plotusToken.balanceOf(users[0]);

			// assert.equal(Math.round((relayerBalAfter-relayerBalBefore)/1e15),11.532*1e3);


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
				assert.equal(totalDepositedPlot[i]-unusedBal[0]/1e18,predictionVal[i]);
			}

			await cyclicMarkets.settleMarket(7,0);
			await mockChainlink.setLatestAnswer(100);
			await increaseTime(8*60*60);
			await cyclicMarkets.settleMarket(1,1);

			let daoBalanceBefore = await plotusToken.balanceOf(masterInstance.address);
			await cyclicMarkets.settleMarket(7,1);
			await mockChainlink.setLatestAnswer(100);
			let daoFee = 5.666;
			let daoBalanceAfter = await plotusToken.balanceOf(masterInstance.address);
			assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + daoFee).toFixed(2));
			
			
			let marketCreatorReward = await cyclicMarkets.getPendingMarketCreationRewards(users[11]);
			assert.equal(226640000,Math.round(marketCreatorReward/1e11));

			// let creationReward = 14.3999;
			let marketCreatoFee = 22.664;
            let balanceBefore = await plotusToken.balanceOf(users[11]);
            await cyclicMarkets.claimCreationReward({ from: users[11] });
            let balanceAfter = await plotusToken.balanceOf(users[11]);
            assert.equal(~~(balanceAfter/1e15), ~~((balanceBefore/1e14  + marketCreatoFee*1e4)/10));

			// assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + marketCreatoFee+daoFee).toFixed(2));
			await plotusToken.transfer(users[12], "700000000000000000000");
			await plotusToken.approve(disputeResolution.address, "500000000000000000000", {
				from: users[12],
			});
			await disputeResolution.raiseDispute(7, toWei(1000000), "", {from: users[12]});
			await increaseTime(604810);
			await disputeResolution.declareResult(7);
			
			await increaseTime(60*61);
            await allMarkets.emitMarketSettledEvent(7);
		});

        it("Should update the AllMarkets to implement reward pool share for market creator", async () => {
            let allMarketsV3Impl = await AllMarkets_V3.new();
            let cyclicMarketsV2Impl = await CyclicMarkets_V2.new();
			await masterInstance.upgradeMultipleImplementations([toHex("AM"), toHex("CM")], [allMarketsV3Impl.address, cyclicMarketsV2Impl.address]);
			allMarkets = await AllMarkets_V3.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
			cyclicMarkets = await CyclicMarkets_V2.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
			
        });

        it("Should be able to get expected rewards after the upgrade", async () => {
            let userRewardPlot = [0,0,0,0,0,1134.24931507,1587.949041,0,0,0,0];
			for(i=1;i<11;i++)
			{	
				let reward = await allMarkets.getReturn(users[i],7);
				try {
			
					assert.equal(Math.trunc(reward/1e4),Math.trunc(userRewardPlot[i]*1e4));
					let plotBalBefore = await plotusToken.balanceOf(users[i]);
					let plotEthUnused = await allMarkets.getUserUnusedBalance(users[i]);
					if((plotEthUnused[0]/1 +plotEthUnused[1]/1) > 0) {
						functionSignature = encode3("withdraw(uint,uint)", plotEthUnused[0].iadd(plotEthUnused[1]), 100);
						await signAndExecuteMetaTx(
						privateKeyList[i],
						users[i],
						functionSignature,
						allMarkets,
							"AM"
						);
					}
					let plotBalAfter = await plotusToken.balanceOf(users[i]);
					assert.equal(Math.round((plotBalAfter-plotBalBefore)/1e18),Math.round((totalDepositedPlot[i]-predictionVal[i])/1+reward/1e8));
				} catch (e) {
					console.log(`Error At index ${i}, Expected: ${Math.trunc(userRewardPlot[i]*1e4)}, Actual: ${Math.trunc(reward/1e4)}`)
				}
			}
				
        });

        it("Check referral fee", async () => {
			let referralRewardPlot = [9.932, 0.8, 0.42, 0.246, 1, 1.4, 0.4, 0.1, 0.6, 0];

			for(i=1;i<11;i++)
			{
				let reward = await referral.getReferralFees(users[i], plotusToken.address);
				if(i == 1) {
					reward = reward[0];
				} else {
					reward = reward[1];
				}
				assert.equal(reward/1,referralRewardPlot[i-1]*1e8);
				let plotBalBefore = await plotusToken.balanceOf(users[i]);
				functionSignature = encode3("claimReferralFee(address,address)", users[i], plotusToken.address);
				await signAndExecuteMetaTx(
			      privateKeyList[i],
			      users[i],
			      functionSignature,
			      referral,
              		"RF"
			      );
				let plotBalAfter = await plotusToken.balanceOf(users[i]);
				assert.equal(Math.round((plotBalAfter/1e13-plotBalBefore/1e13)),reward/1e3);
			}
		})

        it("Should set reward pool share to 5%", async () => {
            await cyclicMarkets.updateUintParameters(toHex("RPS"), 5);
        });

        it("Scenario 2: Check Rewards with New contract", async () => {
            await plotusToken.transfer(users[11],toWei(1000));
            await increaseTime(86400)
			await mockChainlink.setLatestAnswer(934999802346);
			await cyclicMarkets.setNextOptionPrice(18);
            await cyclicMarkets.createMarket(0, 0, 1,{from:users[11]});
            let i;
			totalDepositedPlot  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			predictionVal  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			let options=[0,2,2,2,3,1,1,2,3,3,2,1];
			let daoCommissions = [0, 1.8, 6.4, 3.36, 1.968, 8, 11.2, 3.2, 0.8, 4.8, 2.4];
			const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
			await assertRevert(referral.setReferrer(ZERO_ADDRESS, ZERO_ADDRESS));
            await cyclicMarkets.setReferralContract(referral.address);
			for(i=1; i<11;i++){
				await spInstance.whitelistTokenForSwap(externalToken.address);
				if(i == 10) {
					await cyclicMarkets.removeReferralContract();
				}
                let _inputAmount = toWei(predictionVal[i]*plotTokenPrice);
                await externalToken.approve(spInstance.address, _inputAmount, {from:users[i]});
                await externalToken.transfer(users[i], _inputAmount);
				await cyclicMarkets.setNextOptionPrice(options[i]*9);
                let spPlotBalanceBefore = await plotusToken.balanceOf(spInstance.address); 
                let spTokenBalanceBefore = await externalToken.balanceOf(spInstance.address); 
                // await spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], 0)
				if(i == 2) {
					//Predict with eth
					await assertRevert(allMarkets.depositAndPredictFor(users[0], _inputAmount, 8, plotusToken.address, 1, _inputAmount, 0));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, 1, {from:users[i], value:_inputAmount*2}));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, toWei(1000), {from:users[i], value:_inputAmount}));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, nullAddress, 8, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
					await spInstance.deWhitelistTokenForSwap(await router.WETH());
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
					await spInstance.whitelistTokenForSwap(await router.WETH());
					await spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount});
			} else {
					if(i == 3) {
						//Predict with WETH
						await _weth.approve(spInstance.address, _inputAmount, {from:users[i]});
						await _weth.transfer(users[i], _inputAmount);
						// await spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, {from:users[i], value:_inputAmount});
						functionSignature = encode3("swapAndPlacePrediction(address[],uint256,address,uint256,uint256,uint64,uint256)", [await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i]);
					} else {
						await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, externalToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i], {from:users[i]}));
						await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
						functionSignature = encode3("swapAndPlacePrediction(address[],uint256,address,uint256,uint256,uint64,uint256)", [externalToken.address, plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i]);
					}  
					await signAndExecuteMetaTx(
						privateKeyList[i],
						users[i],
						functionSignature,
						spInstance,
							"SP"
					);
				}
                let spPlotBalanceAfter = await plotusToken.balanceOf(spInstance.address); 
                let spTokenBalanceAfter = await externalToken.balanceOf(spInstance.address); 
                await assert.equal(spPlotBalanceAfter/1, spPlotBalanceBefore/1);
                await assert.equal(spTokenBalanceAfter/1, spTokenBalanceBefore/1);
				await spInstance.deWhitelistTokenForSwap(externalToken.address);
			}
			await assertRevert(spInstance.deWhitelistTokenForSwap(externalToken.address));

			let relayerBalBefore = await plotusToken.balanceOf(users[0]);
			await cyclicMarkets.claimRelayerRewards();
			let relayerBalAfter = await plotusToken.balanceOf(users[0]);

			// assert.equal(Math.round((relayerBalAfter-relayerBalBefore)/1e15),11.532*1e3);


			let betpoints = [0,5444.44444, 21777.77777, 11433.33333, 4464.44444, 54444.44444, 76222.22222, 10888.88888, 1814.81481, 10888.88888, 8166.66666, 1814.81481, 1814.81481, 1814.81481];


			for(i=1;i<=11;i++)
			{
				let betPointUser = (await allMarkets.getUserPredictionPoints(users[i],8,options[i]))/1e5;
				if(i == 11) {
					let betPointUser1 = (await allMarkets.getUserPredictionPoints(users[i],8,2))/1e5;
					assert.equal(betPointUser1,betpoints[i+1]);
					let betPointUser2 = (await allMarkets.getUserPredictionPoints(users[i],8,3))/1e5;
					assert.equal(betPointUser2,betpoints[i+1]);
				}
				assert.equal(betPointUser,betpoints[i]);
				let unusedBal = await allMarkets.getUserUnusedBalance(users[i]);
				if(i != 11)
				assert.equal(totalDepositedPlot[i]-unusedBal[0]/1e18,predictionVal[i]);
			}

			await cyclicMarkets.settleMarket(8,3);
			await mockChainlink.setLatestAnswer(100);
			await increaseTime(8*60*60);

			let daoBalanceBefore = await plotusToken.balanceOf(masterInstance.address);
			await cyclicMarkets.settleMarket(8,4);
			let daoFee = 5.666;
			let daoBalanceAfter = await plotusToken.balanceOf(masterInstance.address);
			assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + daoFee).toFixed(2));
			
			
			let marketCreatorReward = await cyclicMarkets.getPendingMarketCreationRewards(users[11]);
			assert.equal(226640000,Math.round(marketCreatorReward/1e11));

			// let creationReward = 14.3999;
			let marketCreatoFee = 22.664;
            let balanceBefore = await plotusToken.balanceOf(users[11]);
            await cyclicMarkets.claimCreationReward({ from: users[11] });
            let balanceAfter = await plotusToken.balanceOf(users[11]);
            assert.equal(~~(balanceAfter/1e15), ~~((balanceBefore/1e14  + marketCreatoFee*1e4)/10));

			// assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + marketCreatoFee+daoFee).toFixed(2));
			await plotusToken.transfer(users[12], "700000000000000000000");
			await plotusToken.approve(disputeResolution.address, "500000000000000000000", {
				from: users[12],
			});
			await disputeResolution.raiseDispute(8, toWei(1000000), "", {from: users[12]});
			await increaseTime(604810);
			await disputeResolution.declareResult(8);
			
			await increaseTime(60*61);
		});

		it("Should not be able to get reward if MarketSettled Event is emitted", async () => {
			let plotEthUnused = await allMarkets.getUserUnusedBalance(users[5]);
			await assertRevert(allMarkets.withdraw(plotEthUnused[0].iadd(plotEthUnused[1]), 100));
		});

		it("Should transfer MC reward pool share to market creator contract on emitting event", async() => {
			let plotBalBefore = await plotusToken.balanceOf(allMarkets.address);
			let plotBalCMBefore = await plotusToken.balanceOf(cyclicMarkets.address);
            await allMarkets.emitMarketSettledEvent(8);
			let rewardPoolShare = await cyclicMarkets.rewardPoolShareForMarketCreator(users[11]);
			let plotBalAfter = await plotusToken.balanceOf(allMarkets.address);
			let plotBalCMAfter = await plotusToken.balanceOf(cyclicMarkets.address);
			await assert.equal((plotBalAfter.iadd(rewardPoolShare))/1, plotBalBefore/1);
			await assert.equal((plotBalCMBefore.iadd(rewardPoolShare))/1, plotBalCMAfter/1);
		})

        it("Should be able to get expected rewards after dedcuting reward pool share", async () => {
            let userRewardPlot = [0,0,0,0,0,1102.03684932,1542.851589,0,0,0,0];
            let i;
			for(i=1;i<11;i++)
			{	
				let reward = await allMarkets.getReturn(users[i],8);
				try {
			
					assert.equal(Math.trunc(reward/1e4),Math.trunc(userRewardPlot[i]*1e4));
					let plotBalBefore = await plotusToken.balanceOf(users[i]);
					let plotEthUnused = await allMarkets.getUserUnusedBalance(users[i]);
					if((plotEthUnused[0]/1 +plotEthUnused[1]/1) > 0) {
						functionSignature = encode3("withdraw(uint,uint)", plotEthUnused[0].iadd(plotEthUnused[1]), 100);
						await signAndExecuteMetaTx(
						privateKeyList[i],
						users[i],
						functionSignature,
						allMarkets,
							"AM"
						);
					}
					let plotBalAfter = await plotusToken.balanceOf(users[i]);
					assert.equal(Math.round((plotBalAfter-plotBalBefore)/1e18),Math.round((totalDepositedPlot[i]-predictionVal[i])/1+reward/1e8));
				} catch (e) {
                    console.log(e);
					console.log(`Error At index ${i}, Expected: ${Math.trunc(userRewardPlot[i]*1e4)}, Actual: ${Math.trunc(reward/1e4)}`)
				}
			}
				
        });

		it("Market creator should get expected reward share", async () => {
			let plotBalBefore = await plotusToken.balanceOf(users[11]);
			let rewardPoolShare = await cyclicMarkets.rewardPoolShareForMarketCreator(users[11]);
			assert.equal(Math.trunc(rewardPoolShare/1e10), 7838366666)
			await cyclicMarkets.claimCreationReward({from:users[11]});
			let plotBalAfter = await plotusToken.balanceOf(users[11]);
			await assert.equal((plotBalBefore.iadd(rewardPoolShare))/1, plotBalAfter/1);
		});

	});
});

contract("Market", async function(users) {

	describe("Scenario 2: Check proper reward distribution after resolving dispute", async () => {
		it("0.0", async () => {
			masterInstance = await OwnedUpgradeabilityProxy.deployed();
			masterInstance = await Master.at(masterInstance.address);
			plotusToken = await PlotusToken.deployed();
			timeNow = await latestTime();
            router = await MockUniswapRouter.deployed();
			allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
			cyclicMarkets = await CyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
			referral = await Referral.deployed();
			disputeResolution = await DisputeResolution.at(await masterInstance.getLatestAddress(web3.utils.toHex("DR")));
			spInstance = await SwapAndPredictWithPlot.at(await masterInstance.getLatestAddress(web3.utils.toHex("SP")));
			mockChainlink = await MockchainLink.deployed();

			nullAddress = await masterInstance.getLatestAddress("0x0000");
			await assertRevert(allMarkets.addAuthorizedProxyPreditictor(nullAddress));
            await assertRevert(spInstance.initiate(
                nullAddress,
                await router.WETH()
            ));
            await assertRevert(spInstance.initiate(
                router.address,
                nullAddress
            ));
            await assertRevert(spInstance.initiate(
                router.address,
                await router.WETH()
            ));
			await assertRevert(spInstance.initiate(users[0], users[1], {from:users[1]}));
            externalToken = await SampleERC.new("USDP", "USDP");
            _weth = await SampleERC.at(await spInstance.nativeCurrencyAddress());
			await router.setWETH(_weth.address);
            await _weth.mint(users[0], toWei(1000000));
            await externalToken.mint(users[0], toWei(1000000));
            plotTokenPrice = 0.01;
            externalTokenPrice = 1/plotTokenPrice; 
            await plotusToken.transfer(router.address,toWei(10000));
            await increaseTime(5 * 3600);
            await plotusToken.transfer(users[12],toWei(100000));
            await plotusToken.transfer(users[11],toWei(100000));
            // await plotusToken.transfer(marketIncentives.address,toWei(500));
            
         
            await plotusToken.transfer(users[11],toWei(100));
            await plotusToken.approve(allMarkets.address,toWei(200000),{from:users[11]});
			await cyclicMarkets.setNextOptionPrice(18);
			await cyclicMarkets.claimRelayerRewards();
            await cyclicMarkets.whitelistMarketCreator(users[11]);
            await cyclicMarkets.createMarket(0, 0, 0,{from:users[11],gasPrice:500000});
            // await assertRevert(marketIncentives.setMasterAddress(users[0], users[0]));
            await assertRevert(allMarkets.setMasterAddress(users[0], users[0]));
            await assertRevert(spInstance.setMasterAddress(users[0], users[0]));
            await assertRevert(allMarkets.setMarketStatus(6, 1));
	        await assertRevert(cyclicMarkets.setReferralContract(users[0]));
			var date = Date.now();
			date = Math.round(date/1000);
    		await assertRevert(cyclicMarkets.addInitialMarketTypesAndStart(date, users[0], users[0], {from:users[10]}));
    		await assertRevert(cyclicMarkets.handleFee(100, 1, users[0], users[0], {from:users[10]}));
			// await marketIncentives.claimCreationReward(100,{from:users[11]});
		});

		it("Scenario 1: Rewards with existing contract", async () => {
			let i;
			totalDepositedPlot  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			predictionVal  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			let options=[0,2,2,2,3,1,1,2,3,3,2,1];
			let daoCommissions = [0, 1.8, 6.4, 3.36, 1.968, 8, 11.2, 3.2, 0.8, 4.8, 2.4];
			const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
			await assertRevert(referral.setReferrer(ZERO_ADDRESS, ZERO_ADDRESS));
			await spInstance.whitelistTokenForSwap(await router.WETH());
			await assertRevert(spInstance.whitelistTokenForSwap(nullAddress));
			await assertRevert(spInstance.whitelistTokenForSwap(await router.WETH()));
			for(i=1; i<11;i++){
				await spInstance.whitelistTokenForSwap(externalToken.address);
				if(i>1) {
					//Should not allow unauthorized address to set referrer
					await assertRevert(referral.setReferrer(users[1], users[i], {from:users[i]}));
					await referral.setReferrer(users[1], users[i]);
					//SHould not add referrer if already set
					await assertRevert(referral.setReferrer(users[1], users[i]));
				}
				if(i == 10) {
					await cyclicMarkets.removeReferralContract();
					await assertRevert(cyclicMarkets.removeReferralContract());
				}
                let _inputAmount = toWei(predictionVal[i]*plotTokenPrice);
                await externalToken.approve(spInstance.address, _inputAmount, {from:users[i]});
                await externalToken.transfer(users[i], _inputAmount);
				await cyclicMarkets.setNextOptionPrice(options[i]*9);
                let spPlotBalanceBefore = await plotusToken.balanceOf(spInstance.address); 
                let spTokenBalanceBefore = await externalToken.balanceOf(spInstance.address); 
                // await spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], 0)
				if(i == 2) {
					//Predict with eth
					await assertRevert(allMarkets.depositAndPredictFor(users[0], _inputAmount, 7, plotusToken.address, 1, _inputAmount, 0));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, 1, {from:users[i], value:_inputAmount*2}));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, toWei(1000), {from:users[i], value:_inputAmount}));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, nullAddress, 7, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
					await spInstance.deWhitelistTokenForSwap(await router.WETH());
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
					await spInstance.whitelistTokenForSwap(await router.WETH());
					await spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount});
			} else {
					if(i == 3) {
						//Predict with WETH
						await _weth.approve(spInstance.address, _inputAmount, {from:users[i]});
						await _weth.transfer(users[i], _inputAmount);
						// await spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, {from:users[i], value:_inputAmount});
						functionSignature = encode3("swapAndPlacePrediction(address[],uint256,address,uint256,uint256,uint64,uint256)", [await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i]);
					} else {
						await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, externalToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i], {from:users[i]}));
						await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
						functionSignature = encode3("swapAndPlacePrediction(address[],uint256,address,uint256,uint256,uint64,uint256)", [externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], 0, predictionVal[i]);
					}  
					await signAndExecuteMetaTx(
						privateKeyList[i],
						users[i],
						functionSignature,
						spInstance,
							"SP"
					);
				}
                let spPlotBalanceAfter = await plotusToken.balanceOf(spInstance.address); 
                let spTokenBalanceAfter = await externalToken.balanceOf(spInstance.address); 
                await assert.equal(spPlotBalanceAfter/1, spPlotBalanceBefore/1);
                await assert.equal(spTokenBalanceAfter/1, spTokenBalanceBefore/1);
				await spInstance.deWhitelistTokenForSwap(externalToken.address);
			}
			await assertRevert(spInstance.deWhitelistTokenForSwap(externalToken.address));

			//SHould not add referrer if already placed prediction
			await assertRevert(referral.setReferrer(users[1], users[2]));
			let relayerBalBefore = await plotusToken.balanceOf(users[0]);
			await cyclicMarkets.claimRelayerRewards();
			let relayerBalAfter = await plotusToken.balanceOf(users[0]);

			// assert.equal(Math.round((relayerBalAfter-relayerBalBefore)/1e15),11.532*1e3);


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
				assert.equal(totalDepositedPlot[i]-unusedBal[0]/1e18,predictionVal[i]);
			}

			await cyclicMarkets.settleMarket(7,0);
			await mockChainlink.setLatestAnswer(100);
			await increaseTime(8*60*60);
			await cyclicMarkets.settleMarket(1,1);

			let daoBalanceBefore = await plotusToken.balanceOf(masterInstance.address);
			await cyclicMarkets.settleMarket(7,1);
			await mockChainlink.setLatestAnswer(100);
			let daoFee = 5.666;
			let daoBalanceAfter = await plotusToken.balanceOf(masterInstance.address);
			assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + daoFee).toFixed(2));
			
			
			let marketCreatorReward = await cyclicMarkets.getPendingMarketCreationRewards(users[11]);
			assert.equal(226640000,Math.round(marketCreatorReward/1e11));

			// let creationReward = 14.3999;
			let marketCreatoFee = 22.664;
            let balanceBefore = await plotusToken.balanceOf(users[11]);
            await cyclicMarkets.claimCreationReward({ from: users[11] });
            let balanceAfter = await plotusToken.balanceOf(users[11]);
            assert.equal(~~(balanceAfter/1e15), ~~((balanceBefore/1e14  + marketCreatoFee*1e4)/10));

			// assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + marketCreatoFee+daoFee).toFixed(2));
			await plotusToken.transfer(users[12], "700000000000000000000");
			await plotusToken.approve(disputeResolution.address, "500000000000000000000", {
				from: users[12],
			});
		});

		it("Emit the market settled event", async () => {
			await increaseTime(60*61);
            await allMarkets.emitMarketSettledEvent(7);
		})

        it("Should update the AllMarkets to implement reward pool share for market creator", async () => {
            let allMarketsV3Impl = await AllMarkets_V3.new();
            let cyclicMarketsV2Impl = await CyclicMarkets_V2.new();
			await masterInstance.upgradeMultipleImplementations([toHex("AM"), toHex("CM")], [allMarketsV3Impl.address, cyclicMarketsV2Impl.address]);
			allMarkets = await AllMarkets_V3.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
			cyclicMarkets = await CyclicMarkets_V2.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
			
        });

        it("Should be able to get expected rewards after the upgrade", async () => {
            let userRewardPlot = [0,0,0,0,0,1134.24931507,1587.949041,0,0,0,0];
			for(i=1;i<11;i++)
			{	
				let reward = await allMarkets.getReturn(users[i],7);
				try {
			
					assert.equal(Math.trunc(reward/1e4),Math.trunc(userRewardPlot[i]*1e4));
					let plotBalBefore = await plotusToken.balanceOf(users[i]);
					let plotEthUnused = await allMarkets.getUserUnusedBalance(users[i]);
					if((plotEthUnused[0]/1 +plotEthUnused[1]/1) > 0) {
						functionSignature = encode3("withdraw(uint,uint)", plotEthUnused[0].iadd(plotEthUnused[1]), 100);
						await signAndExecuteMetaTx(
						privateKeyList[i],
						users[i],
						functionSignature,
						allMarkets,
							"AM"
						);
					}
					let plotBalAfter = await plotusToken.balanceOf(users[i]);
					assert.equal(Math.round((plotBalAfter-plotBalBefore)/1e18),Math.round((totalDepositedPlot[i]-predictionVal[i])/1+reward/1e8));
				} catch (e) {
					console.log(`Error At index ${i}, Expected: ${Math.trunc(userRewardPlot[i]*1e4)}, Actual: ${Math.trunc(reward/1e4)}`)
				}
			}
				
        });

        it("Check referral fee", async () => {
			let referralRewardPlot = [9.932, 0.8, 0.42, 0.246, 1, 1.4, 0.4, 0.1, 0.6, 0];

			for(i=1;i<11;i++)
			{
				let reward = await referral.getReferralFees(users[i], plotusToken.address);
				if(i == 1) {
					reward = reward[0];
				} else {
					reward = reward[1];
				}
				assert.equal(reward/1,referralRewardPlot[i-1]*1e8);
				let plotBalBefore = await plotusToken.balanceOf(users[i]);
				functionSignature = encode3("claimReferralFee(address,address)", users[i], plotusToken.address);
				await signAndExecuteMetaTx(
			      privateKeyList[i],
			      users[i],
			      functionSignature,
			      referral,
              		"RF"
			      );
				let plotBalAfter = await plotusToken.balanceOf(users[i]);
				assert.equal(Math.round((plotBalAfter/1e13-plotBalBefore/1e13)),reward/1e3);
			}
		})

        it("Scenario 2: Check Rewards with New contract", async () => {
            await plotusToken.transfer(users[11],toWei(1000));
            await increaseTime(86400)
			await mockChainlink.setLatestAnswer(934999802346);
			await cyclicMarkets.setNextOptionPrice(18);
            await cyclicMarkets.createMarket(0, 0, 1,{from:users[11]});
            let i;
			totalDepositedPlot  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			predictionVal  = [0,100, 400, 210, 123, 500, 700, 200, 50, 300, 150];
			let options=[0,2,2,2,3,1,1,2,3,3,2,1];
			let daoCommissions = [0, 1.8, 6.4, 3.36, 1.968, 8, 11.2, 3.2, 0.8, 4.8, 2.4];
			const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
			await assertRevert(referral.setReferrer(ZERO_ADDRESS, ZERO_ADDRESS));
            await cyclicMarkets.setReferralContract(referral.address);
			for(i=1; i<11;i++){
				await spInstance.whitelistTokenForSwap(externalToken.address);
				if(i == 10) {
					await cyclicMarkets.removeReferralContract();
				}
                let _inputAmount = toWei(predictionVal[i]*plotTokenPrice);
                await externalToken.approve(spInstance.address, _inputAmount, {from:users[i]});
                await externalToken.transfer(users[i], _inputAmount);
				await cyclicMarkets.setNextOptionPrice(options[i]*9);
                let spPlotBalanceBefore = await plotusToken.balanceOf(spInstance.address); 
                let spTokenBalanceBefore = await externalToken.balanceOf(spInstance.address); 
                // await spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], 0)
				if(i == 2) {
					//Predict with eth
					await assertRevert(allMarkets.depositAndPredictFor(users[0], _inputAmount, 8, plotusToken.address, 1, _inputAmount, 0));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, 1, {from:users[i], value:_inputAmount*2}));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, toWei(1000), {from:users[i], value:_inputAmount}));
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, nullAddress, 8, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
					await spInstance.deWhitelistTokenForSwap(await router.WETH());
					await assertRevert(spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
					await spInstance.whitelistTokenForSwap(await router.WETH());
					await spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount});
			} else {
					if(i == 3) {
						//Predict with WETH
						await _weth.approve(spInstance.address, _inputAmount, {from:users[i]});
						await _weth.transfer(users[i], _inputAmount);
						// await spInstance.swapAndPlacePrediction([await router.WETH(), plotusToken.address], _inputAmount, users[i], 7, options[i], 0, {from:users[i], value:_inputAmount});
						functionSignature = encode3("swapAndPlacePrediction(address[],uint256,address,uint256,uint256,uint64,uint256)", [await router.WETH(), plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i]);
					} else {
						await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, externalToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i], {from:users[i]}));
						await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i], {from:users[i], value:_inputAmount}));
						functionSignature = encode3("swapAndPlacePrediction(address[],uint256,address,uint256,uint256,uint64,uint256)", [externalToken.address, plotusToken.address], _inputAmount, users[i], 8, options[i], 0, predictionVal[i]);
					}  
					await signAndExecuteMetaTx(
						privateKeyList[i],
						users[i],
						functionSignature,
						spInstance,
							"SP"
					);
				}
                let spPlotBalanceAfter = await plotusToken.balanceOf(spInstance.address); 
                let spTokenBalanceAfter = await externalToken.balanceOf(spInstance.address); 
                await assert.equal(spPlotBalanceAfter/1, spPlotBalanceBefore/1);
                await assert.equal(spTokenBalanceAfter/1, spTokenBalanceBefore/1);
				await spInstance.deWhitelistTokenForSwap(externalToken.address);
			}
			await assertRevert(spInstance.deWhitelistTokenForSwap(externalToken.address));

			let relayerBalBefore = await plotusToken.balanceOf(users[0]);
			await cyclicMarkets.claimRelayerRewards();
			let relayerBalAfter = await plotusToken.balanceOf(users[0]);

			// assert.equal(Math.round((relayerBalAfter-relayerBalBefore)/1e15),11.532*1e3);


			let betpoints = [0,5444.44444, 21777.77777, 11433.33333, 4464.44444, 54444.44444, 76222.22222, 10888.88888, 1814.81481, 10888.88888, 8166.66666, 1814.81481, 1814.81481, 1814.81481];


			for(i=1;i<=11;i++)
			{
				let betPointUser = (await allMarkets.getUserPredictionPoints(users[i],8,options[i]))/1e5;
				if(i == 11) {
					let betPointUser1 = (await allMarkets.getUserPredictionPoints(users[i],8,2))/1e5;
					assert.equal(betPointUser1,betpoints[i+1]);
					let betPointUser2 = (await allMarkets.getUserPredictionPoints(users[i],8,3))/1e5;
					assert.equal(betPointUser2,betpoints[i+1]);
				}
				assert.equal(betPointUser,betpoints[i]);
				let unusedBal = await allMarkets.getUserUnusedBalance(users[i]);
				if(i != 11)
				assert.equal(totalDepositedPlot[i]-unusedBal[0]/1e18,predictionVal[i]);
			}

			await cyclicMarkets.settleMarket(8,3);
			await mockChainlink.setLatestAnswer(100);
			await increaseTime(8*60*60);

			let daoBalanceBefore = await plotusToken.balanceOf(masterInstance.address);
			await cyclicMarkets.settleMarket(8,4);
			let daoFee = 5.666;
			let daoBalanceAfter = await plotusToken.balanceOf(masterInstance.address);
			assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + daoFee).toFixed(2));
			
			
			let marketCreatorReward = await cyclicMarkets.getPendingMarketCreationRewards(users[11]);
			assert.equal(226640000,Math.round(marketCreatorReward/1e11));

			// let creationReward = 14.3999;
			let marketCreatoFee = 22.664;
            let balanceBefore = await plotusToken.balanceOf(users[11]);
            await cyclicMarkets.claimCreationReward({ from: users[11] });
            let balanceAfter = await plotusToken.balanceOf(users[11]);
            assert.equal(~~(balanceAfter/1e15), ~~((balanceBefore/1e14  + marketCreatoFee*1e4)/10));

			// assert.equal((daoBalanceAfter/1e18).toFixed(2), (daoBalanceBefore/1e18 + marketCreatoFee+daoFee).toFixed(2));
			await plotusToken.transfer(users[12], "700000000000000000000");
			await plotusToken.approve(disputeResolution.address, "500000000000000000000", {
				from: users[12],
			});
		});

		it("Should raise a dispute to change winning option to 3", async () => {
			await plotusToken.transfer(masterInstance.address, toWei(500));
			await disputeResolution.raiseDispute(8, toWei(100), "", {from: users[12]});
			
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
			await disputeResolution.submitVote(8, "20000000000000000000000", 1, {from:users[13]});
		    await disputeResolution.submitVote(8, "20000000000000000000000", 1, {from:users[14]});
		    await disputeResolution.submitVote(8, "20000000000000000000000", 1, {from:users[15]});
		});

        it("Should set reward pool share to 5%", async () => {
            await cyclicMarkets.updateUintParameters(toHex("RPS"), 5);
        });

		it("Should not be able to emit MarketSettled event", async () => {
            await assertRevert(allMarkets.emitMarketSettledEvent(8));
		})
		
		it("Should declare result of dispute", async () => {
			await increaseTime(604810);
			await disputeResolution.declareResult(8);
		})

		it("Should not be able to get reward if MarketSettled Event is emitted", async () => {
			let plotEthUnused = await allMarkets.getUserUnusedBalance(users[5]);
			await assertRevert(allMarkets.withdraw(plotEthUnused[0].iadd(plotEthUnused[1]), 100));
		});

		it("Should transfer MC reward pool share to market creator contract on emitting event", async() => {
			let plotBalBefore = await plotusToken.balanceOf(allMarkets.address);
			let plotBalCMBefore = await plotusToken.balanceOf(cyclicMarkets.address);
            await allMarkets.emitMarketSettledEvent(8);
            await assertRevert(allMarkets.emitMarketSettledEvent(8));
			let rewardPoolShare = await cyclicMarkets.rewardPoolShareForMarketCreator(users[11]);
			let plotBalAfter = await plotusToken.balanceOf(allMarkets.address);
			let plotBalCMAfter = await plotusToken.balanceOf(cyclicMarkets.address);
			await assert.equal((plotBalAfter.iadd(rewardPoolShare))/1, plotBalBefore/1);
			await assert.equal((plotBalCMBefore.iadd(rewardPoolShare))/1, plotBalCMAfter/1);
		})

        it("Should be able to get expected rewards after dedcuting reward pool share", async () => {
            let userRewardPlot = [0,0,0,0,629.9732314,0,0,0,256.0866794,1536.520076,0];
            let i;
			for(i=1;i<11;i++)
			{	
				let reward = await allMarkets.getReturn(users[i],8);
				try {
			
					assert.equal(Math.trunc(reward/1e4),Math.trunc(userRewardPlot[i]*1e4));
					let plotBalBefore = await plotusToken.balanceOf(users[i]);
					let plotEthUnused = await allMarkets.getUserUnusedBalance(users[i]);
					if((plotEthUnused[0]/1 +plotEthUnused[1]/1) > 0) {
						functionSignature = encode3("withdraw(uint,uint)", plotEthUnused[0].iadd(plotEthUnused[1]), 100);
						await signAndExecuteMetaTx(
						privateKeyList[i],
						users[i],
						functionSignature,
						allMarkets,
							"AM"
						);
					}
					let plotBalAfter = await plotusToken.balanceOf(users[i]);
					assert.equal(Math.round((plotBalAfter-plotBalBefore)/1e18),Math.round((totalDepositedPlot[i]-predictionVal[i])/1+reward/1e8));
				} catch (e) {
                    console.log(e);
					console.log(`Error At index ${i}, Expected: ${Math.trunc(userRewardPlot[i]*1e4)}, Actual: ${Math.trunc(reward/1e4)}`)
				}
			}
				
        });

		it("Market creator should get expected reward share", async () => {
			let plotBalBefore = await plotusToken.balanceOf(users[11]);
			let rewardPoolShare = await cyclicMarkets.rewardPoolShareForMarketCreator(users[11]);
			assert.equal(Math.trunc(rewardPoolShare/1e10), 11400666666)
			await cyclicMarkets.claimCreationReward({from:users[11]});
			await assertRevert(cyclicMarkets.claimCreationReward({from:users[11]}));
			let plotBalAfter = await plotusToken.balanceOf(users[11]);
			await assert.equal((plotBalBefore.iadd(rewardPoolShare))/1, plotBalAfter/1);
		});

	});
})

contract("Markets", async function(users) {
    var mapMarketPair = {};
    var marketCount;
    before(async function() {
        masterInstance = await OwnedUpgradeabilityProxy.deployed();
        masterInstance = await Master.at(masterInstance.address);
        plotusToken = await PlotusToken.deployed();
        timeNow = await latestTime();

        allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
        cyclicMarkets = await CyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
        referral = await Referral.deployed();
        disputeResolution = await DisputeResolution.at(await masterInstance.getLatestAddress(web3.utils.toHex("DR")));
        await increaseTime(5 * 3600);
        await plotusToken.transfer(users[12],toWei(1000000));
        await plotusToken.transfer(users[11],toWei(100000));

        let nullAddress = await masterInstance.getLatestAddress("0x00");
        
        await plotusToken.transfer(users[11],toWei(20000000));
        await plotusToken.approve(allMarkets.address,toWei(20000000),{from:users[11]});
        await cyclicMarkets.setNextOptionPrice(18);
        await cyclicMarkets.claimRelayerRewards();
        await cyclicMarkets.whitelistMarketCreator(users[11]);
        marketCount = (await allMarkets.getTotalMarketsLength())/1;
        await increaseTime(2*604810);
        await cyclicMarkets.settleMarket(1,0);
        await cyclicMarkets.settleMarket(2,0);
        await cyclicMarkets.settleMarket(3,0);
        await cyclicMarkets.settleMarket(4,0);
        await cyclicMarkets.settleMarket(5,0);
        await cyclicMarkets.settleMarket(6,0);
        await increaseTime(86400);
        await allMarkets.emitMarketSettledEvent(1); 
        await allMarkets.emitMarketSettledEvent(2);
        await allMarkets.emitMarketSettledEvent(3);
        await allMarkets.emitMarketSettledEvent(4);
        await allMarkets.emitMarketSettledEvent(5);
        await allMarkets.emitMarketSettledEvent(6);
        await cyclicMarkets.updateMarketType(0, 100, 1, 40*60 , (100 * 10**8))
        await cyclicMarkets.updateMarketType(1, 200, 1, 4*60*60 , (100 * 10**8))
        await cyclicMarkets.updateMarketType(2, 500, 1, 28*60*60 , (100 * 10**8))
    });

    async function createMarket(contractInstance, marketCurrency, marketType, roundId) {
        if(!mapMarketPair[`${marketCurrency}${marketType}`]) {
            mapMarketPair[`${marketCurrency}${marketType}`] = [];    
        }
        mapMarketPair[`${marketCurrency}${marketType}`].push(marketCount);
        let tx = await contractInstance.createMarket(marketCurrency, marketType, roundId,{from:users[11]});
        // console.log(`Gas consumed for market-${marketCount}: ${tx.receipt.gasUsed};`)
        marketCount++;
        if(mapMarketPair[`${marketCurrency}${marketType}`].length >2) {
            let _marketToSettle = mapMarketPair[`${marketCurrency}${marketType}`][mapMarketPair[`${marketCurrency}${marketType}`].length-3];
            try {
                await increaseTime(10)
                await allMarkets.emitMarketSettledEvent(_marketToSettle);
                // await cyclicMarkets.settleMarket(_marketToSettle, 0);
            } catch (error) {
                console.log(`Errorer for Market-${marketCurrency}: ${marketType}> ${_marketToSettle}`)

            }
        }
    }

    it("Create markets for 2 weeks, upgrade contract after a week and should work properly", async () => {
        let z = 7;
        let allMarketsV3Impl = await AllMarkets_V3.new();
        // await masterInstance.upgradeMultipleImplementations([toHex("AM")], [allMarketsV3Impl.address]);
        // allMarkets = await AllMarkets_V3.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
        for(let i = 0;i<2; i++) {
            if(i == 1) {
                await masterInstance.upgradeMultipleImplementations([toHex("AM")], [allMarketsV3Impl.address]);
                allMarkets = await AllMarkets_V3.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
                console.log(`Contract upgraded`);
            }
            await createMarket(cyclicMarkets, 0, 2, 0);
            await createMarket(cyclicMarkets, 1, 2, 0);
            for(j = 0;j<7;j++) {
                await createMarket(cyclicMarkets, 0, 1, 0);
                await createMarket(cyclicMarkets, 1, 1, 0);
                for(k = 0;k<24;k++) {
                    await createMarket(cyclicMarkets, 0, 0, 0);
                    await createMarket(cyclicMarkets, 1, 0, 0);
                    await increaseTime(4*60*60 + 1);
                }
            }
        }
        
        await increaseTime(2*604800);
        let plotBalance = await allMarkets.getUserUnusedBalance(users[0]);
        // console.log(plotBalance[0]/1e18, plotBalance[1]/1e18);
        
        // let allMarketsBalBefore = await plotusToken.balanceOf(allMarkets.address);
        // console.log(`All Markets Before Withdraw${allMarketsBalBefore/1e18}`);

        // let plotBalBefore = await plotusToken.balanceOf(users[11]);
        // console.log(plotBalBefore/1e18);
        let tx;
        try {
            tx = await allMarkets.withdraw(plotBalance[0].iadd(plotBalance[1]), 1000)
            // console.log(`Gas Used : ${tx.receipt.gasUsed}`);
            
        } catch (error) {
            console.log(`Withdraw Errored, ${error}`);
        }
    }).timeout(30000000);
});