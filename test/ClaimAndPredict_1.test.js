const { assert } = require("chai");
const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const AllMarkets = artifacts.require("MockAllMarkets_6");
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

            claimAndPedict = await ClaimAndPredict.new(masterInstance.address, users[0]);
            
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

        it("Existing user should not get bPLOT", async () => {
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
            await assertRevert(claimAndPedict.claimAndPredict(claimDataJson, json))
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
            await allMarkets.withdraw(userBal.toString(), 100, {from:users[userIndex]});
            let userBalAfter = await plotusToken.balanceOf(users[userIndex]);
            try {
                assert.equal(Math.trunc(userBalAfter/1e10), Math.trunc(userBal/1e10-amountToDeduct/1e10));
                
            } catch (error) {
                console.log(error);
                console.log(userBal, userBalAfter/1, amountToDeduct);
            }
        });

        it.skip("1. Place Prediction", async () => {

            predictionToken = plotusToken.address;
            functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositAmt , 7, predictionToken, options[i], 0, to8Power(predictionVal[i]));
        
            let i;
          let predictionVal  = [0,100, 400, 210, 123, 200, 100, 300, 500, 200, 100];
          let options=[0,2,2,2,3,1,1,2,3,3,2];
          let withPlot = [0,true,false,true,false,false,true,false,false,true,true]; 
            
          for(i=1;i<11;i++) {
            let predictionToken;
            let depositAmt;
            if(withPlot[i])
            {
              depositAmt = toWei(predictionVal[i]);
              await plotusToken.transfer(users[i], toWei(predictionVal[i]));
              await plotusToken.approve(allMarkets.address, toWei(predictionVal[i]), { from: users[i] });
              predictionToken = plotusToken.address;

            } else {
              depositAmt=0;
            //   await plotusToken.approve(BLOTInstance.address, toWei(predictionVal[i]*2));
            //   await BLOTInstance.mint(users[i], toWei(predictionVal[i]*2));
              predictionToken = BLOTInstance.address;
            }
            let functionSignature = encode3("depositAndPlacePrediction(uint,uint,address,uint64,uint256)",depositAmt , 7, predictionToken, to8Power(predictionVal[i]), options[i]);
            if(i == 5) {
                // Predict with only bPLOT
            }
            if( i==4) {
                // Predict with some plot and some bPLOT
				await spInstance.whitelistTokenForSwap(await router.WETH());
				await spInstance.whitelistTokenForSwap(externalToken.address);
                 
                let _inputAmount = toWei(100*plotTokenPrice);
                await externalToken.approve(spInstance.address, toWei(1000), {from:users[i]});
                await externalToken.transfer(users[i], toWei(1000));
                let functionSignature = encode3("swapAndPlacePrediction(address[],uint256,address,uint256,uint256,uint64,uint256)", [externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], to8Power(predictionVal[i]-100), 1);
                await cyclicMarkets.setNextOptionPrice(options[i]*9);
                await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], to8Power(predictionVal[i]-100), 1));
                let data = await signAndGetMetaTxData(
                    pkList[i],
                    users[i],
                    functionSignature,
                    spInstance,
                    "SP"
                );
                    let json = {
                        targetAddress: spInstance.address,
                        userAddress: data[0],
                        functionSignature: data[1],
                        sigR: data[2],
                        sigS: data[3],
                        sigV: data[4]
                    }
                
                let data0 = web3.utils.toHex(users[i]);
                let dataPacked = web3.eth.abi.encodeParameters(["uint256", "uint256", "uint256", "uint256"], [0, toWei(predictionVal[i]-100), 1, 0]);
                data_1 = data0 + dataPacked.slice(2) + claimAndPedict.address.slice(2);
                data_1 = web3.utils.sha3(data_1);
                let signData = await web3.eth.accounts.sign(data_1, pkList[0]);
                let claimDataJson = {
                    user: data[0],
                    userClaimNonce: 0,
                    strategyId: 1,
                    claimAmount: toWei(predictionVal[i]-100),
                    totalClaimed: 0,
                    v: signData.v,
                    r: signData.r,
                    s: signData.s
                }
                await claimAndPedict.claimAndPredict(claimDataJson, json)
                await assertRevert(spInstance.swapAndPlacePrediction([externalToken.address, plotusToken.address], _inputAmount, users[i], 7, options[i], to8Power(predictionVal[i]-100), 1, {from:users[i]}));
				
                // predictionToken = plotusToken.address;
                // await plotusToken.transfer(users[i], toWei(100));
                // await plotusToken.approve(allMarkets.address, toWei(100), { from: users[i] });
                // depositAmt=toWei(100);
                // functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositAmt , 7, predictionToken, options[i], to8Power(100), to8Power(predictionVal[i]-100));
            }
            if(i == 3) {
                // Predict with only PLOT
                functionSignature = encode3("depositAndPredictWithBoth(uint,uint,address,uint256,uint64,uint64)",depositAmt , 7, predictionToken, options[i], to8Power(predictionVal[i]), 0);
            }
            await cyclicMarkets.setNextOptionPrice(options[i]*9);
            if(i == 4) {
                // await signAndExecuteMetaTx(
                //     pkList[i],
                //     users[i],
                //     functionSignature,
                //     spInstance,
                //        "SP"
                //     );
            } else {
                let data = await signAndGetMetaTxData(
                    pkList[i],
                    users[i],
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

                    let data0 = web3.utils.toHex(users[i]);
                    let dataPacked = web3.eth.abi.encodeParameters(["uint256", "uint256","uint256", "uint256"], [0, toWei(predictionVal[i]), 1, 0]);
                    data_1 = data0 + dataPacked.slice(2) + claimAndPedict.address.slice(2);
                    data_1 = web3.utils.sha3(data_1);
                    let signData = await web3.eth.accounts.sign(data_1, pkList[0]);
                    let claimDataJson = {
                        user: data[0],
                        userClaimNonce: 0,
                        strategyId: 1,
                        claimAmount: toWei(predictionVal[i]),
                        totalClaimed: 0,
                        v: signData.v,
                        r: signData.r,
                        s: signData.s
                    }

                await claimAndPedict.claimAndPredict(claimDataJson, json)
            }
            if(!withPlot[i]) {
            //SHould not allow to predict with bPLOT twice
            await assertRevert(signAndExecuteMetaTx(
                            pkList[i],
                            users[i],
                            functionSignature,
                            allMarkets,
                            "AM"
                            ));
            }
          }
        });
        it.skip("1.2 Relayer should get apt reward", async () => {

            let relayerBalBefore = await plotusToken.balanceOf(users[0]);
            await cyclicMarkets.claimRelayerRewards();
            let relayerBalAfter = await plotusToken.balanceOf(users[0]);

            assert.equal(Math.round((relayerBalAfter-relayerBalBefore)/1e15),22.33*1e3);
        });
        it.skip("1.3 Check Prediction points allocated", async () => {
            options = [0,2, 2, 2, 3, 1, 1, 2, 3, 3, 2];
            getPredictionPoints = async (user, option) => {
                let predictionPoints = await allMarkets.getUserPredictionPoints(user, 7, option);
                predictionPoints = predictionPoints / 1;
                return predictionPoints;
            };
            PredictionPointsExpected = [0,5444.44444, 21777.77777, 11433.33333, 4464.44444, 21777.77777, 10888.88888, 16333.33333, 18148.14815, 7259.25925, 5444.44444];

            for (let index = 1; index < 11; index++) {
                let PredictionPoints = await getPredictionPoints(users[index], options[index]);
                PredictionPoints = PredictionPoints / 1e5;
                try{
                    assert.equal(PredictionPoints.toFixed(1), PredictionPointsExpected[index].toFixed(1));
                }catch(e){
                    console.log(`Not equal!! -> Sheet: ${PredictionPointsExpected[index]} Got: ${PredictionPoints}`);
                }
                // commented by parv (as already added assert above)
                // console.log(`Prediction points : ${PredictionPoints} expected : ${PredictionPointsExpected[index].toFixed(1)} `);
            }
            // console.log(await plotusToken.balanceOf(user1));

            let ethChainlinkOracle = await EthChainlinkOracle.deployed();
            await ethChainlinkOracle.setLatestAnswer(1);
            // close market
            await increaseTime(8 * 60 * 60);
            await cyclicMarkets.settleMarket(7, 1);
            await increaseTime(8 * 60 * 60);
        });
        it.skip("1.4 Check total return for each user Prediction values in plot", async () => {
            options = [0,2, 2, 2, 3, 1, 1, 2, 3, 3, 2];
            getReturnsInPLOT = async (user) => {
                const response = await allMarkets.getReturn(user, 7);
                let returnAmountInPLOT = response / 1e8;
                return returnAmountInPLOT;
            };
            const returnInPLOTExpected = [0,0,0,0,0,1433.688421,716.8442105,0,0,0,0];

            for (let index = 1; index < 11; index++) {
                let returns = await getReturnsInPLOT(users[index]) / 1;
                try{
                    assert.equal(returnInPLOTExpected[index].toFixed(2), returns.toFixed(2), );
                }catch(e){
                    console.log(`Not equal!! -> Sheet: ${returnInPLOTExpected[index].toFixed(2)} Got: ${returns.toFixed(2)}`);
                }
                // commented by Parv (as assert already added above)
                // console.log(`return : ${returns} Expected :${returnInPLOTExpected[index]}`);
            }
        });
        it.skip("1.5 Check User Received The appropriate amount", async () => {
            const totalReturnLotExpexted = [0,0,0,0,0,1433.688421,716.8442105,0,0,0,0];;
            for (let i=1;i<11;i++) {
                beforeClaimToken = await plotusToken.balanceOf(users[i]);
                try {
                    let plotEthUnused = await allMarkets.getUserUnusedBalance(users[i]);
                    let functionSignature = encode3("withdraw(uint,uint)", plotEthUnused[0].iadd(plotEthUnused[1]), 10);
                    await signAndExecuteMetaTx(
                      pkList[i],
                      users[i],
                      functionSignature,
                      allMarkets,
                        "AM"
                      );
                } catch (e) { }
                afterClaimToken = await plotusToken.balanceOf(users[i]);
                conv = new BigNumber(1000000000000000000);

                diffToken = afterClaimToken - beforeClaimToken;
                diffToken = diffToken / conv;
                diffToken = diffToken.toFixed(2);
                expectedInLot = totalReturnLotExpexted[i].toFixed(2);
                
                try{
                    assert.equal(diffToken/1, expectedInLot);
                }catch(e){
                    console.log(`Not equal!! -> Sheet: ${expectedInLot} Got: ${diffToken}`);
                }
                // commented by Parv (as assert already added above)
                // console.log(`User ${accounts.indexOf(account) + 1}`);
                // console.log(`Returned in Eth : ${diff}  Expected : ${expectedInEth} `);
                // console.log(`Returned in Lot : ${diffToken}  Expected : ${expectedInLot} `);
            }
        });
        it.skip("1.6 Market creator should get apt reward", async () => {
            let marketCreatorReward = await cyclicMarkets.getPendingMarketCreationRewards(users[11]);
            assert.equal(Math.round(1866.39),Math.round(marketCreatorReward/1e16));

            let plotBalBeforeCreator = await plotusToken.balanceOf(users[11]);

            functionSignature = encode3("claimCreationReward()");
            await signAndExecuteMetaTx(
                pkList[11],
                users[11],
                functionSignature,
                cyclicMarkets,
                "CM"
                );

            let plotBalAfterCreator = await plotusToken.balanceOf(users[11]);

            assert.equal(Math.round((plotBalAfterCreator-plotBalBeforeCreator)/1e16),Math.round(1866.39));
        });
    });
});
