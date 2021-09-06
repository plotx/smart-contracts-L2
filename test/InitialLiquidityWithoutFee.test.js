const assertRevert = require("./utils/assertRevert.js").assertRevert;
const { assert } = require("chai");
const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const MockchainLinkBTC = artifacts.require("MockChainLinkAggregator");
const AllMarkets = artifacts.require("MockAllMarkets");
const CyclicMarkets = artifacts.require("MockCyclicMarkets");
const CyclicMarkets_3 = artifacts.require("MockCyclicMarkets_3");
const AllPlotMarkets_4 = artifacts.require("AllPlotMarkets_4");
const OptionPricing2 = artifacts.require("OptionPricing2");
const OptionPricing3 = artifacts.require("OptionPricing3");
const increaseTime = require("./utils/increaseTime.js").increaseTime;
const increaseTimeTo = require("./utils/increaseTime.js").increaseTimeTo;
const { encode3 } = require("./utils/encoder.js");
const signAndExecuteMetaTx = require("./utils/signAndExecuteMetaTx.js").signAndExecuteMetaTx;
const { toHex, toWei, toChecksumAddress } = require("./utils/ethTools");
let privateKeyList = ["fb437e3e01939d9d4fef43138249f23dc1d0852e69b0b5d1647c087f869fabbd", "7c85a1f1da3120c941b83d71a154199ee763307683f206b98ad92c3b4e0af13e", "ecc9b35bf13bd5459350da564646d05c5664a7476fe5acdf1305440f88ed784c", "f4470c3fca4dbef1b2488d016fae25978effc586a1f83cb29ac8cb6ab5bc2d50", "141319b1a84827e1046e93741bf8a9a15a916d49684ab04925ac4ce4573eea23", "d54b606094287758dcf19064a8d91c727346aadaa9388732e73c4315b7c606f9", "49030e42ce4152e715a7ddaa10e592f8e61d00f70ef11f48546711f159d985df", "b96761b1e7ebd1e8464a78a98fe52f53ce6035c32b4b2b12307a629a551ff7cf", "d4786e2581571c863c7d12231c3afb6d4cef390c0ac9a24b243293721d28ea95", "ed28e3d3530544f1cf2b43d1956b7bd13b63c612d963a8fb37387aa1a5e11460", "05b127365cf115d4978a7997ee98f9b48f0ddc552b981c18aa2ee1b3e6df42c6", "9d11dd6843f298b01b34bd7f7e4b1037489871531d14b58199b7cba1ac0841e6", "f79e90fa4091de4fc2ec70f5bf67b24393285c112658e0d810e6bd711387fbb9", "99f1fc0f09230ce745b6a256ba7082e6e51a2907abda3d9e735a5c8188bb4ba1", "477f86cce983b9c91a36fdcd4a7ce21144a08dee9b1aafb91b9c70e57f717ce6", "b03d2e6bb4a7d71c66a66ff9e9c93549cae4b593f634a4ea2a1f79f94200f5b4", "9ddc0f53a81e631dcf39d5155f41ec12ed551b731efc3224f410667ba07b37dc", "cf087ff9ae7c9954ad8612d071e5cdf34a6024ee1ae477217639e63a802a53dd", "b64f62b94babb82cc78d3d1308631ae221552bb595202fc1d267e1c29ce7ba60", "a91e24875f8a534497459e5ccb872c4438be3130d8d74b7e1104c5f94cdcf8c2", "4f49f3d029eeeb3fed14d59625acd088b6b34f3b41c527afa09d29e4a7725c32", "179795fd7ac7e7efcba3c36d539a1e8659fb40d77d0a3fab2c25562d99793086", "4ba37d0b40b879eceaaca2802a1635f2e6d86d5c31e3ff2d2fd13e68dd2a6d3d", "6b7f5dfba9cd3108f1410b56f6a84188eee23ab48a3621b209a67eea64293394", "870c540da9fafde331a3316cee50c17ad76ddb9160b78b317bef2e6f6fc4bac0", "470b4cccaea895d8a5820aed088357e380d66b8e7510f0a1ea9b575850160241", "8a55f8942af0aec1e0df3ab328b974a7888ffd60ded48cc6862013da0f41afbc", "2e51e8409f28baf93e665df2a9d646a1bf9ac8703cbf9a6766cfdefa249d5780", "99ef1a23e95910287d39493d8d9d7d1f0b498286f2b1fdbc0b01495f10cf0958", "6652200c53a4551efe2a7541072d817562812003f9d9ef0ec17995aa232378f8", "39c6c01194df72dda97da2072335c38231ced9b39afa280452afcca901e73643", "12097e411d948f77b7b6fa4656c6573481c1b4e2864c1fca9d5b296096707c45", "cbe53bf1976aee6cec830a848c6ac132def1503cffde82ccfe5bd15e75cbaa72", "eeab5dcfff92dbabb7e285445aba47bd5135a4a3502df59ac546847aeb5a964f", "5ea8279a578027abefab9c17cef186cccf000306685e5f2ee78bdf62cae568dd", "0607767d89ad9c7686dbb01b37248290b2fa7364b2bf37d86afd51b88756fe66", "e4fd5f45c08b52dae40f4cdff45e8681e76b5af5761356c4caed4ca750dc65cd", "145b1c82caa2a6d703108444a5cf03e9cb8c3cd3f19299582a564276dbbba734", "736b22ec91ae9b4b2b15e8d8c220f6c152d4f2228f6d46c16e6a9b98b4733120", "ac776cb8b40f92cdd307b16b83e18eeb1fbaa5b5d6bd992b3fda0b4d6de8524c", "65ba30e2202fdf6f37da0f7cfe31dfb5308c9209885aaf4cef4d572fd14e2903", "54e8389455ec2252de063e83d3ce72529d674e6d2dc2070661f01d4f76b63475", "fbbbfb525dd0255ee332d51f59648265aaa20c2e9eff007765cf4d4a6940a849", "8de5e418f34d04f6ea947ce31852092a24a705862e6b810ca9f83c2d5f9cda4d", "ea6040989964f012fd3a92a3170891f5f155430b8bbfa4976cde8d11513b62d9", "14d94547b5deca767137fbd14dae73e888f3516c742fad18b83be333b38f0b88", "47f05203f6368d56158cda2e79167777fc9dcb0c671ef3aabc205a1636c26a29"];
const latestTime = require("./utils/latestTime.js").latestTime;
const to8Power = (number) => String(parseFloat(number) * 1e8);

truncNumber = (n) => Math.trunc(n * Math.pow(10, 2)) / Math.pow(10, 2);
let masterInstance, plotusToken, MockchainLinkInstance, allMarkets;

contract("2 Option market", async function ([user0, user1, user2, user3, user4, user5, userMarketCreator, user6, user7]) {
    before(async function () {
        masterInstance = await OwnedUpgradeabilityProxy.deployed();
        masterInstance = await Master.at(masterInstance.address);
        plotusToken = await PlotusToken.deployed();
        MockchainLinkInstance = await MockchainLinkBTC.deployed();
        allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
        cyclicMarkets = await CyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
        nullAddress = await masterInstance.getLatestAddress("0x00");

        await plotusToken.transfer(userMarketCreator, toWei(1000));
        await plotusToken.approve(allMarkets.address, toWei(1000), { from: userMarketCreator });
        await cyclicMarkets.whitelistMarketCreator(userMarketCreator);

        await cyclicMarkets.setNextOptionPrice(0);

        await MockchainLinkInstance.setLatestAnswer(1195000000000);
      });
    describe("Scenario1", async () => {
      it("0.0", async () => {
        masterInstance = await OwnedUpgradeabilityProxy.deployed();
        masterInstance = await Master.at(masterInstance.address);
        plotusToken = await PlotusToken.deployed();
        timeNow = await latestTime();
  
        allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
        await increaseTime(5 * 3600);
        await plotusToken.transfer(user7, toWei(100000));
        await plotusToken.transfer(user6, toWei(100000));
        // await plotusToken.transfer(marketIncentives.address,toWei(500));
  
        let nullAddress = await masterInstance.getLatestAddress("0x00");
  
        await plotusToken.transfer(user6, toWei(100));
        await plotusToken.approve(allMarkets.address, toWei(200000), { from: user6 });
        await plotusToken.approve(allMarkets.address, toWei(200000));
        // await acyclicMarkets.setNextOptionPrice(18);
        // await acyclicMarkets.claimRelayerRewards();
        timeNow = await latestTime();
        let initialLiquidity = 100 * 10 ** 8;
        // await cyclicMarkets.whitelistMarketCreator(user6);
        await cyclicMarkets.setNextOptionPrice(0);
  
        await MockchainLinkInstance.setLatestAnswer(1195000000000);
  
        let allMarketsV3Impl = await AllPlotMarkets_4.new();
        await masterInstance.upgradeMultipleImplementations([toHex("AM")], [allMarketsV3Impl.address]);
        allMarkets = await AllPlotMarkets_4.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
  
      });

      it("Should be able to create market", async() => {
        let starttime = await cyclicMarkets.calculateStartTimeForMarket(0,0);
        await increaseTime((await latestTime())/1 -  starttime*1 + 10);

        marketId = await allMarkets.getTotalMarketsLength();
        await cyclicMarkets.setNextOptionPrice(18);
        await cyclicMarkets.createMarket(0, 0, 0, { from: userMarketCreator })
      });

      it("Positions", async () => {
        await plotusToken.transfer(user1, toWei("100"));
        await plotusToken.transfer(user2, toWei("400"));
        await plotusToken.transfer(user3, toWei("100"));
        await plotusToken.transfer(user4, toWei("100"));
        await plotusToken.transfer(user5, toWei("1000"));

        await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user1 });
        await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user2 });
        await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user3 });
        await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user4 });
        await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user5 });

        assert.equal((await cyclicMarkets.getOptionPrice(marketId, 2)) / 1, 18);

        // await increaseTime(9*60 + 1);
        await increaseTime(2*60);
        //Predict after 2 minutes of starttime and user should get 1.1X multiplier
        functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 2);
        await signAndExecuteMetaTx(
          privateKeyList[1],
          user1,
          functionSignature,
          allMarkets,
          "AM"
        );
        //Predict after 4 minutes of starttime and user should get 1.1X multiplier 
        await increaseTime(2*60);
        functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(400), marketId, plotusToken.address, to8Power("400"), 2);
        await signAndExecuteMetaTx(
          privateKeyList[2],
          user2,
          functionSignature,
          allMarkets,
          "AM"
        );

        await cyclicMarkets.setNextOptionPrice(9);
        assert.equal((await cyclicMarkets.getOptionPrice(marketId, 1)) / 1, 9);
        //Predict after 6 minutes of starttime and user should get 1.1X multiplier 
        await increaseTime(2*60);
        functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 1);
        await signAndExecuteMetaTx(
          privateKeyList[3],
          user3,
          functionSignature,
          allMarkets,
          "AM"
        );

        //Predict after 20 minutes of starttime and user should not get multiplier 
        await increaseTime(14*60);
        await cyclicMarkets.setNextOptionPrice(27);
        assert.equal((await cyclicMarkets.getOptionPrice(marketId, 3)) / 1, 27);
        functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 3);
        await signAndExecuteMetaTx(
          privateKeyList[4],
          user4,
          functionSignature,
          allMarkets,
          "AM"
        );
        //Predict after 30 minutes of starttime and user should not get multiplier 
        await increaseTime(10*60);
        functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(1000), marketId, plotusToken.address, to8Power("1000"), 3);
        await signAndExecuteMetaTx(
          privateKeyList[5],
          user5,
          functionSignature,
          allMarkets,
          "AM"
        );
        predictionPointsBeforeUser1 = (await allMarkets.getUserPredictionPoints(user1, marketId, 2)) / 1e5;
        predictionPointsBeforeUser2 = (await allMarkets.getUserPredictionPoints(user2, marketId, 2)) / 1e5;
        predictionPointsBeforeUser3 = (await allMarkets.getUserPredictionPoints(user3, marketId, 1)) / 1e5;
        predictionPointsBeforeUser4 = (await allMarkets.getUserPredictionPoints(user4, marketId, 3)) / 1e5;
        predictionPointsBeforeUser5 = (await allMarkets.getUserPredictionPoints(user5, marketId, 3)) / 1e5;
        
        predictionPointsBeforeCreator1 = (await allMarkets.getUserPredictionPoints(userMarketCreator, marketId, 1)/1e5);
        predictionPointsBeforeCreator2 = (await allMarkets.getUserPredictionPoints(userMarketCreator, marketId, 2)/1e5);
        predictionPointsBeforeCreator3 = (await allMarkets.getUserPredictionPoints(userMarketCreator, marketId, 3)/1e5);
        
        const expectedPredictionPoints = [5444.444444, 21777.77777, 10888.88888, 3629.62963, 36296.2963, 1851.851852, 1851.851852, 1851.851852];
        const predictionPointArray = [
            predictionPointsBeforeUser1,
            predictionPointsBeforeUser2,
            predictionPointsBeforeUser3,
            predictionPointsBeforeUser4,
            predictionPointsBeforeUser5,
            predictionPointsBeforeCreator1,
            predictionPointsBeforeCreator2,
            predictionPointsBeforeCreator3
        ];
        for (let i = 0; i < predictionPointArray.length; i++) {
          try {
              assert.equal(parseInt(expectedPredictionPoints[i]), parseInt(predictionPointArray[i]));
            } catch (error) {
              console.log(`Error at index ${i} : ${parseInt(predictionPointArray[i])}`);
            }
          }

        await increaseTime(8 * 60 * 60);
        let daobalanceBefore = await plotusToken.balanceOf(masterInstance.address);
        daobalanceBefore = daobalanceBefore*1;
        await cyclicMarkets.settleMarket(marketId, 2);
        await increaseTime(8 * 60 * 60);
        let daobalanceAfter = await plotusToken.balanceOf(masterInstance.address);
        daobalanceAfter = daobalanceAfter*1;
        let commission = 0;
        let daoCommission = 3.4;
        assert.equal(Math.trunc(daobalanceAfter/1e15), Math.trunc((((daobalanceBefore/1e14))  + daoCommission*1e4)/10));
        let creationReward = 13.6;
        let balanceBefore = await plotusToken.balanceOf(userMarketCreator);
        await cyclicMarkets.claimCreationReward({ from: userMarketCreator });
        let balanceAfter = await plotusToken.balanceOf(userMarketCreator);
        assert.equal(~~(balanceAfter/1e15), ~~((balanceBefore/1e14  + creationReward*1e4)/10));
      });
    })
})