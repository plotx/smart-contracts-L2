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
let pkList = ["fb437e3e01939d9d4fef43138249f23dc1d0852e69b0b5d1647c087f869fabbd","7c85a1f1da3120c941b83d71a154199ee763307683f206b98ad92c3b4e0af13e","ecc9b35bf13bd5459350da564646d05c5664a7476fe5acdf1305440f88ed784c","f4470c3fca4dbef1b2488d016fae25978effc586a1f83cb29ac8cb6ab5bc2d50","141319b1a84827e1046e93741bf8a9a15a916d49684ab04925ac4ce4573eea23","d54b606094287758dcf19064a8d91c727346aadaa9388732e73c4315b7c606f9","49030e42ce4152e715a7ddaa10e592f8e61d00f70ef11f48546711f159d985df","b96761b1e7ebd1e8464a78a98fe52f53ce6035c32b4b2b12307a629a551ff7cf","d4786e2581571c863c7d12231c3afb6d4cef390c0ac9a24b243293721d28ea95","ed28e3d3530544f1cf2b43d1956b7bd13b63c612d963a8fb37387aa1a5e11460","05b127365cf115d4978a7997ee98f9b48f0ddc552b981c18aa2ee1b3e6df42c6","9d11dd6843f298b01b34bd7f7e4b1037489871531d14b58199b7cba1ac0841e6"];
describe("newPlotusWithBlot", () => {
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

        it("Set the max claim limit of strategy", async() => {
            await claimAndPredict.updateMaxClaimPerStrategy([1], [toWei(1000)]);
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
        it("Sign for Claim of 20 bPLOT and predict with 10 more PLOT, User didn't have PLOT balance", async () => {
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

        it("Renounce claimAndPredict contract as minter in BLOT", async () => {
            await claimAndPredict.renounceAsMinter();
            assert.equal(await BLOTInstance.isMinter(claimAndPredict.address), false);
        });
    });
});
