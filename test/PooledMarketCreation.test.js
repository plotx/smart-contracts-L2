const { assert } = require("chai");

const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const AllMarkets = artifacts.require("MockAllMarkets");
const CyclicMarkets = artifacts.require("MockCyclicMarkets");
const PooledMarketCreation = artifacts.require("PooledMarketCreation");
const EthChainlinkOracle = artifacts.require('MockChainLinkAggregator');
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
	marketIncentives,
	PMC;

let privateKeyList = ["fb437e3e01939d9d4fef43138249f23dc1d0852e69b0b5d1647c087f869fabbd","7c85a1f1da3120c941b83d71a154199ee763307683f206b98ad92c3b4e0af13e","ecc9b35bf13bd5459350da564646d05c5664a7476fe5acdf1305440f88ed784c","f4470c3fca4dbef1b2488d016fae25978effc586a1f83cb29ac8cb6ab5bc2d50","141319b1a84827e1046e93741bf8a9a15a916d49684ab04925ac4ce4573eea23","d54b606094287758dcf19064a8d91c727346aadaa9388732e73c4315b7c606f9","49030e42ce4152e715a7ddaa10e592f8e61d00f70ef11f48546711f159d985df","b96761b1e7ebd1e8464a78a98fe52f53ce6035c32b4b2b12307a629a551ff7cf","d4786e2581571c863c7d12231c3afb6d4cef390c0ac9a24b243293721d28ea95","ed28e3d3530544f1cf2b43d1956b7bd13b63c612d963a8fb37387aa1a5e11460","05b127365cf115d4978a7997ee98f9b48f0ddc552b981c18aa2ee1b3e6df42c6","9d11dd6843f298b01b34bd7f7e4b1037489871531d14b58199b7cba1ac0841e6","f79e90fa4091de4fc2ec70f5bf67b24393285c112658e0d810e6bd711387fbb9","99f1fc0f09230ce745b6a256ba7082e6e51a2907abda3d9e735a5c8188bb4ba1","477f86cce983b9c91a36fdcd4a7ce21144a08dee9b1aafb91b9c70e57f717ce6","b03d2e6bb4a7d71c66a66ff9e9c93549cae4b593f634a4ea2a1f79f94200f5b4","9ddc0f53a81e631dcf39d5155f41ec12ed551b731efc3224f410667ba07b37dc","cf087ff9ae7c9954ad8612d071e5cdf34a6024ee1ae477217639e63a802a53dd","b64f62b94babb82cc78d3d1308631ae221552bb595202fc1d267e1c29ce7ba60","a91e24875f8a534497459e5ccb872c4438be3130d8d74b7e1104c5f94cdcf8c2","4f49f3d029eeeb3fed14d59625acd088b6b34f3b41c527afa09d29e4a7725c32","179795fd7ac7e7efcba3c36d539a1e8659fb40d77d0a3fab2c25562d99793086","4ba37d0b40b879eceaaca2802a1635f2e6d86d5c31e3ff2d2fd13e68dd2a6d3d","6b7f5dfba9cd3108f1410b56f6a84188eee23ab48a3621b209a67eea64293394","870c540da9fafde331a3316cee50c17ad76ddb9160b78b317bef2e6f6fc4bac0","470b4cccaea895d8a5820aed088357e380d66b8e7510f0a1ea9b575850160241","8a55f8942af0aec1e0df3ab328b974a7888ffd60ded48cc6862013da0f41afbc","2e51e8409f28baf93e665df2a9d646a1bf9ac8703cbf9a6766cfdefa249d5780","99ef1a23e95910287d39493d8d9d7d1f0b498286f2b1fdbc0b01495f10cf0958","6652200c53a4551efe2a7541072d817562812003f9d9ef0ec17995aa232378f8","39c6c01194df72dda97da2072335c38231ced9b39afa280452afcca901e73643","12097e411d948f77b7b6fa4656c6573481c1b4e2864c1fca9d5b296096707c45","cbe53bf1976aee6cec830a848c6ac132def1503cffde82ccfe5bd15e75cbaa72","eeab5dcfff92dbabb7e285445aba47bd5135a4a3502df59ac546847aeb5a964f","5ea8279a578027abefab9c17cef186cccf000306685e5f2ee78bdf62cae568dd","0607767d89ad9c7686dbb01b37248290b2fa7364b2bf37d86afd51b88756fe66","e4fd5f45c08b52dae40f4cdff45e8681e76b5af5761356c4caed4ca750dc65cd","145b1c82caa2a6d703108444a5cf03e9cb8c3cd3f19299582a564276dbbba734","736b22ec91ae9b4b2b15e8d8c220f6c152d4f2228f6d46c16e6a9b98b4733120","ac776cb8b40f92cdd307b16b83e18eeb1fbaa5b5d6bd992b3fda0b4d6de8524c","65ba30e2202fdf6f37da0f7cfe31dfb5308c9209885aaf4cef4d572fd14e2903","54e8389455ec2252de063e83d3ce72529d674e6d2dc2070661f01d4f76b63475","fbbbfb525dd0255ee332d51f59648265aaa20c2e9eff007765cf4d4a6940a849","8de5e418f34d04f6ea947ce31852092a24a705862e6b810ca9f83c2d5f9cda4d","ea6040989964f012fd3a92a3170891f5f155430b8bbfa4976cde8d11513b62d9","14d94547b5deca767137fbd14dae73e888f3516c742fad18b83be333b38f0b88","47f05203f6368d56158cda2e79167777fc9dcb0c671ef3aabc205a1636c26a29"];


contract("Pooled Market Creation", async function(users) {
	describe("Scenario1", async () => {
		it("Initialization", async () => {
			masterInstance = await OwnedUpgradeabilityProxy.deployed();
			masterInstance = await Master.at(masterInstance.address);
			plotusToken = await PlotusToken.deployed();
			timeNow = await latestTime();

			allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
			cyclicMarkets = await CyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
			PMC = await PooledMarketCreation.new();
			await masterInstance.addNewContract(toHex("PC"), PMC.address);
			PMC = await PooledMarketCreation.at(await masterInstance.getLatestAddress(web3.utils.toHex("PC")));
			await cyclicMarkets.whitelistMarketCreator(PMC.address);
			await increaseTime(5 * 3600);
            await plotusToken.transfer(users[1],toWei(600));
            await plotusToken.transfer(users[2],toWei(600));
            await plotusToken.transfer(users[3],toWei(600));
            await plotusToken.transfer(users[11],toWei(1200));
            await plotusToken.approve(PMC.address,toWei(600),{from:users[0]});
            await plotusToken.approve(PMC.address,toWei(1600),{from:users[1]});
            await plotusToken.approve(PMC.address,toWei(600),{from:users[2]});
            await plotusToken.approve(PMC.address,toWei(600),{from:users[3]});
            await plotusToken.approve(allMarkets.address,toWei(1200),{from:users[11]});
            
			let nullAddress = "0x0000000000000000000000000000";
			await cyclicMarkets.updateMarketType(0,100,3600,2400,300*1e8);
         
            await PMC.approveToAllMarkets(toWei(1600));
            
		});

		it("Non-proxy owner should not be able to set master address", async () => {
			await assertRevert(PMC.setMasterAddress(users[0],users[0]));
		});

		it("Users should not be able to stake 0 amount", async () => {
			await assertRevert(PMC.stake(0));
		});

		it("Users should not be able to unstake 0 amount", async () => {
			await assertRevert(PMC.unstake(0));
		});

		it("Staker S1 stakes 300 Plot", async () => {
			let userPlotBalBefore = await plotusToken.balanceOf(users[1]);
			let userLPBalBefore = await PMC.balanceOf(users[1]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("stake(uint)", toWei(300));
			await signAndExecuteMetaTx(
			      privateKeyList[1],
			      users[1],
			      functionSignature,
			      PMC,
              	   "PMC"
			      );	
			let userPlotBalAfter = await plotusToken.balanceOf(users[1]);
			let userLPBalAfter = await PMC.balanceOf(users[1]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(userPlotBalBefore-userPlotBalAfter,toWei(300));
			assert.equal(userLPBalAfter-userLPBalBefore,toWei(300));
			assert.equal(poolPlotBalAfter-poolPlotBalBefore,toWei(300));
			assert.equal(poolPlotBalAfter,toWei(300));
			assert.equal(userLPBalAfter,toWei(300));
			assert.equal(lpTotalSupply,toWei(300));
		});

		it("Users should not be able to unstake within ristricted time", async () => {
			await assertRevert(PMC.unstake(100,{from:users[1]}));
		});

		it("Should not create market if it falls beyond min liquidity", async () => {
			await assertRevert(PMC.createMarket(0,0,1));
		});

		it("Staker S2 stakes 400 Plot", async () => {
			let userPlotBalBefore = await plotusToken.balanceOf(users[2]);
			let userLPBalBefore = await PMC.balanceOf(users[2]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("stake(uint)", toWei(400));
			await signAndExecuteMetaTx(
			      privateKeyList[2],
			      users[2],
			      functionSignature,
			      PMC,
              	   "PMC"
			      );
			let userPlotBalAfter = await plotusToken.balanceOf(users[2]);
			let userLPBalAfter = await PMC.balanceOf(users[2]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(userPlotBalBefore-userPlotBalAfter,toWei(400));
			assert.equal(userLPBalAfter-userLPBalBefore,toWei(400));
			assert.equal(poolPlotBalAfter-poolPlotBalBefore,toWei(400));
			assert.equal(poolPlotBalAfter,toWei(700));
			assert.equal(userLPBalAfter,toWei(400));
			assert.equal(lpTotalSupply,toWei(700));
		});

		it("Create Market with liquidity of 300 Plot", async () => {
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			await PMC.createMarket(0,0,0);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();
			assert.equal(poolPlotBalBefore-poolPlotBalAfter,toWei(300));
			assert.equal(poolPlotBalAfter,toWei(400));
			assert.equal(lpTotalSupply,toWei(700));

			assert.equal(Math.round((await PMC.getPlotWorthOfLP(await PMC.balanceOf(users[1])))/1e13),17142857);
			assert.equal(Math.round((await PMC.getPlotWorthOfLP(await PMC.balanceOf(users[2])))/1e13),22857143);
		});

		it("Staker S1 stakes 50 Plot", async () => {
			let userPlotBalBefore = await plotusToken.balanceOf(users[1]);
			let userLPBalBefore = await PMC.balanceOf(users[1]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("stake(uint)", toWei(50));
			await signAndExecuteMetaTx(
			      privateKeyList[1],
			      users[1],
			      functionSignature,
			      PMC,
              	  "PMC"
			      );	
			let userPlotBalAfter = await plotusToken.balanceOf(users[1]);
			let userLPBalAfter = await PMC.balanceOf(users[1]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(userPlotBalBefore-userPlotBalAfter,toWei(50));
			assert.equal(userLPBalAfter-userLPBalBefore,toWei(87.5));
			assert.equal(poolPlotBalAfter-poolPlotBalBefore,toWei(50));
			assert.equal(poolPlotBalAfter,toWei(450));
			assert.equal(userLPBalAfter,toWei(387.5));
			assert.equal(lpTotalSupply,toWei(787.5));
		});

		it("Market settles", async () => {
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(500), 7, plotusToken.address, 500*1e8, 2);
			await cyclicMarkets.setNextOptionPrice(18);
			await signAndExecuteMetaTx(
			      privateKeyList[11],
			      users[11],
			      functionSignature,
			      allMarkets,
              	   "AM"
			      );
			functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(600), 7, plotusToken.address, 600*1e8, 3);
			await cyclicMarkets.setNextOptionPrice(27);
			await signAndExecuteMetaTx(
			      privateKeyList[11],
			      users[11],
			      functionSignature,
			      allMarkets,
              	   "AM"
			      );

			let ethChainlinkOracle = await EthChainlinkOracle.deployed();
            await ethChainlinkOracle.setLatestAnswer(1);

			await increaseTime(8*60*60);

			await cyclicMarkets.settleMarket(7,1);

			await increaseTime(60*61);
			await PMC.claimCreationAndParticipationReward(10);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(poolPlotBalAfter-poolPlotBalBefore,toWei(1383.2));
			assert.equal(poolPlotBalAfter,toWei(1833.2));
			assert.equal(lpTotalSupply,toWei(787.5));
			assert.equal(Math.round((await PMC.getPlotWorthOfLP(await PMC.balanceOf(users[1])))/1e13),90205079);
			assert.equal(Math.round((await PMC.getPlotWorthOfLP(await PMC.balanceOf(users[2])))/1e13),93114921);
		});

		it("Staker S1 stakes 50 Plot", async () => {
			let userPlotBalBefore = await plotusToken.balanceOf(users[1]);
			let userLPBalBefore = await PMC.balanceOf(users[1]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("stake(uint)", toWei(50));
			await signAndExecuteMetaTx(
			      privateKeyList[1],
			      users[1],
			      functionSignature,
			      PMC,
              	  "PMC"
			      );	
			let userPlotBalAfter = await plotusToken.balanceOf(users[1]);
			let userLPBalAfter = await PMC.balanceOf(users[1]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(userPlotBalBefore-userPlotBalAfter,toWei(50));
			assert.equal(Math.round((userLPBalAfter-userLPBalBefore)/1e13),2147883);
			assert.equal(poolPlotBalAfter-poolPlotBalBefore,toWei(50));
			assert.equal(poolPlotBalAfter,toWei(1883.2));
			assert.equal(Math.round(userLPBalAfter/1e13),40897883);
			assert.equal(Math.round(lpTotalSupply/1e13),80897883);	
		});

		it("Staker S2 unstakes all of their LP ", async () => {
			await increaseTime(24 * 3600);
			let userPlotBalBefore = await plotusToken.balanceOf(users[2]);
			let userLPBalBefore = await PMC.balanceOf(users[2]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("unstake(uint)", toWei(400));
			await signAndExecuteMetaTx(
			      privateKeyList[2],
			      users[2],
			      functionSignature,
			      PMC,
              	  "PMC"
			      );	

			let userPlotBalAfter = await plotusToken.balanceOf(users[2]);
			let userLPBalAfter = await PMC.balanceOf(users[2]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(Math.round((userPlotBalAfter-userPlotBalBefore)/1e13),93114921);
			assert.equal(userLPBalBefore-userLPBalAfter,toWei(400));
			assert.equal(Math.round((poolPlotBalBefore-poolPlotBalAfter)/1e13),93114921);
			assert.equal(Math.round(poolPlotBalAfter/1e13),95205079);
			assert.equal(userLPBalAfter,0);
			assert.equal(Math.round(lpTotalSupply/1e13),40897883);
		});

		it("Staker S1 unstakes some of their LP ", async () => {
			let userPlotBalBefore = await plotusToken.balanceOf(users[1]);
			let userLPBalBefore = await PMC.balanceOf(users[1]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("unstake(uint)", toWei(237.1481562));
			await signAndExecuteMetaTx(
			      privateKeyList[1],
			      users[1],
			      functionSignature,
			      PMC,
              	  "PMC"
			      );
			let userPlotBalAfter = await plotusToken.balanceOf(users[1]);
			let userLPBalAfter = await PMC.balanceOf(users[1]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(Math.round((userPlotBalAfter-userPlotBalBefore)/1e13),55205079);
			assert.equal(Math.round((userLPBalBefore-userLPBalAfter)/1e13),23714816);
			assert.equal(Math.round((poolPlotBalBefore-poolPlotBalAfter)/1e13),55205079);
			assert.equal(Math.round(poolPlotBalAfter/1e18),400);
			assert.equal(Math.round(userLPBalAfter/1e13),17183068);
			assert.equal(Math.round(lpTotalSupply/1e13),17183068);	
		});

		it("Create Market with liquidity of 300 Plot", async () => {
			let ethChainlinkOracle = await EthChainlinkOracle.deployed();
            await ethChainlinkOracle.setLatestAnswer(10000000000);
            let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			await PMC.createMarket(0,0,1);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();
			assert.equal(poolPlotBalBefore-poolPlotBalAfter,toWei(300));
			assert.equal(Math.round(poolPlotBalAfter/1e18),100);
			assert.equal(Math.round(lpTotalSupply/1e13),17183068);
			assert.equal(Math.round((await PMC.getPlotWorthOfLP(await PMC.balanceOf(users[1])))/1e18),100);
			assert.equal(await PMC.getPlotWorthOfLP(await PMC.balanceOf(users[2])),0);
		});

		it("Staker S3 stakes 400 Plot", async () => {
			let userPlotBalBefore = await plotusToken.balanceOf(users[3]);
			let userLPBalBefore = await PMC.balanceOf(users[3]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("stake(uint)", toWei(400));
			await signAndExecuteMetaTx(
			      privateKeyList[3],
			      users[3],
			      functionSignature,
			      PMC,
              	  "PMC"
			      );	
			let userPlotBalAfter = await plotusToken.balanceOf(users[3]);
			let userLPBalAfter = await PMC.balanceOf(users[3]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(userPlotBalBefore-userPlotBalAfter,toWei(400));
			assert.equal(Math.round((userLPBalAfter-userLPBalBefore)/1e13),68732271);
			assert.equal(Math.round((poolPlotBalAfter-poolPlotBalBefore)/1e18),400);
			assert.equal(Math.round(poolPlotBalAfter/1e18),500);
			assert.equal(Math.round(userLPBalAfter/1e13),68732271);
			assert.equal(Math.round(lpTotalSupply/1e13),85915339);	
		});
		it("Update Additional reward for market type", async () => {
			assert.equal(await PMC.marketTypeAdditionalReward(0,0),0);
			await PMC.updateAdditionalRewardPerMarketType(0,0,toWei(503.6));
			assert.equal(await PMC.marketTypeAdditionalReward(0,0),toWei(503.6));
		});
		it("Create, settle market and Add additional reward of 503.6 plots", async () => {
			let ethChainlinkOracle = await EthChainlinkOracle.deployed();
            await ethChainlinkOracle.setLatestAnswer(10000000000);
            await increaseTime(10*60*60);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			await PMC.createMarket(0,0,3);
			await cyclicMarkets.settleMarket(8,3);
			await increaseTime(1*60*61);
			await PMC.claimCreationAndParticipationReward(10);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();
			assert.equal(Math.round((poolPlotBalAfter-poolPlotBalBefore)/1e18),500);
			assert.equal(Math.round(poolPlotBalAfter/1e18),1000);
			assert.equal(Math.round(lpTotalSupply/1e13),85915339);	
			assert.equal(Math.round((await PMC.getPlotWorthOfLP(await PMC.balanceOf(users[1])))/1e18),200);
			assert.equal(await PMC.getPlotWorthOfLP(await PMC.balanceOf(users[2])),0);
			assert.equal(Math.round((await PMC.getPlotWorthOfLP(await PMC.balanceOf(users[3])))/1e18),800);
		});
		it("Staker S1 unstakes all of their LP ", async () => {
			let totalLp =await PMC.balanceOf(users[1]);
			let userPlotBalBefore = await plotusToken.balanceOf(users[1]);
			let userLPBalBefore = await PMC.balanceOf(users[1]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("unstake(uint)", totalLp);
			await signAndExecuteMetaTx(
			      privateKeyList[1],
			      users[1],
			      functionSignature,
			      PMC,
              	  "PMC"
			      );	
			let userPlotBalAfter = await plotusToken.balanceOf(users[1]);
			let userLPBalAfter = await PMC.balanceOf(users[1]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(Math.round((userPlotBalAfter-userPlotBalBefore)/1e18),200);
			assert.equal(Math.round((userLPBalBefore-userLPBalAfter)/1e13),17183068);
			assert.equal(Math.round((poolPlotBalBefore-poolPlotBalAfter)/1e18),200);
			assert.equal(Math.round(poolPlotBalAfter/1e18),800);
			assert.equal(Math.round(userLPBalAfter/1e13),0);
			assert.equal(Math.round(lpTotalSupply/1e13),68732271);
		});
		it("Staker S3 unstakes all of their LP ", async () => {
			await increaseTime(24 * 3600);
			let totalLp =await PMC.balanceOf(users[3]);
			let userPlotBalBefore = await plotusToken.balanceOf(users[3]);
			let userLPBalBefore = await PMC.balanceOf(users[3]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("unstake(uint)", totalLp);
			await signAndExecuteMetaTx(
			      privateKeyList[3],
			      users[3],
			      functionSignature,
			      PMC,
              	  "PMC"
			      );	
			let userPlotBalAfter = await plotusToken.balanceOf(users[3]);
			let userLPBalAfter = await PMC.balanceOf(users[3]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(Math.round((userPlotBalAfter-userPlotBalBefore)/1e18),800);
			assert.equal(Math.round((userLPBalBefore-userLPBalAfter)/1e13),68732271);
			assert.equal(Math.round((poolPlotBalBefore-poolPlotBalAfter)/1e18),800);
			assert.equal(poolPlotBalAfter,0);
			assert.equal(userLPBalAfter,0);
			assert.equal(lpTotalSupply,0);
		});
		it("Staker S1 stakes 600 Plot", async () => {
			let userPlotBalBefore = await plotusToken.balanceOf(users[1]);
			let userLPBalBefore = await PMC.balanceOf(users[1]);
			let poolPlotBalBefore = await plotusToken.balanceOf(PMC.address);
			let functionSignature = encode3("stake(uint)", toWei(600));
			await signAndExecuteMetaTx(
			      privateKeyList[1],
			      users[1],
			      functionSignature,
			      PMC,
              	  "PMC"
			      );	
			let userPlotBalAfter = await plotusToken.balanceOf(users[1]);
			let userLPBalAfter = await PMC.balanceOf(users[1]);
			let poolPlotBalAfter = await plotusToken.balanceOf(PMC.address);
			let lpTotalSupply = await PMC.totalSupply();

			assert.equal(userPlotBalBefore-userPlotBalAfter,toWei(600));
			assert.equal(userLPBalAfter-userLPBalBefore,toWei(600));
			assert.equal(poolPlotBalAfter-poolPlotBalBefore,toWei(600));
			assert.equal(poolPlotBalAfter,toWei(600));
			assert.equal(userLPBalAfter,toWei(600));
			assert.equal(lpTotalSupply,toWei(600));	
		});

		it("Authorised user should be able to update unstakeRestrictTime", async () => {
			assert.equal(await PMC.unstakeRestrictTime(),3600*24);
			await PMC.updateUnstakeRestrictTime(2*3600*24);
			assert.equal(await PMC.unstakeRestrictTime(),2*3600*24);

		});

		it("Should not be able to update unstakeRestrictTime as 0", async () => {
			await assertRevert(PMC.updateUnstakeRestrictTime(0));
		});

		it("Authorised user should be able to update minLiquidity", async () => {

			assert.equal(await PMC.minLiquidity(),toWei(100));
			await PMC.updateMinLiquidity(toWei(50));
			assert.equal(await PMC.minLiquidity(),toWei(50));

		});

		it("Should not be able to update minLiquidity as 0", async () => {

			await assertRevert(PMC.updateMinLiquidity(0));
			
		});

		it("Authorised user should be able to update wallet address", async () => {

			assert.equal(await PMC.rewardWallet(),users[0]);
			await PMC.updateWalletAddress(users[3]);
			assert.equal(await PMC.rewardWallet(),users[3]);

		});

		it("Should not be able to update wallet address as null", async () => {
			let ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
			assert.equal(await PMC.rewardWallet(),users[3]);
			await assertRevert(PMC.updateWalletAddress(ZERO_ADDRESS));
			assert.equal(await PMC.rewardWallet(),users[3]);

		});

		it("Should not be able to update marketTypeAdditionalReward for invalid market type", async () => {
			await assertRevert(PMC.updateAdditionalRewardPerMarketType(0,5,12));

		});
	});
});
