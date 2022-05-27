const { assert } = require("chai");
const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const AllMarkets = artifacts.require("AllPlotMarkets_9");
const AllMarkets_10 = artifacts.require("AllPlotMarkets_10");
const UserLevels = artifacts.require("UserLevels2");
const CyclicMarkets = artifacts.require('MockCyclicMarkets');
const PooledMarketCreation = artifacts.require('PooledMarketCreation_3');
const MockCyclicMarkets_4 = artifacts.require('CyclicMarkets_7');
const OptionPricing3 = artifacts.require("OptionPricing3_v2");
const OptionPricing2 = artifacts.require("OptionPricing2_v2");

const ethAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const signAndExecuteMetaTx = require("./utils/signAndExecuteMetaTx.js").signAndExecuteMetaTx;
const increaseTime = require("./utils/increaseTime.js").increaseTime;
const assertRevert = require("./utils/assertRevert").assertRevert;
const latestTime = require("./utils/latestTime").latestTime;
const encode = require("./utils/encoder.js").encode;
const encode3 = require("./utils/encoder.js").encode3;
const encode1 = require("./utils/encoder.js").encode1;
const gvProposal = require("./utils/gvProposal.js").gvProposalWithIncentiveViaTokenHolder;
const { toHex, toWei, toChecksumAddress } = require("./utils/ethTools");
const to8Power = (number) => String(parseFloat(number) * 1e8);
let privateKeyList = ["fb437e3e01939d9d4fef43138249f23dc1d0852e69b0b5d1647c087f869fabbd","7c85a1f1da3120c941b83d71a154199ee763307683f206b98ad92c3b4e0af13e","ecc9b35bf13bd5459350da564646d05c5664a7476fe5acdf1305440f88ed784c","f4470c3fca4dbef1b2488d016fae25978effc586a1f83cb29ac8cb6ab5bc2d50","141319b1a84827e1046e93741bf8a9a15a916d49684ab04925ac4ce4573eea23","d54b606094287758dcf19064a8d91c727346aadaa9388732e73c4315b7c606f9","49030e42ce4152e715a7ddaa10e592f8e61d00f70ef11f48546711f159d985df","b96761b1e7ebd1e8464a78a98fe52f53ce6035c32b4b2b12307a629a551ff7cf","d4786e2581571c863c7d12231c3afb6d4cef390c0ac9a24b243293721d28ea95","ed28e3d3530544f1cf2b43d1956b7bd13b63c612d963a8fb37387aa1a5e11460","05b127365cf115d4978a7997ee98f9b48f0ddc552b981c18aa2ee1b3e6df42c6","9d11dd6843f298b01b34bd7f7e4b1037489871531d14b58199b7cba1ac0841e6","f79e90fa4091de4fc2ec70f5bf67b24393285c112658e0d810e6bd711387fbb9","99f1fc0f09230ce745b6a256ba7082e6e51a2907abda3d9e735a5c8188bb4ba1","477f86cce983b9c91a36fdcd4a7ce21144a08dee9b1aafb91b9c70e57f717ce6","b03d2e6bb4a7d71c66a66ff9e9c93549cae4b593f634a4ea2a1f79f94200f5b4","9ddc0f53a81e631dcf39d5155f41ec12ed551b731efc3224f410667ba07b37dc","cf087ff9ae7c9954ad8612d071e5cdf34a6024ee1ae477217639e63a802a53dd","b64f62b94babb82cc78d3d1308631ae221552bb595202fc1d267e1c29ce7ba60","a91e24875f8a534497459e5ccb872c4438be3130d8d74b7e1104c5f94cdcf8c2","4f49f3d029eeeb3fed14d59625acd088b6b34f3b41c527afa09d29e4a7725c32","179795fd7ac7e7efcba3c36d539a1e8659fb40d77d0a3fab2c25562d99793086","4ba37d0b40b879eceaaca2802a1635f2e6d86d5c31e3ff2d2fd13e68dd2a6d3d","6b7f5dfba9cd3108f1410b56f6a84188eee23ab48a3621b209a67eea64293394","870c540da9fafde331a3316cee50c17ad76ddb9160b78b317bef2e6f6fc4bac0","470b4cccaea895d8a5820aed088357e380d66b8e7510f0a1ea9b575850160241","8a55f8942af0aec1e0df3ab328b974a7888ffd60ded48cc6862013da0f41afbc","2e51e8409f28baf93e665df2a9d646a1bf9ac8703cbf9a6766cfdefa249d5780","99ef1a23e95910287d39493d8d9d7d1f0b498286f2b1fdbc0b01495f10cf0958","6652200c53a4551efe2a7541072d817562812003f9d9ef0ec17995aa232378f8","39c6c01194df72dda97da2072335c38231ced9b39afa280452afcca901e73643","12097e411d948f77b7b6fa4656c6573481c1b4e2864c1fca9d5b296096707c45","cbe53bf1976aee6cec830a848c6ac132def1503cffde82ccfe5bd15e75cbaa72","eeab5dcfff92dbabb7e285445aba47bd5135a4a3502df59ac546847aeb5a964f","5ea8279a578027abefab9c17cef186cccf000306685e5f2ee78bdf62cae568dd","0607767d89ad9c7686dbb01b37248290b2fa7364b2bf37d86afd51b88756fe66","e4fd5f45c08b52dae40f4cdff45e8681e76b5af5761356c4caed4ca750dc65cd","145b1c82caa2a6d703108444a5cf03e9cb8c3cd3f19299582a564276dbbba734","736b22ec91ae9b4b2b15e8d8c220f6c152d4f2228f6d46c16e6a9b98b4733120","ac776cb8b40f92cdd307b16b83e18eeb1fbaa5b5d6bd992b3fda0b4d6de8524c","65ba30e2202fdf6f37da0f7cfe31dfb5308c9209885aaf4cef4d572fd14e2903","54e8389455ec2252de063e83d3ce72529d674e6d2dc2070661f01d4f76b63475","fbbbfb525dd0255ee332d51f59648265aaa20c2e9eff007765cf4d4a6940a849","8de5e418f34d04f6ea947ce31852092a24a705862e6b810ca9f83c2d5f9cda4d","ea6040989964f012fd3a92a3170891f5f155430b8bbfa4976cde8d11513b62d9","14d94547b5deca767137fbd14dae73e888f3516c742fad18b83be333b38f0b88","47f05203f6368d56158cda2e79167777fc9dcb0c671ef3aabc205a1636c26a29"];


describe("Option pricing V2 with Multiplier: 3 bucket market", () => {
    let masterInstance,
        plotusToken,
        allMarkets;
    let marketId = 1;
    let predictionPointsBeforeUser1, predictionPointsBeforeUser2, predictionPointsBeforeUser3, predictionPointsBeforeUser4;

    contract("AllMarkets", async function ([user0, user1, user2, user3, user4, user5, userMarketCreator, user6]) {
        before(async () => {
            masterInstance = await OwnedUpgradeabilityProxy.deployed();
            masterInstance = await Master.at(masterInstance.address);
            plotusToken = await PlotusToken.deployed();
            allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
            cyclicMarkets = await CyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
            userLevels = await UserLevels.new();
            marketId = 6;
            await increaseTime(4 * 60 * 60 + 1);
            await plotusToken.transfer(userMarketCreator, toWei(1000000));
            await plotusToken.approve(allMarkets.address, toWei(1000), { from: userMarketCreator });
            await cyclicMarkets.whitelistMarketCreator(userMarketCreator);
            await userLevels.initialize(masterInstance.address);
            await cyclicMarkets.removeUserLevelsContract();
            await cyclicMarkets.setUserLevelsContract(userLevels.address);
        });

        it("Upgrade contract", async () => {
            let cyclicMarketsV4Impl = await MockCyclicMarkets_4.new();
            let allMarketsImpl = await AllMarkets.new();
            await masterInstance.upgradeMultipleImplementations([toHex("AM"), toHex("CM")], [allMarketsImpl.address, cyclicMarketsV4Impl.address]);
            cyclicMarkets = await MockCyclicMarkets_4.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));

            pmImpl = await PooledMarketCreation.new();
            await masterInstance.addNewContract(toHex("PC"), pmImpl.address);
            pmcInstance = await PooledMarketCreation.at(await masterInstance.getLatestAddress(web3.utils.toHex("PC")));
            await cyclicMarkets.whitelistMarketCreator(pmcInstance.address);
            await plotusToken.approve(pmcInstance.address, toWei(10000000));
            await pmcInstance.stake(toWei(1000000));
            await pmcInstance.approveToAllMarkets(toWei(1000000));
            
            optionPricing3 = await OptionPricing3.new();
            optionPricing2 = await OptionPricing2.new();
            await cyclicMarkets.setOptionPricingContract([2,3], [optionPricing2.address, optionPricing3.address]);
            // await cyclicMarkets.setNextOptionPrice(18);
            await cyclicMarkets.alterMarketType(0, 3, 100, 8 * 60 * 60, 60 * 60, 40 * 60, 100 * 1e8);
        });
        it("Upgrade allMarkets contract", async () => {
            let allMarketsImpl = await AllMarkets_10.new();
            await masterInstance.upgradeMultipleImplementations([toHex("AM")], [allMarketsImpl.address]);
            allMarkets = await AllMarkets_10.at(allMarkets.address);
            await allMarkets.addAuthorizedProxyPreditictor(user0);
        });

        it("Update initial liquidity only for Eth markets", async () => {
          // assert.equal((await cyclicMarkets.getInitialLiquidity(0))/1, 120*1e8);
          // assert.equal((await cyclicMarkets.mcPairInitialLiquidity(0, 0))/1, 0);
          await cyclicMarkets.setMCPairInitialLiquidity(0,0, 120*1e8);
          assert.equal((await cyclicMarkets.mcPairInitialLiquidity(0, 0))/1, 120*1e8);
        });

        it("Create market", async () => {
          await assertRevert(pmcInstance.createMarketWithOptionRanges(0, 0, [119500000000, 123000000000], { from: userMarketCreator }));
          await pmcInstance.whitelistMarketCreator(userMarketCreator);
          await assertRevert(pmcInstance.whitelistMarketCreator(userMarketCreator));
          await pmcInstance.createMarketWithOptionRanges(0, 0, [119500000000, 123000000000], { from: userMarketCreator });
          await pmcInstance.deWhitelistMarketCreator(userMarketCreator);
          await assertRevert(pmcInstance.deWhitelistMarketCreator(userMarketCreator));
          marketId++;
          let mcPairInitialLiquidity = 100;
          let predictionFee = mcPairInitialLiquidity*2/100;
          let _params = (await allMarkets.getMarketOptionPricingParams(marketId, 0));
          let initialLiquidityInMarket = _params[0][1]/1e8;
          // assert.equal(initialLiquidityInMarket.toFixed(6),((mcPairInitialLiquidity - predictionFee)).toFixed(6));
          let optionPrices = await cyclicMarkets.getAllOptionPricesWithStake(marketId, 98*1e8);
          assert.equal((optionPrices[0] / 1e5).toFixed(5), 0.51728);
          assert.equal((optionPrices[1] / 1e5).toFixed(5), 0.51728);
          assert.equal((optionPrices[2] / 1e5).toFixed(5), 0.51728);
          assert.equal((await cyclicMarkets.getOptionPriceWithStake(marketId, 1, 98*1e8)/1e5).toFixed(5), 0.51728);
          assert.equal((await cyclicMarkets.getOptionPriceWithStake(marketId, 2, 98*1e8)/1e5).toFixed(5), 0.51728);
          assert.equal((await cyclicMarkets.getOptionPriceWithStake(marketId, 3, 98*1e8)/1e5).toFixed(5), 0.51728);
        });

        it("1.1 Position without User levels", async () => {
            await cyclicMarkets.removeUserLevelsContract();
            await assertRevert(cyclicMarkets.removeUserLevelsContract());
            await plotusToken.transfer(user1, toWei("100"));
            await plotusToken.transfer(user2, toWei("400"));
            await plotusToken.transfer(user3, toWei("100"));
            await plotusToken.transfer(user4, toWei("100"));
            await plotusToken.transfer(user5, toWei("1000"));
            await plotusToken.transfer(user6, toWei("500000"));
            await plotusToken.transfer(cyclicMarkets.address, toWei("1000"));
            await plotusToken.transfer(allMarkets.address, toWei("1000"));

            await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user1 });
            await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user2 });
            await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user3 });
            await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user4 });
            await plotusToken.approve(allMarkets.address, toWei("10000"), { from: user5 });
            await plotusToken.approve(allMarkets.address, toWei("500000"), { from: user6 });
        
            // await cyclicMarkets.setNextOptionPrice(9);
            // assert.equal((await cyclicMarkets.getOptionPrice(marketId, 1)) / 1, 9);
            await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 1, { from: user3 });
            // let functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 1);
            // await signAndExecuteMetaTx(
            //   privateKeyList[3],
            //   user3,
            //   functionSignature,
            //   allMarkets,
            //   "AM"
            // );

            assert.equal((await allMarkets.getUserPredictionPoints(user3, marketId, 1))/1, 189452);
            // await cyclicMarkets.setNextOptionPrice(18);
            // assert.equal((await cyclicMarkets.getOptionPrice(marketId, 2)) / 1, 18);
            // assert.equal((await allMarkets.getMarketData(marketId))._optionPrice[1] / 1, 18);
            assert.equal(await cyclicMarkets.getOptionPriceWithStake(marketId, 2, 98*1e8)/1, 0.32775*1e5);
            // await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 2, { from: user1 });
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 2);
            await signAndExecuteMetaTx(
              privateKeyList[1],
              user1,
              functionSignature,
              allMarkets,
              "AM"
            );
            assert.equal((await allMarkets.getUserPredictionPoints(user1, marketId, 2))/1, 299008);
            // await cyclicMarkets.setNextOptionPrice(27);
            // assert.equal((await cyclicMarkets.getOptionPrice(marketId, 3)) / 1, 27);
            // assert.equal((await allMarkets.getMarketData(marketId))._optionPrice[2] / 1, 27);
            assert.equal(await cyclicMarkets.getOptionPriceWithStake(marketId, 3, 98*1e8)/1, 0.24283*1e5);
            // await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 3, { from: user4 });
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 3);
            await signAndExecuteMetaTx(
              privateKeyList[4],
              user4,
              functionSignature,
              allMarkets,
              "AM"
              );
            assert.equal((await allMarkets.getUserPredictionPoints(user4, marketId, 3))/1, 403574);
            assert.equal(await cyclicMarkets.getOptionPriceWithStake(marketId, 2, 392*1e8)/1, 0.53349*1e5);
            // await allMarkets.depositAndPlacePrediction(toWei(400), marketId, plotusToken.address, to8Power("400"), 2, { from: user2 });
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(400), marketId, plotusToken.address, to8Power("400"), 2);
            await signAndExecuteMetaTx(
              privateKeyList[2],
              user2,
              functionSignature,
              allMarkets,
              "AM"
            );
            assert.equal((await allMarkets.getUserPredictionPoints(user2, marketId, 2))/1, 734784);
            assert.equal(await cyclicMarkets.getOptionPriceWithStake(marketId, 3, 1960000000)/1, 0.20095*1e5);
            // await allMarkets.depositAndPlacePrediction(toWei(1000), marketId, plotusToken.address, to8Power("1000"), 3, { from: user5 });
            assert.equal(await allMarkets.getUserFlags(marketId,user5),false);
            functionSignature = encode3("depositAndPredictForWithDBPlot(address,uint,uint,uint256,uint64,bool)", user5,toWei(20), marketId, 3, to8Power("20"),true);
            await signAndExecuteMetaTx(
              privateKeyList[0],
              user0,
              functionSignature,
              allMarkets,
              "AM"
            );
            assert.equal((await allMarkets.getUserPredictionPoints(user5, marketId, 3))/1, 97536);
            assert.equal(await allMarkets.getUserFlags(marketId,user5),true);

            await cyclicMarkets.updateUintParameters(toHex("MAXP"), toWei(500000));
            // assert.equal(await cyclicMarkets.getOptionPriceWithStake(marketId, 1, 190000*0.98*1e8)/1, 0.98*1e5);
            await allMarkets.depositAndPlacePrediction(toWei(200000), marketId, plotusToken.address, to8Power("200000"), 1, { from: user6 });

            // should be still able to participate if not using dbplot
            functionSignature = encode3("depositAndPredictForWithDBPlot(address,uint,uint,uint256,uint64,bool)", user5,toWei(20), marketId, 3, to8Power("20"),false);
            await signAndExecuteMetaTx(
              privateKeyList[0],
              user0,
              functionSignature,
              allMarkets,
              "AM"
            );

            // should revert if tries to participate with dbPlot more than 1.
            functionSignature = encode3("depositAndPredictForWithDBPlot(address,uint,uint,uint256,uint64,bool)", user5,toWei(20), marketId, 3, to8Power("20"),true);
            await assertRevert(signAndExecuteMetaTx(
                          privateKeyList[0],
                          user0,
                          functionSignature,
                          allMarkets,
                          "AM"
                        ));
            // functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(190000), marketId, plotusToken.address, to8Power("190000"), 1);
            // await signAndExecuteMetaTx(
            //   privateKeyList[7],
            //   user6,
            //   functionSignature,
            //   allMarkets,
            //   "AM"
            // );

            assert.equal((await allMarkets.getUserPredictionPoints(user6, marketId, 1))/1, 200000000);

            assert.equal((await allMarkets.getUserPredictionPoints(pmcInstance.address, marketId, 1)), 120001);
            assert.equal((await allMarkets.getUserPredictionPoints(pmcInstance.address, marketId, 2)), 120001);
            assert.equal((await allMarkets.getUserPredictionPoints(pmcInstance.address, marketId, 3)), 120001);

            // predictionPointsBeforeUser1 = (await allMarkets.getUserPredictionPoints(user1, marketId, 2)) / 1e5;
            // predictionPointsBeforeUser2 = (await allMarkets.getUserPredictionPoints(user2, marketId, 2)) / 1e5;
            // predictionPointsBeforeUser3 = (await allMarkets.getUserPredictionPoints(user3, marketId, 1)) / 1e5;
            // predictionPointsBeforeUser4 = (await allMarkets.getUserPredictionPoints(user4, marketId, 3)) / 1e5;
            // predictionPointsBeforeUser5 = (await allMarkets.getUserPredictionPoints(user5, marketId, 3)) / 1e5;
            // // console.log( //     predictionPointsBeforeUser1, //     predictionPointsBeforeUser2, //     predictionPointsBeforeUser3, //     predictionPointsBeforeUser4, //     predictionPointsBeforeUser5 // );

            // const expectedPredictionPoints = [1814.81481, 1814.81481, 1814.81481, 5444.44444, 21777.77777, 10888.88888, 3629.62963, 36296.2963];
            // const predictionPointArray = [
            //     predictionPointsBeforeMC1,
            //     predictionPointsBeforeMC2,
            //     predictionPointsBeforeMC3,
            //     predictionPointsBeforeUser1,
            //     predictionPointsBeforeUser2,
            //     predictionPointsBeforeUser3,
            //     predictionPointsBeforeUser4,
            //     predictionPointsBeforeUser5,
            // ];
            // for (let i = 0; i < predictionPointArray.length; i++) {
            //         assert.equal(parseInt(expectedPredictionPoints[i]), parseInt(predictionPointArray[i]));
            // }

            // await increaseTime(8 * 60 * 60);
        });
    
      });
});

