const { assert } = require("chai");
const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const AllMarkets = artifacts.require("MockAllMarkets");
const CyclicMarkets = artifacts.require("MockCyclicMarkets");
const EthChainlinkOracle = artifacts.require('MockChainLinkAggregator');
const MockUniswapRouter = artifacts.require('MockUniswapRouter');
const SwapAndPredictWithPlot = artifacts.require('SwapAndPredictWithPlot');
const SampleERC = artifacts.require('SampleERC');
const ClaimAndPredict = artifacts.require('ClaimAndPredict');

const BLOT = artifacts.require("BPLOT");
const BigNumber = require("bignumber.js");

const increaseTime = require("./utils/increaseTime.js").increaseTime;
const assertRevert = require("./utils/assertRevert").assertRevert;
const latestTime = require("./utils/latestTime").latestTime;
const encode = require("./utils/encoder.js").encode;
const encode1 = require("./utils/encoder.js").encode1;

const encode3 = require("./utils/encoder.js").encode3;
const signAndExecuteMetaTx = require("./utils/signAndExecuteMetaTx.js").signAndExecuteMetaTx;
const signAndGetMetaTxData = require("./utils/signAndExecuteMetaTx.js").signAndGetMetaTxData;
const BN = require('bn.js');

const gvProposal = require("./utils/gvProposal.js").gvProposalWithIncentiveViaTokenHolder;
const { toHex, toWei, toChecksumAddress } = require("./utils/ethTools");
const to8Power = (number) => String(parseFloat(number) * 1e8);
let pkList = ["fb437e3e01939d9d4fef43138249f23dc1d0852e69b0b5d1647c087f869fabbd", "7c85a1f1da3120c941b83d71a154199ee763307683f206b98ad92c3b4e0af13e", "ecc9b35bf13bd5459350da564646d05c5664a7476fe5acdf1305440f88ed784c", "f4470c3fca4dbef1b2488d016fae25978effc586a1f83cb29ac8cb6ab5bc2d50", "141319b1a84827e1046e93741bf8a9a15a916d49684ab04925ac4ce4573eea23", "d54b606094287758dcf19064a8d91c727346aadaa9388732e73c4315b7c606f9", "49030e42ce4152e715a7ddaa10e592f8e61d00f70ef11f48546711f159d985df", "b96761b1e7ebd1e8464a78a98fe52f53ce6035c32b4b2b12307a629a551ff7cf", "d4786e2581571c863c7d12231c3afb6d4cef390c0ac9a24b243293721d28ea95", "ed28e3d3530544f1cf2b43d1956b7bd13b63c612d963a8fb37387aa1a5e11460", "05b127365cf115d4978a7997ee98f9b48f0ddc552b981c18aa2ee1b3e6df42c6", "9d11dd6843f298b01b34bd7f7e4b1037489871531d14b58199b7cba1ac0841e6", "f79e90fa4091de4fc2ec70f5bf67b24393285c112658e0d810e6bd711387fbb9", "99f1fc0f09230ce745b6a256ba7082e6e51a2907abda3d9e735a5c8188bb4ba1", "477f86cce983b9c91a36fdcd4a7ce21144a08dee9b1aafb91b9c70e57f717ce6", "b03d2e6bb4a7d71c66a66ff9e9c93549cae4b593f634a4ea2a1f79f94200f5b4", "9ddc0f53a81e631dcf39d5155f41ec12ed551b731efc3224f410667ba07b37dc", "cf087ff9ae7c9954ad8612d071e5cdf34a6024ee1ae477217639e63a802a53dd", "b64f62b94babb82cc78d3d1308631ae221552bb595202fc1d267e1c29ce7ba60", "a91e24875f8a534497459e5ccb872c4438be3130d8d74b7e1104c5f94cdcf8c2", "4f49f3d029eeeb3fed14d59625acd088b6b34f3b41c527afa09d29e4a7725c32", "179795fd7ac7e7efcba3c36d539a1e8659fb40d77d0a3fab2c25562d99793086", "4ba37d0b40b879eceaaca2802a1635f2e6d86d5c31e3ff2d2fd13e68dd2a6d3d", "6b7f5dfba9cd3108f1410b56f6a84188eee23ab48a3621b209a67eea64293394", "870c540da9fafde331a3316cee50c17ad76ddb9160b78b317bef2e6f6fc4bac0", "470b4cccaea895d8a5820aed088357e380d66b8e7510f0a1ea9b575850160241", "8a55f8942af0aec1e0df3ab328b974a7888ffd60ded48cc6862013da0f41afbc", "2e51e8409f28baf93e665df2a9d646a1bf9ac8703cbf9a6766cfdefa249d5780", "99ef1a23e95910287d39493d8d9d7d1f0b498286f2b1fdbc0b01495f10cf0958", "6652200c53a4551efe2a7541072d817562812003f9d9ef0ec17995aa232378f8", "39c6c01194df72dda97da2072335c38231ced9b39afa280452afcca901e73643", "12097e411d948f77b7b6fa4656c6573481c1b4e2864c1fca9d5b296096707c45", "cbe53bf1976aee6cec830a848c6ac132def1503cffde82ccfe5bd15e75cbaa72", "eeab5dcfff92dbabb7e285445aba47bd5135a4a3502df59ac546847aeb5a964f", "5ea8279a578027abefab9c17cef186cccf000306685e5f2ee78bdf62cae568dd", "0607767d89ad9c7686dbb01b37248290b2fa7364b2bf37d86afd51b88756fe66", "e4fd5f45c08b52dae40f4cdff45e8681e76b5af5761356c4caed4ca750dc65cd", "145b1c82caa2a6d703108444a5cf03e9cb8c3cd3f19299582a564276dbbba734", "736b22ec91ae9b4b2b15e8d8c220f6c152d4f2228f6d46c16e6a9b98b4733120", "ac776cb8b40f92cdd307b16b83e18eeb1fbaa5b5d6bd992b3fda0b4d6de8524c", "65ba30e2202fdf6f37da0f7cfe31dfb5308c9209885aaf4cef4d572fd14e2903", "54e8389455ec2252de063e83d3ce72529d674e6d2dc2070661f01d4f76b63475", "fbbbfb525dd0255ee332d51f59648265aaa20c2e9eff007765cf4d4a6940a849", "8de5e418f34d04f6ea947ce31852092a24a705862e6b810ca9f83c2d5f9cda4d", "ea6040989964f012fd3a92a3170891f5f155430b8bbfa4976cde8d11513b62d9", "14d94547b5deca767137fbd14dae73e888f3516c742fad18b83be333b38f0b88", "47f05203f6368d56158cda2e79167777fc9dcb0c671ef3aabc205a1636c26a29"];
describe("ClaimAndPredict", () => {
    contract("AllMarket", async function (users) {
        // Multiplier Sheet
        let masterInstance,
            plotusToken,
            allMarkets;
        let totalClaimedByUser = {};
        let userClaimGlobalNonce = {};
        let predictionPointsBeforeUser1, predictionPointsBeforeUser2, predictionPointsBeforeUser3, predictionPointsBeforeUser4;
        before(async () => {
            masterInstance = await OwnedUpgradeabilityProxy.deployed();
            masterInstance = await Master.at(masterInstance.address);
            plotusToken = await PlotusToken.deployed();
            allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
			cyclicMarkets = await CyclicMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("CM")));
            router = await MockUniswapRouter.deployed();
			spInstance = await SwapAndPredictWithPlot.at(await masterInstance.getLatestAddress(web3.utils.toHex("SP")));
            externalToken = await SampleERC.new("USDP", "USDP"); 
            await externalToken.mint(users[0], toWei(1000000));
            plotTokenPrice = 0.01;
            externalTokenPrice = 1/plotTokenPrice; 
            await plotusToken.transfer(router.address,toWei(10000));
            
            nullAddress = await masterInstance.getLatestAddress(toHex("0x00"));
            
            
            await increaseTime(4 * 60 * 60 + 1);
            await cyclicMarkets.claimRelayerRewards();
            // await plotusToken.transfer(masterInstance.address,toWei(100000));
            await plotusToken.transfer(users[11],toWei(1000));
            await plotusToken.approve(allMarkets.address, toWei(10000), {from:users[11]});
            await cyclicMarkets.setNextOptionPrice(18);
            await cyclicMarkets.whitelistMarketCreator(users[11]);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});
            // await marketIncentives.claimCreationReward(100,{from:users[11]});
            BLOTInstance = await BLOT.at(await masterInstance.getLatestAddress(web3.utils.toHex("BL")));

            claimAndPredict = await ClaimAndPredict.new(masterInstance.address, router.address, (await router.WETH()));
            await assertRevert(ClaimAndPredict.new(nullAddress, router.address, (await router.WETH())));
            await assertRevert(ClaimAndPredict.new(masterInstance.address, nullAddress, (await router.WETH())));
            await assertRevert(ClaimAndPredict.new(masterInstance.address, router.address, nullAddress));
    
            await assertRevert(BLOTInstance.convertToPLOT(users[0], users[1],toWei(100)));
        });

        async function getSignedClaimMessage(authUserPvtKey, toUser, userClaimNonce, claimAmount, strategyId, totalClaimed, cpContractAddress) {
            let data0 = web3.utils.toHex(toUser);
            let dataPacked = web3.eth.abi.encodeParameters(["uint256", "uint256","uint256", "uint256"], [userClaimNonce, claimAmount, strategyId, totalClaimed]);
            data_1 = data0 + dataPacked.slice(2) + cpContractAddress.slice(2);
            data_1 = web3.utils.sha3(data_1);
            let signData = await web3.eth.accounts.sign(data_1, authUserPvtKey);
            return signData;
        }

        async function getEventDataFromTx(contractInstance, eventName, txData) {
            let eventMetaData = (contractInstance.abi).filter(m=>m.name == eventName);
            let eventTxData = txData.receipt.rawLogs.filter(m=>m.topics[0]==eventMetaData[0].signature);
            let eventData = eventTxData[0].data;
            return web3.eth.abi.decodeLog(eventMetaData[0].inputs, eventData, [eventTxData[0].topics[1], eventTxData[0].topics[0]]);
        }

        async function constructMetaTxStructJson(targetAddress, userAddress, functionSignature, sigR, sigS, sigV) {
            return {
                targetAddress: targetAddress,
                userAddress: userAddress,
                functionSignature: functionSignature,
                sigR: sigR,
                sigS: sigS,
                sigV: sigV
            };
        }
        
        it("Add claimAndPredict contract as minter in BLOT", async () => {
            await BLOTInstance.addMinter(users[5]);
            await BLOTInstance.addMinter(claimAndPredict.address);
            await plotusToken.transfer(claimAndPredict.address, toWei(100000));
            assert.equal(await BLOTInstance.isMinter(users[5]), true);
            assert.equal(await BLOTInstance.isMinter(claimAndPredict.address), true);
        });

        it("Authorized address should be able to change authorized", async () => {
            await assertRevert(claimAndPredict.changeAuthorizedAddress(nullAddress));
            await assertRevert(claimAndPredict.changeAuthorizedAddress(users[1], {from:users[1]}));
            await claimAndPredict.changeAuthorizedAddress(users[1]);
            assert.equal((await claimAndPredict.authorized()), users[1]);
            await claimAndPredict.changeAuthorizedAddress(users[0], {from:users[1]});
        });

        it("Set the max claim limit of strategy", async() => {
            await claimAndPredict.updateMaxClaimPerStrategy([1], [toWei(100)]);
        });
        
        //User index 1
        it("Sign for Claim of 20 bPLOT and predict with same", async () => {
            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 7;
            let predictionOption = 1;
            let userIndex = 1;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);
            
            let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            assert.equal(predictionAmount, eventObj.value/1e8);
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            totalClaimedByUser[users[userIndex]] += claimAmount;
            userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });
        
        //User index 2
        it("Sign for Claim of 20 bPLOT and predict with 30 bPLOT, user didn't have bPLOT balance - Should fail", async () => {
            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 30;
            let depositAmount = 0;
            let marketId = 7;
            let predictionOption = 1;
            let userIndex = 2;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            assert.equal((await BLOTInstance.balanceOf(users[userIndex])), 0);

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            // assert.equal(predictionAmount, eventObj.value/1e8);
            // assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            // totalClaimedByUser[users[userIndex]] += claimAmount;
            // userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 3
        it("Sign for Claim of 20 bPLOT and predict with 20 existing bPLOT, user had enough bPLOT balance", async () => {
            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 40;
            let depositAmount = 0;
            let marketId = 7;
            let predictionOption = 1;
            let userIndex = 3;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            await plotusToken.approve(BLOTInstance.address, toWei(10000000));
            await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount-claimAmount));

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);
            
            let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            assert.equal(predictionAmount, eventObj.value/1e8);
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            totalClaimedByUser[users[userIndex]] += claimAmount;
            userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 4
        it("Sign for Claim of 10 bPLOT and predict with 10 more PLOT", async () => {
            let claimAmount = 10;
            let strategyId = 1;
            let plotPredictionAmount = 10;
            let bPlotPredictionAmount = 10;
            let depositAmount = 10;
            let marketId = 7;
            let predictionOption = 2;
            let userIndex = 4;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            await plotusToken.transfer(users[userIndex], toWei(depositAmount));
            await plotusToken.approve(allMarkets.address, toWei(depositAmount), {from:users[userIndex]});

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);
            
            let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            assert.equal(predictionAmount, eventObj.value/1e8);
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            totalClaimedByUser[users[userIndex]] += claimAmount;
            userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 5
        it("Sign for Claim of 20 bPLOT and predict with 10 more PLOT, User didn't have PLOT balance - Should Fail", async () => {
            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 10;
            let bPlotPredictionAmount = 20;
            let depositAmount = 10;
            let marketId = 7;
            let predictionOption = 2;
            let userIndex = 5;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 6
        it("Sign for Claim of 10 bPLOT and predict with 10  PLOT and with existing 10 bPLOT balance", async () => {
            let claimAmount = 10;
            let strategyId = 1;
            let plotPredictionAmount = 10;
            let bPlotPredictionAmount = 20;
            let depositAmount = 10;
            let marketId = 7;
            let predictionOption = 1;
            let userIndex = 6;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            await plotusToken.approve(BLOTInstance.address, toWei(10000000));
            await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount-claimAmount));

            await plotusToken.transfer(users[userIndex], toWei(predictionAmount));
            await plotusToken.approve(allMarkets.address, toWei(predictionAmount), {from: users[userIndex]});

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);
            await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            assert.equal(predictionAmount, eventObj.value/1e8);
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            totalClaimedByUser[users[userIndex]] += claimAmount;
            userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 7
        it("Sign for Claim of 10 bPLOT and predict with 10  PLOT, 10 bPLOT, user didn't have bPLOT balance - Should Fail", async () => {
            let claimAmount = 10;
            let strategyId = 1;
            let plotPredictionAmount = 10;
            let bPlotPredictionAmount = 20;
            let depositAmount = 10;
            let marketId = 7;
            let predictionOption = 1;
            let userIndex = 7;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            await plotusToken.approve(BLOTInstance.address, toWei(10000000));
            await BLOTInstance.mint(users[userIndex], toWei(5));

            await plotusToken.transfer(users[userIndex], toWei(predictionAmount));
            await plotusToken.approve(allMarkets.address, toWei(predictionAmount), {from: users[userIndex]});

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 8
        it("Sign for Claim of 0 bPLOT and predict with 20  PLOT - Should Fail", async () => {
            let claimAmount = 0;
            let strategyId = 1;
            let plotPredictionAmount = 20;
            let bPlotPredictionAmount = 0;
            let depositAmount = 20;
            let marketId = 7;
            let predictionOption = 2;
            let userIndex = 8;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            await plotusToken.transfer(users[userIndex], toWei(depositAmount));
            await plotusToken.approve(allMarkets.address, toWei(depositAmount), {from:users[userIndex]});

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 9
        it("Sign for Claim of 0 bPLOT and predict with 20 existing bPLOT balance - Should Fail", async () => {
            let claimAmount = 0;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 7;
            let predictionOption = 2;
            let userIndex = 9;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            await plotusToken.approve(BLOTInstance.address, toWei(10000000));
            await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 10
        it("Sign for Claim of 20 bPLOT for an user, predict with different user - Should Fail", async () => {
            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 7;
            let predictionOption = 1;
            let userIndex = 10;
            let user2Index = 11;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            await plotusToken.approve(BLOTInstance.address, toWei(10000000));
            await BLOTInstance.mint(users[user2Index], toWei(bPlotPredictionAmount));

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[user2Index],
                users[user2Index],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 11
        it("Sign for Claim of 20 bPLOT from UnAuthorized user and predict  - Should Fail", async () => {
            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 7;
            let predictionOption = 1;
            let userIndex = 11;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            await plotusToken.approve(BLOTInstance.address, toWei(10000000));
            await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[1], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 12
        it("Modify the sign of Claim for 20 bPLOT and predict with same  - Should Fail", async () => {
            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 7;
            let predictionOption = 1;
            let userIndex = 12;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            await plotusToken.approve(BLOTInstance.address, toWei(10000000));
            await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount + 10),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 13
        it("Resend the sign for Claim of 20 bPLOT and predict with same - Should Fail", async () => {
            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 7;
            let predictionOption = 1;
            let userIndex = 13;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);
            await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            assert.equal(predictionAmount, eventObj.value/1e8);
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            totalClaimedByUser[users[userIndex]] += claimAmount;
            userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 13
        it("Send the sign for Claim of 20 bPLOT with lower nonce - Should Fail", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 8;
            let predictionOption = 1;
            let userIndex = 13;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]] - 1;

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);
            await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), false);
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 13
        it("Send the sign for Claim of 20 bPLOT with higher nonce - Should Fail", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 9;
            let predictionOption = 1;
            let userIndex = 13;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]] + 1;

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], 0, toWei(claimAmount), 1, 0, claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: _totalClaimedByUser,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);
            await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), false);
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 13
        it("Send the sign for Claim of 80 bPLOT with total claimed > allowed, transfer (allowed-totalClaimed) if it is > 0", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 100;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 80;
            let depositAmount = 0;
            let marketId = 10;
            let predictionOption = 2;
            let userIndex = 13;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);
            
            let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            assert.equal(predictionAmount, eventObj.value/1e8);
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            totalClaimedByUser[users[userIndex]] += claimAmount;
            userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 13
        it("Send the sign for Claim of 20 bPLOT with total claimed > allowed - Should Fail", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 11;
            let predictionOption = 2;
            let userIndex = 13;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            // assert.equal(predictionAmount, eventObj.value/1e8);
            // assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            // totalClaimedByUser[users[userIndex]] += claimAmount;
            // userClaimGlobalNonce[users[userIndex]]++;
            // // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 14
        it("Send the sign for Claim of 20 bPLOT with invalid strategy ID - Should Fail", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 2;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 12;
            let predictionOption = 2;
            let userIndex = 14;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            // assert.equal(predictionAmount, eventObj.value/1e8);
            // assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            // totalClaimedByUser[users[userIndex]] += claimAmount;
            // userClaimGlobalNonce[users[userIndex]]++;
            // // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 14
        it("Send the sign for Claim of 20 bPLOT with proper stratedy id, pass different strategy in transaction - Should Fail", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 13;
            let predictionOption = 2;
            let userIndex = 14;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId+1,
                claimAmount: toWei(claimAmount),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            // assert.equal(predictionAmount, eventObj.value/1e8);
            // assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            // totalClaimedByUser[users[userIndex]] += claimAmount;
            // userClaimGlobalNonce[users[userIndex]]++;
            // // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 14
        it("Send the sign for Claim of 20 bPLOT, pass different bPLOT claim amount in transaction - Should Fail", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 14;
            let predictionOption = 2;
            let userIndex = 14;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount*2),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            // assert.equal(predictionAmount, eventObj.value/1e8);
            // assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            // totalClaimedByUser[users[userIndex]] += claimAmount;
            // userClaimGlobalNonce[users[userIndex]]++;
            // // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 1; Total claimed 20, nonce 1
        it("Send the sign for Claim of 20 bPLOT, pass different totalClaimed amount in transaction - Should Fail", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 15;
            let predictionOption = 2;
            let userIndex = 1;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: 0,
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            // assert.equal(predictionAmount, eventObj.value/1e8);
            // assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            // totalClaimedByUser[users[userIndex]] += claimAmount;
            // userClaimGlobalNonce[users[userIndex]]++;
            // // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 14
        it("Send the sign for Claim of 20 bPLOT, pass different user Address in transaction - Should Fail", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 16;
            let predictionOption = 2;
            let userIndex = 14;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: users[20],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));
            
            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            // assert.equal(predictionAmount, eventObj.value/1e8);
            // assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            // totalClaimedByUser[users[userIndex]] += claimAmount;
            // userClaimGlobalNonce[users[userIndex]]++;
            // // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 14
        it("Sign for Claim of 40 bPLOT and predict with only 20 bPLOT", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 40;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 17;
            let predictionOption = 2;
            let userIndex = 14;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);
            
            let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            assert.equal(predictionAmount, eventObj.value/1e8);
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            totalClaimedByUser[users[userIndex]] += claimAmount;
            userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 14
        it("Sign for claim from auth address, predict with user address, relay the tx with different address", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 18;
            let predictionOption = 2;
            let userIndex = 14;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            // let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);

            functionSignature = await claimAndPredict.contract.methods.claimAndPredict(claimDataJson, json).encodeABI();

                await signAndExecuteMetaTx(
                    pkList[20],
                    users[20],
                    functionSignature,
                    claimAndPredict,
                    "CP"
                    );
                
            
            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            // assert.equal(predictionAmount, eventObj.value/1e8);
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            totalClaimedByUser[users[userIndex]] += claimAmount;
            userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        //User index 15
        it("Sign for Claim of 20 bPLOT and predict with same, pass totalClaimed > value in contract, contract value should be updated", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 19;
            let predictionOption = 2;
            let userIndex = 15;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = (await claimAndPredict.bonusClaimed(users[userIndex]))/1e18 + 30;
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await claimAndPredict.claimAndPredict(claimDataJson, json);

            // functionSignature = await claimAndPredict.contract.methods.claimAndPredict(claimDataJson, json).encodeABI();

            // await signAndExecuteMetaTx(
            //     pkList[20],
            //     users[20],
            //     functionSignature,
            //     claimAndPredict,
            //     "CP"
            //     );
                
            
            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)
            
            // assert.equal(predictionAmount, eventObj.value/1e8);
            assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            totalClaimedByUser[users[userIndex]] += claimAmount;
            userClaimGlobalNonce[users[userIndex]]++;

            assert.equal((await claimAndPredict.bonusClaimed(users[userIndex]))/1e18, totalClaimedByUser[users[userIndex]] + 30)
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        it("Renounce claimAndPredict contract as minter in BLOT", async () => {
            await claimAndPredict.renounceAsMinter();
            assert.equal(await BLOTInstance.isMinter(claimAndPredict.address), false);
        });

        //User index 16
        it("Claim after the contract is removed as minter", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});

            let claimAmount = 20;
            let strategyId = 1;
            let plotPredictionAmount = 0;
            let bPlotPredictionAmount = 20;
            let depositAmount = 0;
            let marketId = 20;
            let predictionOption = 2;
            let userIndex = 16;
            let predictionAmount = plotPredictionAmount + bPlotPredictionAmount;
            totalClaimedByUser[users[userIndex]] = totalClaimedByUser[users[userIndex]] || 0;
            userClaimGlobalNonce[users[userIndex]] = userClaimGlobalNonce[users[userIndex]] || 0;
            // userClaimGlobalNonce[users[userIndex]] ??= 0;

            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
            let _totalClaimedByUser = totalClaimedByUser[users[userIndex]];
            let _userClaimNonce = userClaimGlobalNonce[users[userIndex]];

            // await BLOTInstance.mint(users[userIndex], toWei(bPlotPredictionAmount));
            // await allMarkets.depositAndPredictWithBoth(toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount), {from:users[userIndex]});
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",toWei(depositAmount) , marketId, plotusToken.address, predictionOption, to8Power(plotPredictionAmount), to8Power(bPlotPredictionAmount));
            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
                );

            let json = await constructMetaTxStructJson(allMarkets.address, ...data);
            
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], _userClaimNonce, toWei(claimAmount), 1, toWei(_totalClaimedByUser), claimAndPredict.address);
            let claimDataJson = {
                user: data[0],
                userClaimNonce: _userClaimNonce,
                strategyId: strategyId,
                claimAmount: toWei(claimAmount),
                totalClaimed: toWei(_totalClaimedByUser),
                v: signData.v,
                r: signData.r,
                s: signData.s
            }

            // let eventArgs = (await claimAndPredict._verifyAndClaim(claimDataJson)).logs[0].args;
            // console.log(eventArgs[0]/1e18, eventArgs[1]/1e18);
            let txData = await assertRevert(claimAndPredict.claimAndPredict(claimDataJson, json));

            // let eventObj = await getEventDataFromTx(allMarkets, "PlacePrediction", txData)

            // assert.equal(predictionAmount, eventObj.value/1e8);
            // assert.equal(await allMarkets.getUserFlags(marketId, users[userIndex]), true);
            // totalClaimedByUser[users[userIndex]] += claimAmount;
            // userClaimGlobalNonce[users[userIndex]]++;
            // console.log(totalClaimedByUser[users[userIndex]], userClaimGlobalNonce[users[userIndex]]);
        });

        it("Withdraw any leftover token/native curency in the contract", async () => {
            let balanceLeft = await plotusToken.balanceOf(claimAndPredict.address);

            let balanceBeforeOfUser = await plotusToken.balanceOf(users[1]);

            await claimAndPredict.withdrawToken(plotusToken.address, users[1], balanceLeft);
            
            let balanceAfterOfUser = await plotusToken.balanceOf(users[1]);
            let balanceAfterOfContract = await plotusToken.balanceOf(claimAndPredict.address);
            
            assert.equal(balanceBeforeOfUser/1e18+balanceLeft/1e18, balanceAfterOfUser/1e18);
            assert.equal(balanceAfterOfContract, 0);
        });
    });
});
