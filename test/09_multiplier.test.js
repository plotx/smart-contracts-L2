const { assert } = require("chai");
const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const AllMarkets = artifacts.require("MockAllMarkets");
const UserLevels = artifacts.require("UserLevels");
const CyclicMarkets = artifacts.require('MockCyclicMarkets');

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

// Multiplier Sheet
describe("new_Multiplier 1. Multiplier Sheet PLOT Prediction", () => {
    let masterInstance,
        plotusToken,
        allMarkets;
    let marketId = 1;
    let predictionPointsBeforeUser1, predictionPointsBeforeUser2, predictionPointsBeforeUser3, predictionPointsBeforeUser4;

    contract("AllMarkets", async function ([user0, user1, user2, user3, user4, user5, userMarketCreator]) {
        before(async () => {
            masterInstance = await OwnedUpgradeabilityProxy.deployed();
            masterInstance = await Master.at(masterInstance.address);
            plotusToken = await PlotusToken.deployed();
            allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
            cyclicMarkets = await CyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
            userLevels = await UserLevels.deployed();
            marketId = 6;
            await increaseTime(4 * 60 * 60 + 1);
            await plotusToken.transfer(userMarketCreator, toWei(1000));
            await plotusToken.approve(allMarkets.address, toWei(1000), { from: userMarketCreator });
            await cyclicMarkets.whitelistMarketCreator(userMarketCreator);
            await cyclicMarkets.createMarket(0, 0, 0, { from: userMarketCreator });
            marketId++;
        });
        it("1.0 Set user levels", async () => {

          let userLevelsArray = [];
          let multipliers = [];
          for(let i = 1; i <= 25; i++) {
              userLevelsArray.push(i);
              multipliers.push(5*i);
          }
          let actionHash = encode1(
            ['uint256[]', 'uint256[]'],
            [
              userLevelsArray,
              multipliers
            ]
          );

          await userLevels.setMultiplierLevels(userLevelsArray, multipliers);
          await assertRevert(userLevels.setMultiplierLevels(userLevelsArray, multipliers, { from: user2 }));
          await assertRevert(userLevels.setMultiplierLevels([1,2,3], [1,2]));
          
          await userLevels.setUserLevel(user1, 1);
          await userLevels.setUserLevel(user2, 2);
          await userLevels.setUserLevel(user3, 5);
          await userLevels.setUserLevel(user4, 10);
          await userLevels.setUserLevel(user5, 22);
        })
        it("1.1 Position without User levels", async () => {
            await cyclicMarkets.removeUserLevelsContract();
            await assertRevert(cyclicMarkets.removeUserLevelsContract());
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

            // await allMarkets.deposit(toWei(100), { from: user1 });
            // await allMarkets.deposit(toWei(400), { from: user2 });
            // await allMarkets.deposit(toWei(100), { from: user3 });
            // await allMarkets.deposit(toWei(100), { from: user4 });
            // await allMarkets.deposit(toWei(10), { from: user5 });

            await cyclicMarkets.setNextOptionPrice(9);
            assert.equal((await cyclicMarkets.getOptionPrice(marketId, 1)) / 1, 9);
            // await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 1, { from: user3 });
            let functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 1);
            await signAndExecuteMetaTx(
              privateKeyList[3],
              user3,
              functionSignature,
              allMarkets,
              "AM"
            );
            await cyclicMarkets.setNextOptionPrice(18);
            assert.equal((await cyclicMarkets.getOptionPrice(marketId, 2)) / 1, 18);
            // assert.equal((await allMarkets.getMarketData(marketId))._optionPrice[1] / 1, 18);
            // await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 2, { from: user1 });
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 2);
            await signAndExecuteMetaTx(
              privateKeyList[1],
              user1,
              functionSignature,
              allMarkets,
              "AM"
            );
            // await allMarkets.depositAndPlacePrediction(toWei(400), marketId, plotusToken.address, to8Power("400"), 2, { from: user2 });
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(400), marketId, plotusToken.address, to8Power("400"), 2);
            await signAndExecuteMetaTx(
              privateKeyList[2],
              user2,
              functionSignature,
              allMarkets,
              "AM"
            );
            await cyclicMarkets.setNextOptionPrice(27);
            assert.equal((await cyclicMarkets.getOptionPrice(marketId, 3)) / 1, 27);
            // assert.equal((await allMarkets.getMarketData(marketId))._optionPrice[2] / 1, 27);
            // await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 3, { from: user4 });
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 3);
            await signAndExecuteMetaTx(
              privateKeyList[4],
              user4,
              functionSignature,
              allMarkets,
              "AM"
            );
            // await allMarkets.depositAndPlacePrediction(toWei(1000), marketId, plotusToken.address, to8Power("1000"), 3, { from: user5 });
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
            // console.log( //     predictionPointsBeforeUser1, //     predictionPointsBeforeUser2, //     predictionPointsBeforeUser3, //     predictionPointsBeforeUser4, //     predictionPointsBeforeUser5 // );

            const expectedPredictionPoints = [5444.44444, 21777.77777, 10888.88888, 3629.62963, 36296.2963];
            const predictionPointArray = [
                predictionPointsBeforeUser1,
                predictionPointsBeforeUser2,
                predictionPointsBeforeUser3,
                predictionPointsBeforeUser4,
                predictionPointsBeforeUser5,
            ];
            for (let i = 0; i < 5; i++) {
                    assert.equal(parseInt(expectedPredictionPoints[i]), parseInt(predictionPointArray[i]));
            }

            await increaseTime(8 * 60 * 60);
            let daobalanceBefore = await plotusToken.balanceOf(masterInstance.address);
            daobalanceBefore = daobalanceBefore*1;
            await cyclicMarkets.settleMarket(7, 0);
            await increaseTime(8 * 60 * 60);
            let daobalanceAfter = await plotusToken.balanceOf(masterInstance.address);
            daobalanceAfter = daobalanceAfter*1;
            let commission = 0;
            let daoCommission = 3.599;
            assert.equal(~~(daobalanceAfter/1e15), daobalanceBefore/1e15  + daoCommission*1e3);
            let creationReward = 14.399;
            let balanceBefore = await plotusToken.balanceOf(userMarketCreator);
            await cyclicMarkets.claimCreationReward({ from: userMarketCreator });
            let balanceAfter = await plotusToken.balanceOf(userMarketCreator);
            assert.equal(~~(balanceAfter/1e15), balanceBefore/1e15  + creationReward*1e3);
        });

        it("Set User levels contract to activate multiplier", async () => {
          await cyclicMarkets.setUserLevelsContract(userLevels.address);
          await assertRevert(cyclicMarkets.setUserLevelsContract(user1));
        })

        it("1.2 Positions After increasing user levels", async () => {
            await increaseTime(4 * 60 * 60 + 1);

            await cyclicMarkets.createMarket(0, 0, 0, { from: userMarketCreator })
            marketId++;
            
            await assertRevert(userLevels.setUserLevel(user1, 1, {from:user2}));

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

            // await allMarkets.deposit(toWei(100), { from: user1 });
            // await allMarkets.deposit(toWei(400), { from: user2 });
            // await allMarkets.deposit(toWei(100), { from: user3 });
            // await allMarkets.deposit(toWei(100), { from: user4 });
            // await allMarkets.deposit(toWei(10), { from: user5 });

            await cyclicMarkets.setNextOptionPrice(9);
            assert.equal((await cyclicMarkets.getOptionPrice(marketId, 1)) / 1, 9);
            // assert.equal((await allMarkets.getMarketData(marketId))._optionPrice[0] / 1, 9);
            // await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 1, { from: user3 });
            let functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 1);
            await signAndExecuteMetaTx(
              privateKeyList[3],
              user3,
              functionSignature,
              allMarkets,
              "AM"
            );
            await cyclicMarkets.setNextOptionPrice(18);
            assert.equal((await cyclicMarkets.getOptionPrice(marketId, 2)) / 1, 18);
            // assert.equal((await allMarkets.getMarketData(marketId))._optionPrice[1] / 1, 18);
            // await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 2, { from: user1 });
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 2);
            await signAndExecuteMetaTx(
              privateKeyList[1],
              user1,
              functionSignature,
              allMarkets,
              "AM"
            );
            // await allMarkets.depositAndPlacePrediction(toWei(400), marketId, plotusToken.address, to8Power("400"), 2, { from: user2 });
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(400), marketId, plotusToken.address, to8Power("400"), 2);
            await signAndExecuteMetaTx(
              privateKeyList[2],
              user2,
              functionSignature,
              allMarkets,
              "AM"
            );
            await cyclicMarkets.setNextOptionPrice(27);
            assert.equal((await cyclicMarkets.getOptionPrice(marketId, 3)) / 1, 27);
            // assert.equal((await allMarkets.getMarketData(marketId))._optionPrice[2] / 1, 27);
            // await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 3, { from: user4 });
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 3);
            await signAndExecuteMetaTx(
              privateKeyList[4],
              user4,
              functionSignature,
              allMarkets,
              "AM"
            );
            // await allMarkets.depositAndPlacePrediction(toWei(1000), marketId, plotusToken.address, to8Power("1000"), 3, { from: user5 });
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
            // console.log( //     predictionPointsBeforeUser1, //     predictionPointsBeforeUser2, //     predictionPointsBeforeUser3, //     predictionPointsBeforeUser4, //     predictionPointsBeforeUser5 // );

            const expectedPredictionPoints = [5716.66666, 23955.55555, 13611.11111, 5444.44444, 76222.22222];
            const predictionPointArray = [
                predictionPointsBeforeUser1,
                predictionPointsBeforeUser2,
                predictionPointsBeforeUser3,
                predictionPointsBeforeUser4,
                predictionPointsBeforeUser5,
            ];
            for (let i = 0; i < 5; i++) {
                    assert.equal(parseInt(expectedPredictionPoints[i]), parseInt(predictionPointArray[i]));
            }

            await increaseTime(8 * 60 * 60);
            let daobalanceBefore = await plotusToken.balanceOf(masterInstance.address);
            daobalanceBefore = daobalanceBefore*1;
            await cyclicMarkets.settleMarket(marketId, 0);
            await increaseTime(8 * 60 * 60);
            let daobalanceAfter = await plotusToken.balanceOf(masterInstance.address);
            daobalanceAfter = daobalanceAfter*1;
            let commission = 0;
            let daoCommission = 3.5999;
            assert.equal(~~(daobalanceAfter/1e15), ~~((((daobalanceBefore/1e14))  + daoCommission*1e4)/10));
            let creationReward = 14.3999;
            let balanceBefore = await plotusToken.balanceOf(userMarketCreator);
            await cyclicMarkets.claimCreationReward({ from: userMarketCreator });
            let balanceAfter = await plotusToken.balanceOf(userMarketCreator);
            assert.equal(~~(balanceAfter/1e15), ~~((balanceBefore/1e14  + creationReward*1e4)/10));

        });


        it("1.3 Positions After increasing user levels, should not give multiplier twice", async () => {
          await increaseTime(4 * 60 * 60 + 1);

          await cyclicMarkets.createMarket(0, 0, 0, { from: userMarketCreator })
          marketId++;

          await plotusToken.transfer(user1, toWei("200"));

          await plotusToken.approve(allMarkets.address, toWei("100000"), { from: user1 });
          
          // await allMarkets.deposit(toWei(100), { from: user1 });
          // await allMarkets.deposit(toWei(400), { from: user2 });
          // await allMarkets.deposit(toWei(100), { from: user3 });
          // await allMarkets.deposit(toWei(100), { from: user4 });
          // await allMarkets.deposit(toWei(10), { from: user5 });

          await cyclicMarkets.setNextOptionPrice(18);
          // assert.equal((await allMarkets.getMarketData(marketId))._optionPrice[0] / 1, 9);
          // await allMarkets.depositAndPlacePrediction(toWei(100), marketId, plotusToken.address, to8Power("100"), 1, { from: user3 });
          let functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 1);
          await signAndExecuteMetaTx(
            privateKeyList[1],
            user1,
            functionSignature,
            allMarkets,
            "AM"
          );
          predictionPointsBeforeUser1 = (await allMarkets.getUserPredictionPoints(user1, marketId, 1)) / 1e5;

          await cyclicMarkets.setNextOptionPrice(18);
          functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)", toWei(100), marketId, plotusToken.address, to8Power("100"), 1);
          await signAndExecuteMetaTx(
            privateKeyList[1],
            user1,
            functionSignature,
            allMarkets,
            "AM"
          );
          
          predictionPointsUser1SecondTime = (await allMarkets.getUserPredictionPoints(user1, marketId, 1)) / 1e5;
          // console.log( //     predictionPointsBeforeUser1, //     predictionPointsBeforeUser2, //     predictionPointsBeforeUser3, //     predictionPointsBeforeUser4, //     predictionPointsBeforeUser5 // );
          predictionPointsUser1SecondTime = predictionPointsUser1SecondTime/1 - predictionPointsBeforeUser1/1;
          const expectedPredictionPoints = [5716.66666, 5444.44444];
          const predictionPointArray = [
              predictionPointsBeforeUser1/1,
              predictionPointsUser1SecondTime/1
          ];
          for (let i = 0; i < 2; i++) {
              assert.equal(expectedPredictionPoints[i], predictionPointArray[i]);
          }

      });
    });
});
