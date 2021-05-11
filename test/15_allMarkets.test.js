const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const AllMarkets = artifacts.require("MockAllMarkets");
const CyclicMarkets = artifacts.require("MockCyclicMarkets");
const PlotusToken = artifacts.require("MockPLOT");
const MockchainLink = artifacts.require("MockChainLinkAggregator");
const EThOracle = artifacts.require("EthChainlinkOracle");
const assertRevert = require("./utils/assertRevert.js").assertRevert;
const increaseTime = require("./utils/increaseTime.js").increaseTime;
const latestTime = require("./utils/latestTime.js").latestTime;
const encode = require("./utils/encoder.js").encode;
const encode1 = require("./utils/encoder.js").encode1;
const { toHex, toWei } = require("./utils/ethTools.js");
const expectEvent = require("./utils/expectEvent");
const gvProp = require("./utils/gvProposal.js").gvProposal;
// const Web3 = require("web3");
const { assert } = require("chai");
// const gvProposalWithIncentive = require("./utils/gvProposal.js").gvProposalWithIncentive;
const gvProposal = require("./utils/gvProposal.js").gvProposalWithIncentiveViaTokenHolder;
// const web3 = new Web3();

let gv;
let cr;
let pc;
let master;
let proposalId;
let pId;
let mr;
let plotusToken;
let tc;
let td;
let pl;
let mockchainLinkInstance;
let allMarkets, marketIncentives, tokenController;
let nullAddress = "0x0000000000000000000000000000000000000000";

contract("PlotX", ([ab1, ab2, ab3, ab4, mem1, mem2, mem3, mem4, mem5, mem6, mem7, mem8, mem9, mem10, notMember, dr1, dr2, dr3, user11, user12, user13, user14]) => {
	before(async function() {
		master = await OwnedUpgradeabilityProxy.deployed();
		master = await Master.at(master.address);
		plotusToken = await PlotusToken.deployed();
		mockchainLinkInstance = await EThOracle.deployed();
		
		let date = await latestTime();
        await increaseTime(3610);
        date = Math.round(date);
        // await marketConfig.setInitialCummulativePrice();
		allMarkets = await AllMarkets.at(await master.getLatestAddress(toHex("AM")));
		cyclicMarkets = await CyclicMarkets.at(await master.getLatestAddress(toHex("CM")));
		// await assertRevert(marketIncentives.setMasterAddress());
        // await assertRevert(marketIncentives.initialise(marketConfig.address, mockchainLinkInstance.address));
        await increaseTime(5 * 3600);
        await plotusToken.transfer(master.address,toWei(100000));
        await plotusToken.transfer(user11,toWei(100000));
        await plotusToken.transfer(user12,toWei(100000));
		await plotusToken.transfer(user14,toWei(100000));
        // await plotusToken.approve(tokenController.address,toWei(200000),{from:user11});
        // await tokenController.lock(toHex("SM"),toWei(100000),30*3600*24,{from:user11});

		await plotusToken.transfer(mem1, toWei(100));
		await plotusToken.transfer(mem2, toWei(100));
		await plotusToken.transfer(mem3, toWei(100));
		await plotusToken.transfer(mem4, toWei(100));
		await plotusToken.transfer(mem5, toWei(100));
		await assertRevert(cyclicMarkets.setMasterAddress(mem1, mem1));
	});

	it("Should not be able to create initial markets invalid params", async function() {
		await assertRevert(cyclicMarkets.addInitialMarketTypesAndStart(await latestTime(), nullAddress, mem1));
		await assertRevert(cyclicMarkets.addInitialMarketTypesAndStart(await latestTime(), mem1, nullAddress));
	})

	it("Should not be able to create initial markets twice", async function() {
		await assertRevert(cyclicMarkets.addInitialMarketTypesAndStart(await latestTime(), mem1, mem1));
	});

	it("Should not create market directly in allMarkets", async function() {
		await assertRevert(allMarkets.createMarket([1,2],[1,2],mem1, 100));
	})

	it("Total options should be 3 for markets created by cyclic markets contract", async function() {
		assert.equal((await allMarkets.getTotalOptions(1))/1, 3);
	});

	it("Should not add new market curreny if already exists", async function() {
		await increaseTime(604810);
		let startTime = (await latestTime()) / 1 + 604800;
		await assertRevert(cyclicMarkets.addMarketCurrency(toHex("ETH/USD"), mockchainLinkInstance.address, 8, 1, startTime));
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 15, 0);
		// let actionHash = encode("addMarketCurrency(bytes32,address,uint8,uint8,uint32)", toHex("ETH/USD"), mockchainLinkInstance.address, 8, 1, startTime);
		// await gv.submitProposalWithSolution(pId, "addNewMarketCurrency", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await assertRevert(gv.submitVote(pId, 1, { from: mem2 })); //closed to vote
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not add new market curreny if decimals passed is zero", async function() {
		await increaseTime(604810);
		let startTime = (await latestTime()) / 1 + 604800;
		await assertRevert(cyclicMarkets.addMarketCurrency(toHex("ETH/PLOT"), mockchainLinkInstance.address, 0, 1, startTime));
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 15, 0);
		// let actionHash = encode("addMarketCurrency(bytes32,address,uint8,uint8,uint32)", toHex("ETH/PLOT"), mockchainLinkInstance.address, 0, 1, startTime);
		// await gv.submitProposalWithSolution(pId, "addNewMarketCurrency", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await assertRevert(gv.submitVote(pId, 1, { from: mem2 })); //closed to vote
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not add new market curreny if round off argument passed is zero", async function() {
		await increaseTime(604810);
		let startTime = (await latestTime()) / 1 + 604800;
		await assertRevert(cyclicMarkets.addMarketCurrency(toHex("ETH/PLOT"), mockchainLinkInstance.address, 8, 0, startTime));
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 15, 0);
		// let actionHash = encode("addMarketCurrency(bytes32,address,uint8,uint8,uint32)", toHex("ETH/PLOT"), mockchainLinkInstance.address, 8, 0, startTime);
		// await gv.submitProposalWithSolution(pId, "addNewMarketCurrency", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await assertRevert(gv.submitVote(pId, 1, { from: mem2 })); //closed to vote
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should create a proposal to add new market curreny", async function() {
		await increaseTime(604810);
		let startTime = (await latestTime()) / 1 + 604800;
		await cyclicMarkets.addMarketCurrency(toHex("ETH/PLOT"), mockchainLinkInstance.address, 8, 1, startTime);
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 15, 0);
		// let actionHash = encode("addMarketCurrency(bytes32,address,uint8,uint8,uint32)", toHex("ETH/PLOT"), mockchainLinkInstance.address, 8, 1, startTime);
		// await gv.submitProposalWithSolution(pId, "addNewMarketCurrency", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await assertRevert(gv.submitVote(pId, 1, { from: mem2 })); //closed to vote
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
		// await plotusToken.approve(allMarkets.address, toWei(1000000), {from:user14});
		await increaseTime(604810);
		await plotusToken.approve(allMarkets.address, toWei(1000),{from:user14});
		await cyclicMarkets.whitelistMarketCreator(user14);
		await cyclicMarkets.createMarket(2,0,0,{from:user14});
	});

	it("Predict on newly created market", async function() {
		await cyclicMarkets.setNextOptionPrice(18);

		// set price
		// user 1
		// set price lot
		await cyclicMarkets.setNextOptionPrice(9);
		await plotusToken.approve(allMarkets.address, "18000000000000000000000000");
		await plotusToken.approve(allMarkets.address, "18000000000000000000000000", {from:mem1});
		await plotusToken.approve(allMarkets.address, "18000000000000000000000000");
		await assertRevert(allMarkets.depositAndPlacePrediction("100000000000000000000", 7, plotusToken.address, 100*1e8, 5));
		await assertRevert(allMarkets.depositAndPlacePrediction("100000000000000000000", 7, allMarkets.address, 100*1e8, 1));
		await assertRevert(allMarkets.depositAndPlacePrediction("10000000", 7, plotusToken.address, 100*1e8, 1));
		await assertRevert(allMarkets.depositAndPlacePrediction("100000000000000000000", 7, plotusToken.address, 100, 1));
		await allMarkets.depositAndPlacePrediction("100000000000000000000", 7, plotusToken.address, 100*1e8, 1);
		// await allMarkets.placePrediction(plotusToken.address, "1000000000000000000000", 1, 1);
		let totalStaked = await allMarkets.getUserFlags(7, ab1);
		assert.equal(totalStaked, false);
    	await allMarkets.depositAndPlacePrediction("8000000000000000000000", 7, plotusToken.address, 8000*1e8, 2);
    	await allMarkets.depositAndPlacePrediction("8000000000000000000000", 7, plotusToken.address, 8000*1e8, 3);
		// await assertRevert(marketInstance.placePrediction("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", "10000000000000000000", 1, 1, { value: 1000 }));
		// await assertRevert(allMarkets.settleMarket(7));
		await assertRevert(allMarkets.postResultMock(0,7));
		await increaseTime(604810);
		// await allMarkets.withdrawMax(100);
		// await marketInstance.claimReturn(ab1);
		await allMarkets.postResultMock(1, 7);
		// await assertRevert(marketInstance.placePrediction(plotusToken.address, "10000000000000000000", 1, 1));
		await increaseTime(604800);
		let balance = await allMarkets.getUserUnusedBalance(ab1);
		await allMarkets.withdraw((balance[1]), 100);
		// await marketInstance.claimReturn(ab1);
		await increaseTime(604800);
	});

	it("Should not add new market type if prediction type already exists", async function() {
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 2 * 604800;
		await assertRevert(cyclicMarkets.addMarketType(24 * 60 * 60, 50, startTime, 3600, 100, 100));
		await increaseTime(604810);
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 14, 0);
		// let actionHash = encode("addMarketType(uint32,uint32,uint32,uint32,uint32)", 24 * 60 * 60, 50, startTime, 3600, 100);
		// await gv.submitProposalWithSolution(pId, "update max followers limit", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not add new market type if prediction is zero", async function() {
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 2 * 604800;
		await assertRevert(cyclicMarkets.addMarketType(0, 50, startTime, 3600, 100, 100));
		await increaseTime(604810);
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 14, 0);
		// let actionHash = encode("addMarketType(uint32,uint32,uint32,uint32,uint32)", 0, 50, startTime, 3600, 100);
		// await gv.submitProposalWithSolution(pId, "update max followers limit", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not add new market type if option range percent is zero", async function() {
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 2 * 604800;
		await assertRevert(cyclicMarkets.addMarketType(6 * 60 * 60, 0, startTime, 3600, 100, 100));
		await increaseTime(604810);
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 14, 0);
		// let startTime = Math.round(Date.now());
		// startTime = (await latestTime()) / 1 + 3 * 604800;
		// let actionHash = encode("addMarketType(uint32,uint32,uint32,uint32,uint32)", 6 * 60 * 60, 0, startTime, 3600, 100);
		// await gv.submitProposalWithSolution(pId, "update max followers limit", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not add new market type if cooldown time is zero", async function() {
		await increaseTime(604810);
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 2 * 604800;
		await assertRevert(cyclicMarkets.addMarketType(6 * 60 * 60, 50, startTime, 0, 100, 100));
		await increaseTime(604810);

		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 14, 0);
		// let startTime = Math.round(Date.now());
		// startTime = (await latestTime()) / 1 + 3 * 604800;
		// let actionHash = encode("addMarketType(uint32,uint32,uint32,uint32,uint32)", 6 * 60 * 60, 50, startTime, 0, 100);
		// await gv.submitProposalWithSolution(pId, "update max followers limit", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not add new market type if min time passed is zero", async function() {
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 2 * 604800;
		await assertRevert(cyclicMarkets.addMarketType(6 * 60 * 60, 50, startTime, 3600, 0, 100));
		await increaseTime(604810);

		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 14, 0);
		// let startTime = Math.round(Date.now());
		// startTime = (await latestTime()) / 1 + 3 * 604800;
		// let actionHash = encode("addMarketType(uint32,uint32,uint32,uint32,uint32)", 6 * 60 * 60, 50, startTime, 3600, 0);
		// await gv.submitProposalWithSolution(pId, "update max followers limit", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not update market type if option range percent is zero", async function() {
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 3 * 604800;
		await assertRevert(cyclicMarkets.updateMarketType(6 * 60 * 60, 0, 3600, 100, 100));
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 25, 0);
		// let actionHash = encode("updateMarketType(uint32,uint32,uint32,uint32)", 6 * 60 * 60, 0, 3600, 100);
		// await gv.submitProposalWithSolution(pId, "update max followers limit", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not update market type if cooldown time is zero", async function() {
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 3 * 604800;
		await assertRevert(cyclicMarkets.updateMarketType(6 * 60 * 60, 50, 0, 100, 100));
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 25, 0);
		// let actionHash = encode("updateMarketType(uint32,uint32,uint32,uint32)", 6 * 60 * 60, 50, 0, 100);
		// await gv.submitProposalWithSolution(pId, "update max followers limit", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not update market type if min time passed is zero", async function() {
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 3 * 604800;
		await assertRevert(cyclicMarkets.updateMarketType(6 * 60 * 60, 50, 3600, 0, 100));
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 25, 0);
		// let startTime = Math.round(Date.now());
		// startTime = (await latestTime()) / 1 + 3 * 604800;
		// let actionHash = encode("updateMarketType(uint32,uint32,uint32,uint32)", 6 * 60 * 60, 50, 3600, 0);
		// await gv.submitProposalWithSolution(pId, "update max followers limit", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should not update market type if invalid market id is passed", async function() {
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 3 * 604800;
		await assertRevert(cyclicMarkets.updateMarketType(12, 10, 3600, 100, 100));
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 25, 0);
		// let startTime = Math.round(Date.now());
		// startTime = (await latestTime()) / 1 + 3 * 604800;
		// let actionHash = encode("updateMarketType(uint32,uint32,uint32,uint32)", 6 * 60 * 60, 50, 3600, 0);
		// await gv.submitProposalWithSolution(pId, "update max followers limit", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Should create a proposal to add new market type", async function() {
		await increaseTime(604810);
		let startTime = Math.round(Date.now());
		startTime = (await latestTime()) / 1 + 2 * 604800;
		await cyclicMarkets.addMarketType(60 * 60, 50, startTime, 7200, 100, 0)
		
		await increaseTime(604810);
		await increaseTime(604820);
		await cyclicMarkets.createMarket(0,3, 0, {from:user14});

		// let openMarkets = await pl.getOpenMarkets();
		// assert.isAbove(openMarkets[1].length, openMarketsBefore[1].length, "Currency not added");
	});

	it("Predict on newly created market", async function() {
		await cyclicMarkets.setNextOptionPrice(18);
		await assertRevert(cyclicMarkets.createMarket(0,3, 0), {from:user14}); //should revert as market is live
		// await increaseTime(604820);

		// set price
		// user 1
		// set price lot
		await plotusToken.approve(allMarkets.address, "1000000000000000000000");
    	await allMarkets.depositAndPlacePrediction("100000000000000000000", 8, plotusToken.address, 100*1e8, 1);
		let reward = await allMarkets.getReturn(ab1, 8);
		assert.equal(reward, 0);
		await increaseTime(3650);
		await cyclicMarkets.createMarket(0, 3,0, {from:user14});
		await increaseTime(604810);
		await assertRevert(allMarkets.settleMarket(8,1000));
		await cyclicMarkets.settleMarket(8, 0);
		let marketSettleTime = await allMarkets.marketSettleTime(8);
		let marketCoolDownTime = await allMarkets.marketCoolDownTime(8);
		assert.equal(marketCoolDownTime/1 - marketSettleTime/1, 7200);
		await cyclicMarkets.settleMarket(9, 0);
		await cyclicMarkets.createMarket(0, 3, 0);
		await increaseTime(604800);
		await cyclicMarkets.createMarket(0, 3, 0);
		// await pl.exchangeCommission(marketInstance.address);
		await allMarkets.getMarketData(8);
	});

	it("Pause market creation ", async function() {
		await cyclicMarkets.createMarket(0, 1, 0);
		await assertRevert(cyclicMarkets.createMarket(0, 1, 0));
		await allMarkets.pauseMarketCreation();
		// pId = (await gv.getProposalLength()).toNumber();
		// await gvProposal(16, "0x", await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
		await increaseTime(604800);
		await assertRevert(cyclicMarkets.createMarket(0, 1, 0));
		let balance = await allMarkets.getUserUnusedBalance(ab1);
		balance = (balance[0]/1+balance[1]/1);
		await assertRevert(allMarkets.withdraw(toWei(balance/1e18), 100));
	});

	it("Cannot Pause market creation if already paused", async function() {
		await assertRevert(cyclicMarkets.createMarket(0, 1, 0));
		await assertRevert(allMarkets.pauseMarketCreation());
		// pId = (await gv.getProposalLength()).toNumber();
		// await gvProposal(16, "0x", await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
		await increaseTime(604800);
	});

	it("Resume market creation ", async function() {
		await assertRevert(cyclicMarkets.createMarket(0, 1, 0));
		await allMarkets.resumeMarketCreation();
		// pId = (await gv.getProposalLength()).toNumber();
		// await gvProposal(17, "0x", await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
		// await increaseTime(604800);
		await cyclicMarkets.createMarket(0, 1, 0);
		let balance = await allMarkets.getUserUnusedBalance(ab1);
		balance = (balance[0]/1+balance[1]/1);
		if(balance > 0) {
			await allMarkets.withdraw(toWei(balance/1e18), 100);
		}
		await assertRevert(allMarkets.withdraw(toWei(balance/1e18), 100));
		
		// await allMarkets.withdrawReward(100);
		// await allMarkets.withdrawReward(100);
	});

	it("Cannot Resume market creation if already live ", async function() {
		await increaseTime(86401);
		await cyclicMarkets.createMarket(0, 1, 0);
		await assertRevert(allMarkets.resumeMarketCreation());
		// pId = (await gv.getProposalLength()).toNumber();
		// await gvProposal(17, "0x", await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
	});

	it("Pause market creation of ETH <-> Daily markets", async function() {
		await increaseTime(604800);
		await cyclicMarkets.createMarket(0, 1, 0);
		await cyclicMarkets.toggleTypeAndCurrencyPairCreation(1, 0, true);
		// pId = (await gv.getProposalLength()).toNumber();
		// let categoryId = await pc.totalCategories();
		// categoryId = 22;
		// let actionHash = encode1(["uint64","bool"],[0,true])
		// await gvProposal(categoryId, actionHash, await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
		await increaseTime(604800);
		await assertRevert(cyclicMarkets.createMarket(0, 1, 0));
		await cyclicMarkets.createMarket(0, 0, 0);
		await cyclicMarkets.createMarket(1, 0, 0);
		await cyclicMarkets.createMarket(1, 1, 0);
		await cyclicMarkets.createMarket(0, 2, 0);
	});

	it("Resume market creation of ETH <-> Daily markets", async function() {
		await plotusToken.approve(allMarkets.address, toWei(1000000));
		await increaseTime(604800);
		await assertRevert(cyclicMarkets.createMarket(0, 1, 0));
		await cyclicMarkets.toggleTypeAndCurrencyPairCreation(1, 0, false);
		// pId = (await gv.getProposalLength()).toNumber();
		// let categoryId = await pc.totalCategories();
		// categoryId = 22;
		// let actionHash = encode1(["uint64","bool"],[0,false])
		// await gvProposal(categoryId, actionHash, await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
		await increaseTime(604800);
		await cyclicMarkets.createMarket(0, 0, 0);
		await cyclicMarkets.createMarket(0, 1, 0);
		await cyclicMarkets.createMarket(0, 2, 0);
		await increaseTime(604800);
	});

	it("Cannot Resume market creation of ETH <-> Daily markets if already live", async function() {
		await increaseTime(604800);
		await cyclicMarkets.createMarket(0, 1, 0);
		await assertRevert(cyclicMarkets.toggleTypeAndCurrencyPairCreation(1, 0, false));
		// pId = (await gv.getProposalLength()).toNumber();
		// let categoryId = await pc.totalCategories();
		// categoryId = 22;
		// let actionHash = encode1(["uint64","bool"],[0,false])
		// await gvProposal(categoryId, actionHash, await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
		await increaseTime(604800);
		await cyclicMarkets.createMarket(0, 1, 0);
		await increaseTime(604800);
	});

	it("Pause market creation of 4-hourly markets", async function() {
		await cyclicMarkets.createMarket(0, 0, 0);
		await cyclicMarkets.toggleMarketCreationType(0, true);
		// pId = (await gv.getProposalLength()).toNumber();
		// let categoryId = await pc.totalCategories();
		// categoryId = 22;
		// let actionHash = encode1(["uint64","bool"],[0,true])
		// await gvProposal(categoryId, actionHash, await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
		await increaseTime(604800);
		await assertRevert(cyclicMarkets.createMarket(0, 0, 0));
		await cyclicMarkets.createMarket(0, 1, 0);
	});

	it("Resume market creation of 4-hourly markets", async function() {
		await increaseTime(604800);
		await assertRevert(cyclicMarkets.createMarket(0, 0, 0));
		await cyclicMarkets.toggleMarketCreationType(0, false);
		// pId = (await gv.getProposalLength()).toNumber();
		// let categoryId = await pc.totalCategories();
		// categoryId = 22;
		// let actionHash = encode1(["uint64","bool"],[0,false])
		// await gvProposal(categoryId, actionHash, await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
		await increaseTime(604800);
		await cyclicMarkets.createMarket(0, 0, 0);
		await cyclicMarkets.createMarket(0, 1, 0);
		await increaseTime(604800);
	});

	it("Cannot Resume market creation of 4-hourly markets if already live", async function() {
		await increaseTime(604800);
		await cyclicMarkets.createMarket(0, 0, 0);
		await assertRevert(cyclicMarkets.toggleMarketCreationType(0, false));
		// pId = (await gv.getProposalLength()).toNumber();
		// let categoryId = await pc.totalCategories();
		// categoryId = 22;
		// let actionHash = encode1(["uint64","bool"],[0,false])
		// await gvProposal(categoryId, actionHash, await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
		await increaseTime(604800);
		await cyclicMarkets.createMarket(0, 0, 0);
		await cyclicMarkets.getPendingMarketCreationRewards(ab1);
		await cyclicMarkets.createMarket(0, 1, 0);
		await increaseTime(604800);
	});

	it("Transfer DAO plot through proposal", async function() {
		await increaseTime(604800);
		// pId = (await gv.getProposalLength()).toNumber();
		// let categoryId = 18;
		await plotusToken.transfer(master.address, toWei(100));
		let daoPLOTbalanceBefore = await plotusToken.balanceOf(master.address);
		let userPLOTbalanceBefore = await plotusToken.balanceOf(user11);

		await master.transferAssets(plotusToken.address, user11, toWei(100));
		// let actionHash = encode1(["address","address","uint256"],[plotusToken.address, user11, toWei(100)])
		// await gvProposal(categoryId, actionHash, await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
		let daoPLOTbalanceAfter = await plotusToken.balanceOf(master.address);
		let userPLOTbalanceAfter = await plotusToken.balanceOf(user11);
		assert.equal((daoPLOTbalanceBefore/1e18 - 100).toFixed(2), (daoPLOTbalanceAfter/1e18).toFixed(2));
		assert.equal((userPLOTbalanceBefore/1e18 + 100).toFixed(2), (userPLOTbalanceAfter/1e18).toFixed(2));
		await increaseTime(604800);
	});

	it("Transfer DAO plot through proposal, Should Revert if no balance", async function() {
		await increaseTime(604800);
		// pId = (await gv.getProposalLength()).toNumber();
		// let categoryId = 18;
		await plotusToken.transfer(master.address, toWei(100));
		let daoPLOTbalanceBefore = await plotusToken.balanceOf(master.address);
		let userPLOTbalanceBefore = await plotusToken.balanceOf(user11);

		await assertRevert(master.transferAssets(plotusToken.address, user11, toWei(100000000)));

		// let actionHash = encode1(["address","address","uint256"],[plotusToken.address, user11, toWei(100000000)])
		// await gvProposal(categoryId, actionHash, await MemberRoles.at(await master.getLatestAddress(toHex("MR"))), gv, 2, 0);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 1);
		let daoPLOTbalanceAfter = await plotusToken.balanceOf(master.address);
		let userPLOTbalanceAfter = await plotusToken.balanceOf(user11);
		assert.equal((daoPLOTbalanceBefore/1e18).toFixed(2), (daoPLOTbalanceAfter/1e18).toFixed(2));
		assert.equal((userPLOTbalanceBefore/1e18).toFixed(2), (userPLOTbalanceAfter/1e18).toFixed(2));
		await increaseTime(604800);
	});

	it("Should not add new market curreny with null address is passed as feed", async function() {
		await increaseTime(604810);
		let startTime = (await latestTime()) / 1 + 2 * 604800;
		await assertRevert(cyclicMarkets.addMarketCurrency(toHex("LINK/PLOT"), nullAddress, 8, 1, startTime));
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 15, 0);
		// let actionHash = encode("addMarketCurrency(bytes32,address,uint8,uint8,uint32)", toHex("LINK/PLOT"), nullAddress, 8, 1, startTime);
		// await gv.submitProposalWithSolution(pId, "addNewMarketCurrency", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await assertRevert(gv.submitVote(pId, 1, { from: mem2 })); //closed to vote
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
	});

	it("Should update market type", async function() {
		await increaseTime(604810);
		await cyclicMarkets.updateMarketType(0, 10, 3600, 100, 100);
		// pId = (await gv.getProposalLength()).toNumber();
		// await gv.createProposal("Proposal2", "Proposal2", "Proposal2", 0); //Pid 3
		// await gv.categorizeProposal(pId, 25, 0);
		// let startTime = Math.round(Date.now());
		// startTime = (await latestTime()) / 1 + 3 * 604800;
		// let actionHash = encode("updateMarketType(uint32,uint32,uint32,uint32)", 0, 10, 3600, 100);
		// await gv.submitProposalWithSolution(pId, "update market type", actionHash);
		// await gv.submitVote(pId, 1, { from: ab1 });
		// await increaseTime(604810);
		// await gv.closeProposal(pId);
		// let actionStatus = await gv.proposalActionStatus(pId);
		// assert.equal(actionStatus / 1, 3);
	});

	it("Should be able to remove authorized market creator contract", async function() {
		await increaseTime(604800);
		await cyclicMarkets.createMarket(0,1,0);
		await allMarkets.removeAuthorizedMarketCreator(cyclicMarkets.address);
		await increaseTime(604800);
		await assertRevert(cyclicMarkets.createMarket(0,1,0));
	});

	it("Should not add authorized market creator contract if zero address is passed", async function() {
		await increaseTime(604800);
		await assertRevert(cyclicMarkets.createMarket(0,1,0));
		await assertRevert(allMarkets.addAuthorizedMarketCreator(nullAddress));
	});

	it("Should not be able to post result directly", async function() {
		await assertRevert(allMarkets.postMarketResult(10, 10));
	});

	// it("Should update address paramters", async function() {
	// 	let categoryId = await pc.totalCategories();
	// 	categoryId = categoryId*1 - 1;
	// 	await updateParameter(categoryId, 2, "GASAGG", marketIncentives, "address", allMarkets.address);
	// 	await updateInvalidParameter(categoryId, 2, "ABECD", marketIncentives, "address", allMarkets.address);
	// })

});
