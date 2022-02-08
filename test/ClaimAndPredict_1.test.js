const { assert } = require("chai");
const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const AllMarkets = artifacts.require("MockAllMarkets_8");
const CyclicMarkets = artifacts.require("MockCyclicMarkets");
const EthChainlinkOracle = artifacts.require('MockChainLinkAggregator');
const MockUniswapRouter = artifacts.require('MockUniswapRouter');
const SwapAndPredictWithPlot = artifacts.require('SwapAndPredictWithPlot');
const SampleERC = artifacts.require('SampleERC');
const ClaimAndPredict = artifacts.require('ClaimAndPredict_2');

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
describe("ClaimAndPredict", () => {
    async function getSignedClaimMessage(authUserPvtKey, toUser, userClaimNonce, claimAmount, strategyId, totalClaimed, functionSignature, cpContractAddress) {
        let data0 = web3.utils.toHex(toUser);
        // let dataPacked = web3.eth.abi.encodeParameters(["uint64", "uint64", "uint256", "uint64"], [userClaimNonce, to8Power(claimValue), strategy, totalClaimed]);
        let data1  = web3.utils.padLeft(web3.utils.toHex(userClaimNonce), 64/4);
        let data2  = web3.utils.padLeft(web3.utils.toHex(claimAmount), 64/4);
        let data3  = web3.utils.padLeft(web3.utils.toHex(strategyId), 256/4);
        let data4  = web3.utils.padLeft(web3.utils.toHex(totalClaimed), 64/4);
        data_1 = data0 + data1.slice(2) + data2.slice(2) + data3.slice(2) + data4.slice(2) + functionSignature.slice(2) + cpContractAddress.slice(2);
        data_1 = web3.utils.sha3(data_1);
        let signData = await web3.eth.accounts.sign(data_1, authUserPvtKey);
        return signData;
    }
    contract("AllMarket", async function (users) {
        // Multiplier Sheet
        let masterInstance,
            plotusToken,
            allMarkets;
        let userClaimNonce = {};
        let totalClaimed = {};
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
            await plotusToken.transfer(users[11],toWei(1000000));
            await plotusToken.approve(allMarkets.address, toWei(1000000), {from:users[11]});
            await cyclicMarkets.setNextOptionPrice(18);
            await cyclicMarkets.whitelistMarketCreator(users[11]);
            await cyclicMarkets.createMarket(0, 0, 0,{from: users[11]});
            // await marketIncentives.claimCreationReward(100,{from:users[11]});
            BLOTInstance = await BLOT.at(await masterInstance.getLatestAddress(web3.utils.toHex("BL")));

            claimAndPedict = await ClaimAndPredict.new();
            claimAndPedict = await OwnedUpgradeabilityProxy.new(claimAndPedict.address);
            claimAndPedict = await ClaimAndPredict.at(claimAndPedict.address);
            claimAndPedict.initialize(masterInstance.address, users[0], users[1]);
            await assertRevert(claimAndPedict.initialize(masterInstance.address, users[0], users[1]));

            let allMarketsV6Impl = await AllMarkets.new();
            await masterInstance.upgradeMultipleImplementations([toHex("AM")], [allMarketsV6Impl.address]);
            allMarkets = await AllMarkets.at(await masterInstance.getLatestAddress(web3.utils.toHex("AM")));
            await allMarkets.setTrailBonusHandler(claimAndPedict.address);
    
        });
        it("Add claimAndPedict contract as minter in BLOT", async () => {
            await BLOTInstance.addMinter(users[5]);
            await BLOTInstance.addMinter(claimAndPedict.address);

            await plotusToken.approve(BLOTInstance.address, toWei(100000));
            await BLOTInstance.mint(claimAndPedict.address, toWei(100000));
            
            assert.equal(await BLOTInstance.isMinter(users[5]), true);
            assert.equal(await BLOTInstance.isMinter(claimAndPedict.address), true);
        });

        it("Set the max claim limit of strategy", async() => {
            await claimAndPedict.updateMaxClaimPerStrategy([1], [to8Power(60)]);
        });

        it("New user should get bPLOT", async () => {
            let userIndex = 1;            let marketIndex = 7;
            let depositVal = 0;            let plotPrediction  = 0;
            let claimValue = 20;            let option = 1;
            userClaimNonce[users[userIndex]] = 0;            totalClaimed[users[userIndex]] = 0;
            let strategy  = 1;
            predictionToken = plotusToken.address;

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositVal , marketIndex, predictionToken, option, to8Power(plotPrediction), to8Power(claimValue));

            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            let json = {
                targetAddress: allMarkets.address,
                userAddress: data[0],
                functionSignature: data[1],
                sigR: data[2],
                sigS: data[3],
                sigV: data[4]
            }

            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], userClaimNonce[users[userIndex]], to8Power(claimValue), strategy, totalClaimed[users[userIndex]], functionSignature, claimAndPedict.address);

            let claimDataJson = {
                user: data[0],
                userClaimNonce: userClaimNonce[users[userIndex]],
                strategyId: 1,
                claimAmount: to8Power(claimValue),
                totalClaimed: totalClaimed[users[userIndex]],
                v: signData.v,
                r: signData.r,
                s: signData.s
            }
            await claimAndPedict.claimAndPredict(claimDataJson, json);
            userClaimNonce[users[userIndex]]++;
            totalClaimed[users[userIndex]]+=claimValue;
        });

        it("Existing user also should get bPLOT", async () => {
            let userIndex = 2;            let marketIndex = 7;
            let depositVal = 0;            let plotPrediction  = 20;
            let claimValue = 20;            let option = 1;
            userClaimNonce[users[userIndex]] = 0;            totalClaimed[users[userIndex]] = 0;
            let strategy  = 1;
            predictionToken = plotusToken.address;

            await plotusToken.transfer(users[userIndex], toWei(plotPrediction));
            await plotusToken.approve(allMarkets.address, toWei(plotPrediction), { from: users[userIndex]});
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)",toWei(plotPrediction) , marketIndex, predictionToken, to8Power(plotPrediction), option);
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            )

            plotPrediction  = 0;
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositVal , marketIndex, predictionToken, option, to8Power(plotPrediction), to8Power(claimValue));

            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            let json = {
                targetAddress: allMarkets.address,
                userAddress: data[0],
                functionSignature: data[1],
                sigR: data[2],
                sigS: data[3],
                sigV: data[4]
            }

            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], userClaimNonce[users[userIndex]], to8Power(claimValue), strategy, totalClaimed[users[userIndex]], functionSignature, claimAndPedict.address);

            let claimDataJson = {
                user: data[0],
                userClaimNonce: userClaimNonce[users[userIndex]],
                strategyId: 1,
                claimAmount: to8Power(claimValue),
                totalClaimed: totalClaimed[users[userIndex]],
                v: signData.v,
                r: signData.r,
                s: signData.s
            }
            await claimAndPedict.claimAndPredict(claimDataJson, json);
            userClaimNonce[users[userIndex]]++;
            totalClaimed[users[userIndex]]+=claimValue;
        });
        
        it("Should not be able to claim if total claim amount is < 50", async () => {
            let userIndex = 1;            let marketIndex = 7;
            ethChainlinkOracle = await EthChainlinkOracle.deployed();
            let currentPrice = await ethChainlinkOracle.latestAnswer();
            await ethChainlinkOracle.setLatestAnswer(1);
            await increaseTime(8*60*60);
            await cyclicMarkets.settleMarket(marketIndex, 1);
            await ethChainlinkOracle.setLatestAnswer(currentPrice);
            await increaseTime(4*60*60);
            await allMarkets.emitMarketSettledEvent(marketIndex);
            let userBal = await allMarkets.getUserUnusedBalance(users[userIndex]);
            userBal = userBal[0]/1 + userBal[1]/1;
            await assertRevert(allMarkets.withdraw(userBal.toString(), 100, {from:users[userIndex]}));
            assert.isBelow(userBal/1e18, 50);

            userIndex = 2;
            userBal = await allMarkets.getUserUnusedBalance(users[userIndex]);
            userBal = userBal[0]/1 + userBal[1]/1;
            await allMarkets.withdraw(userBal.toString(), 100, {from:users[userIndex]});
        });

        it("Should be able to set auth address to force claim", async() => {
            await allMarkets.setAuthToWithdrawFor(users[0]);
        });

        it("Auth user should be able to withdraw for, even if total claim amount is < 50", async () => {
            let userIndex = 1;            let marketIndex = 7;
            await claimAndPedict.updateUintParameters(toHex("BCFP"),0);
            let userBal = await allMarkets.getUserUnusedBalance(users[userIndex]);
            userBal = userBal[0]/1 + userBal[1]/1;
            assert.isBelow(userBal/1e18, 50);
            let userBalBefore = await plotusToken.balanceOf(users[userIndex]);
            await allMarkets.withdrawFor([users[userIndex]], {from:users[0]});
            let userBalAfter = await plotusToken.balanceOf(users[userIndex]);
            assert.equal(userBalAfter/1e18, userBalBefore/1e18+userBal/1e18 -  totalClaimed[users[userIndex]]);
            userBal = await allMarkets.getUserUnusedBalance(users[userIndex]);
            userBal = userBal[0]/1 + userBal[1]/1;
            assert.equal(userBal/1e18, 0);
            await claimAndPedict.updateUintParameters(toHex("BCFP"),10);
        });
        it("Should issue bPLOT until limt reaches the max claim set per strategy", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 1,{from: users[11]});

            let userIndex = 3;            let marketIndex = 8;
            let depositVal = 0;            let plotPrediction  = 0;
            let claimValue = 60;            let option = 1;
            let strategy  = 1;
            predictionToken = plotusToken.address;
            if(!userClaimNonce[users[userIndex]]) {
                userClaimNonce[users[userIndex]] = 0;
            }
            if(!totalClaimed[users[userIndex]]) {
                totalClaimed[users[userIndex]] = 0;
            }

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositVal , marketIndex, predictionToken, option, to8Power(plotPrediction), to8Power(claimValue));

            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            let json = {
                targetAddress: allMarkets.address,
                userAddress: data[0],
                functionSignature: data[1],
                sigR: data[2],
                sigS: data[3],
                sigV: data[4]
            }
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], userClaimNonce[users[userIndex]], to8Power(claimValue), strategy, totalClaimed[users[userIndex]], functionSignature, claimAndPedict.address);

            let claimDataJson = {
                user: data[0],
                userClaimNonce: userClaimNonce[users[userIndex]],
                strategyId: 1,
                claimAmount: to8Power(claimValue),
                totalClaimed: totalClaimed[users[userIndex]],
                v: signData.v,
                r: signData.r,
                s: signData.s
            }
            await claimAndPedict.claimAndPredict(claimDataJson, json);
            userClaimNonce[users[userIndex]]++;
            totalClaimed[users[userIndex]]+=claimValue;
        });

        it("Should not issue bPLOT more than the max claim set per strategy", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 1,{from: users[11]});

            let userIndex = 1;            let marketIndex = 9;
            let depositVal = 0;            let plotPrediction  = 0;
            let claimValue = 60;            let option = 1;
            let strategy  = 1;
            predictionToken = plotusToken.address;
            if(!userClaimNonce[users[userIndex]]) {
                userClaimNonce[users[userIndex]] = 0;
            }
            if(!totalClaimed[users[userIndex]]) {
                totalClaimed[users[userIndex]] = 0;
            }

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositVal , marketIndex, predictionToken, option, to8Power(plotPrediction), to8Power(claimValue));

            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            let json = {
                targetAddress: allMarkets.address,
                userAddress: data[0],
                functionSignature: data[1],
                sigR: data[2],
                sigS: data[3],
                sigV: data[4]
            }

            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], userClaimNonce[users[userIndex]], to8Power(claimValue), strategy, totalClaimed[users[userIndex]], functionSignature, claimAndPedict.address);

            let claimDataJson = {
                user: data[0],
                userClaimNonce: userClaimNonce[users[userIndex]],
                strategyId: 1,
                claimAmount: to8Power(claimValue),
                totalClaimed: totalClaimed[users[userIndex]],
                v: signData.v,
                r: signData.r,
                s: signData.s
            }
            await assertRevert(claimAndPedict.claimAndPredict(claimDataJson, json));
        });

        it("If claimed = 20, while first claiming deduct 20 + Min(Fee%,Max Fee)", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 2,{from: users[11]});

            let userIndex = 4;            let marketIndex = 10;
            let depositVal = 0;            let plotPrediction  = 0;
            let claimValue = 20;            let option = 1;
            let strategy  = 1;
            predictionToken = plotusToken.address;
            if(!userClaimNonce[users[userIndex]]) {
                userClaimNonce[users[userIndex]] = 0;
            }
            if(!totalClaimed[users[userIndex]]) {
                totalClaimed[users[userIndex]] = 0;
            }

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositVal , marketIndex, predictionToken, option, to8Power(plotPrediction), to8Power(claimValue));

            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            let json = {
                targetAddress: allMarkets.address,
                userAddress: data[0],
                functionSignature: data[1],
                sigR: data[2],
                sigS: data[3],
                sigV: data[4]
            }
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], userClaimNonce[users[userIndex]], to8Power(claimValue), strategy, totalClaimed[users[userIndex]], functionSignature, claimAndPedict.address);

            let claimDataJson = {
                user: data[0],
                userClaimNonce: userClaimNonce[users[userIndex]],
                strategyId: 1,
                claimAmount: to8Power(claimValue),
                totalClaimed: totalClaimed[users[userIndex]],
                v: signData.v,
                r: signData.r,
                s: signData.s
            }
            await claimAndPedict.claimAndPredict(claimDataJson, json);
            userClaimNonce[users[userIndex]]++;
            totalClaimed[users[userIndex]]+=claimValue;

            plotPrediction = 20;
            await plotusToken.transfer(users[userIndex], toWei(plotPrediction*3));
            await plotusToken.approve(allMarkets.address, toWei(plotPrediction*3), { from: users[userIndex]});
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)",toWei(plotPrediction) , marketIndex, predictionToken, to8Power(plotPrediction), option);
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );

            ethChainlinkOracle = await EthChainlinkOracle.deployed();
            let currentPrice = await ethChainlinkOracle.latestAnswer();
            await ethChainlinkOracle.setLatestAnswer(1);
            await increaseTime(8*60*60);
            await cyclicMarkets.settleMarket(marketIndex, 3);
            await ethChainlinkOracle.setLatestAnswer(currentPrice);
            await increaseTime(4*60*60);
            await allMarkets.emitMarketSettledEvent(marketIndex);
            let userBal = await allMarkets.getUserUnusedBalance(users[userIndex]);
            userBal = userBal[0]/1 + userBal[1]/1;

            let claimedAmount = totalClaimed[users[userIndex]]*1e18;
            let bonusClaimFeePerc = (await claimAndPedict.getUintParameters(toHex("BCFP")))[1];
            bonusClaimFeePerc = (userBal*(bonusClaimFeePerc)/100).toFixed(0);
            let maxFee = (await claimAndPedict.getUintParameters(toHex("BCMF")))[1];
            let amountToDeduct = claimedAmount + Math.min(bonusClaimFeePerc, maxFee); 

            let userBalBefore = await plotusToken.balanceOf(users[userIndex]);
            await allMarkets.withdraw(userBal.toString(), 100, {from:users[userIndex]});
            let userBalAfter = await plotusToken.balanceOf(users[userIndex]);
            // assert.isBelow(userBal/1e18, 50);
            try {
                assert.equal(userBalAfter, userBal-amountToDeduct);
                
            } catch (error) {
                console.log(userBal, userBalAfter/1, amountToDeduct);
            }
        });

        it("If claimed > MaxDeduction, while first claim deduct MaxDeduction + Min(Fee%,Max Fee)", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 4,{from: users[11]});

            let userIndex = 5;            let marketIndex = 11;
            let depositVal = 0;            let plotPrediction  = 0;
            let claimValue = 60;            let option = 1;
            let strategy  = 1;
            predictionToken = plotusToken.address;
            if(!userClaimNonce[users[userIndex]]) {
                userClaimNonce[users[userIndex]] = 0;
            }
            if(!totalClaimed[users[userIndex]]) {
                totalClaimed[users[userIndex]] = 0;
            }

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositVal , marketIndex, predictionToken, option, to8Power(plotPrediction), to8Power(claimValue));

            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            let json = {
                targetAddress: allMarkets.address,
                userAddress: data[0],
                functionSignature: data[1],
                sigR: data[2],
                sigS: data[3],
                sigV: data[4]
            }
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], userClaimNonce[users[userIndex]], to8Power(claimValue), strategy, totalClaimed[users[userIndex]], functionSignature, claimAndPedict.address);

            let claimDataJson = {
                user: data[0],
                userClaimNonce: userClaimNonce[users[userIndex]],
                strategyId: 1,
                claimAmount: to8Power(claimValue),
                totalClaimed: totalClaimed[users[userIndex]],
                v: signData.v,
                r: signData.r,
                s: signData.s
            }
            await claimAndPedict.claimAndPredict(claimDataJson, json);
            userClaimNonce[users[userIndex]]++;
            totalClaimed[users[userIndex]]+=claimValue;

            plotPrediction = 20;
            await plotusToken.transfer(users[userIndex], toWei(plotPrediction*3));
            await plotusToken.approve(allMarkets.address, toWei(plotPrediction*3), { from: users[userIndex]});
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)",toWei(plotPrediction) , marketIndex, predictionToken, to8Power(plotPrediction), option);
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );

            ethChainlinkOracle = await EthChainlinkOracle.deployed();
            let currentPrice = await ethChainlinkOracle.latestAnswer();
            await ethChainlinkOracle.setLatestAnswer(1);
            await increaseTime(8*60*60);
            await cyclicMarkets.settleMarket(marketIndex, 5);
            await ethChainlinkOracle.setLatestAnswer(currentPrice);
            await increaseTime(4*60*60);
            await allMarkets.emitMarketSettledEvent(marketIndex);
            let userBal = await allMarkets.getUserUnusedBalance(users[userIndex]);
            userBal = userBal[0]/1 + userBal[1]/1;

            let claimedAmount = totalClaimed[users[userIndex]]*1e18;
            let bonusClaimFeePerc = (await claimAndPedict.getUintParameters(toHex("BCFP")))[1];
            bonusClaimFeePerc = (userBal*(bonusClaimFeePerc)/100).toFixed(0);
            let maxFee = (await claimAndPedict.getUintParameters(toHex("BCMF")))[1];
            let maxClaimReturn = (await claimAndPedict.getUintParameters(toHex("BMCA")))[1];
            let amountToDeduct = Math.min(claimedAmount, maxClaimReturn*1e10) + Math.min(bonusClaimFeePerc, maxFee); 

            let userBalBefore = await plotusToken.balanceOf(users[userIndex]);
            await allMarkets.withdraw(userBal.toString(), 100, {from:users[userIndex]});
            let userBalAfter = await plotusToken.balanceOf(users[userIndex]);
            // assert.isBelow(userBal/1e18, 50);
            try {
                assert.equal(userBalAfter, userBal-amountToDeduct);
                
            } catch (error) {
                console.log(userBal, userBalAfter/1, amountToDeduct);
            }
        });

        it("Lost first claim prediction, won 2 normal pred, while claim deduct 20+Fee", async () => {
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 6,{from: users[11]});

            let userIndex = 6;            let marketIndex = 12;
            let depositVal = 0;            let plotPrediction  = 0;
            let claimValue = 20;            let option = 3;
            let strategy  = 1;
            predictionToken = plotusToken.address;
            if(!userClaimNonce[users[userIndex]]) {
                userClaimNonce[users[userIndex]] = 0;
            }
            if(!totalClaimed[users[userIndex]]) {
                totalClaimed[users[userIndex]] = 0;
            }

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositVal , marketIndex, predictionToken, option, to8Power(plotPrediction), to8Power(claimValue));

            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            let json = {
                targetAddress: allMarkets.address,
                userAddress: data[0],
                functionSignature: data[1],
                sigR: data[2],
                sigS: data[3],
                sigV: data[4]
            }
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], userClaimNonce[users[userIndex]], to8Power(claimValue), strategy, totalClaimed[users[userIndex]], functionSignature, claimAndPedict.address);

            let claimDataJson = {
                user: data[0],
                userClaimNonce: userClaimNonce[users[userIndex]],
                strategyId: 1,
                claimAmount: to8Power(claimValue),
                totalClaimed: totalClaimed[users[userIndex]],
                v: signData.v,
                r: signData.r,
                s: signData.s
            }
            await claimAndPedict.claimAndPredict(claimDataJson, json);
            userClaimNonce[users[userIndex]]++;
            totalClaimed[users[userIndex]]+=claimValue;

            plotPrediction = 20;
            option = 1;
            await plotusToken.transfer(users[userIndex], toWei(plotPrediction*2));
            await plotusToken.approve(allMarkets.address, toWei(plotPrediction*2), { from: users[userIndex]});
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)",toWei(plotPrediction) , marketIndex, predictionToken, to8Power(plotPrediction), option);
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );

            ethChainlinkOracle = await EthChainlinkOracle.deployed();
            let currentPrice = await ethChainlinkOracle.latestAnswer();
            await ethChainlinkOracle.setLatestAnswer(1);
            await increaseTime(8*60*60);
            await cyclicMarkets.settleMarket(marketIndex, 7);
            await ethChainlinkOracle.setLatestAnswer(currentPrice);
            await increaseTime(4*60*60);
            await allMarkets.emitMarketSettledEvent(marketIndex);
            let userBal = await allMarkets.getUserUnusedBalance(users[userIndex]);
            userBal = userBal[0]/1 + userBal[1]/1;

            let claimedAmount = totalClaimed[users[userIndex]]*1e18;
            let bonusClaimFeePerc = (await claimAndPedict.getUintParameters(toHex("BCFP")))[1];
            bonusClaimFeePerc = (userBal*(bonusClaimFeePerc)/100).toFixed(0);
            bonusClaimFeePerc = Math.trunc(bonusClaimFeePerc/1e8)*1e8;
            let maxFee = (await claimAndPedict.getUintParameters(toHex("BCMF")))[1];
            let maxClaimReturn = (await claimAndPedict.getUintParameters(toHex("BMCA")))[1];
            let amountToDeduct = Math.min(claimedAmount, maxClaimReturn*1e10) + Math.min(bonusClaimFeePerc, maxFee/1); 
            let userBalBefore = await plotusToken.balanceOf(users[userIndex]);
            await allMarkets.withdraw(userBal.toString(), 100, {from:users[userIndex]});
            let userBalAfter = await plotusToken.balanceOf(users[userIndex]);
            // assert.isBelow(userBal/1e18, 50);
            try {
                assert.equal(Math.trunc(userBalAfter/1e10), Math.trunc(userBal/1e10-amountToDeduct/1e10));
                
            } catch (error) {
                console.log(error);
                console.log(userBal, userBalAfter/1, amountToDeduct);
            }
        });

        it("Above case cont: claim 20 more bonus, at withdraw deduct only 20 without fee", async () => {
            
            await increaseTime(4*60*60);
            await cyclicMarkets.createMarket(0, 0, 8,{from: users[11]});

            let userIndex = 6;            let marketIndex = 13;
            let depositVal = 0;            let plotPrediction  = 0;
            let claimValue = 20;            let option = 1;
            let strategy  = 1;
            predictionToken = plotusToken.address;
            if(!userClaimNonce[users[userIndex]]) {
                userClaimNonce[users[userIndex]] = 0;
            }
            if(!totalClaimed[users[userIndex]]) {
                totalClaimed[users[userIndex]] = 0;
            }

            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositVal , marketIndex, predictionToken, option, to8Power(plotPrediction), to8Power(claimValue));

            let data = await signAndGetMetaTxData(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );
            let json = {
                targetAddress: allMarkets.address,
                userAddress: data[0],
                functionSignature: data[1],
                sigR: data[2],
                sigS: data[3],
                sigV: data[4]
            }
            let signData = await getSignedClaimMessage(pkList[0], users[userIndex], userClaimNonce[users[userIndex]], to8Power(claimValue), strategy, totalClaimed[users[userIndex]], functionSignature, claimAndPedict.address);

            let claimDataJson = {
                user: data[0],
                userClaimNonce: userClaimNonce[users[userIndex]],
                strategyId: 1,
                claimAmount: to8Power(claimValue),
                totalClaimed: totalClaimed[users[userIndex]],
                v: signData.v,
                r: signData.r,
                s: signData.s
            }
            await claimAndPedict.claimAndPredict(claimDataJson, json);
            userClaimNonce[users[userIndex]]++;
            totalClaimed[users[userIndex]]+=claimValue;

            plotPrediction = 40;
            option = 1;
            await plotusToken.transfer(users[0], await plotusToken.balanceOf(users[userIndex]), {from: users[userIndex]});
            await plotusToken.transfer(users[userIndex], toWei(plotPrediction));
            await plotusToken.approve(allMarkets.address, toWei(plotPrediction), { from: users[userIndex]});
            functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)",toWei(plotPrediction) , marketIndex, predictionToken, to8Power(plotPrediction), option);
            await signAndExecuteMetaTx(
                pkList[userIndex],
                users[userIndex],
                functionSignature,
                allMarkets,
                "AM"
            );

            ethChainlinkOracle = await EthChainlinkOracle.deployed();
            let currentPrice = await ethChainlinkOracle.latestAnswer();
            await ethChainlinkOracle.setLatestAnswer(1);
            await increaseTime(8*60*60);
            await cyclicMarkets.settleMarket(marketIndex, 9);
            await ethChainlinkOracle.setLatestAnswer(currentPrice);
            await increaseTime(4*60*60);
            await allMarkets.emitMarketSettledEvent(marketIndex);
            let userBal = await allMarkets.getUserUnusedBalance(users[userIndex]);
            userBal = userBal[0]/1 + userBal[1]/1;

            let claimedAmount = claimValue*1e18;
            let bonusClaimFeePerc = (await claimAndPedict.getUintParameters(toHex("BCFP")))[1];
            bonusClaimFeePerc = (userBal*(bonusClaimFeePerc)/100).toFixed(0);
            bonusClaimFeePerc = Math.trunc(bonusClaimFeePerc/1e8)*1e8;
            let maxClaimReturn = (await claimAndPedict.getUintParameters(toHex("BMCA")))[1];
            let amountToDeduct = Math.min(claimedAmount, maxClaimReturn*1e10);
            // await allMarkets.withdraw(userBal.toString(), 100, {from:users[userIndex]});
            await allMarkets.withdrawFor([users[userIndex]]);
            let userBalAfter = await plotusToken.balanceOf(users[userIndex]);
            try {
                assert.equal(Math.trunc(userBalAfter/1e10), Math.trunc(userBal/1e10-amountToDeduct/1e10));
                
            } catch (error) {
                console.log(error);
                console.log(userBal, userBalAfter/1, amountToDeduct);
            }
        });

    });
});
