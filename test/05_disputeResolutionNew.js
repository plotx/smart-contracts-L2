const { assert } = require("chai");
const OwnedUpgradeabilityProxy = artifacts.require('OwnedUpgradeabilityProxy');
const Master = artifacts.require("Master");
const PlotusToken = artifacts.require("MockPLOT");
const MockchainLinkBTC = artifacts.require("MockChainLinkAggregator");
const AllMarkets = artifacts.require("MockAllMarkets");
const CyclicMarkets = artifacts.require("MockCyclicMarkets");
const DisputeResolution = artifacts.require("DisputeResolution");
const EthChainlinkOracle = artifacts.require('MockChainLinkAggregator');
const BLOT = artifacts.require("BLOT");
const MockChainLinkGasPriceAgg = artifacts.require("MockChainLinkGasPriceAgg");
const gvProposal = require("./utils/gvProposal.js").gvProposalWithIncentiveViaTokenHolder;
const increaseTime = require("./utils/increaseTime.js").increaseTime;
const latestTime = require("./utils/latestTime.js").latestTime;
const encode = require("./utils/encoder.js").encode;
const encode1 = require("./utils/encoder.js").encode1;
const encode3 = require("./utils/encoder.js").encode3;
const {toHex, toWei, toChecksumAddress} = require('./utils/ethTools');
const { assertRevert } = require('./utils/assertRevert');
const signAndExecuteMetaTx = require("./utils/signAndExecuteMetaTx.js").signAndExecuteMetaTx;
let privateKeyList = ["fb437e3e01939d9d4fef43138249f23dc1d0852e69b0b5d1647c087f869fabbd","7c85a1f1da3120c941b83d71a154199ee763307683f206b98ad92c3b4e0af13e","ecc9b35bf13bd5459350da564646d05c5664a7476fe5acdf1305440f88ed784c","f4470c3fca4dbef1b2488d016fae25978effc586a1f83cb29ac8cb6ab5bc2d50","141319b1a84827e1046e93741bf8a9a15a916d49684ab04925ac4ce4573eea23","d54b606094287758dcf19064a8d91c727346aadaa9388732e73c4315b7c606f9","49030e42ce4152e715a7ddaa10e592f8e61d00f70ef11f48546711f159d985df","b96761b1e7ebd1e8464a78a98fe52f53ce6035c32b4b2b12307a629a551ff7cf","d4786e2581571c863c7d12231c3afb6d4cef390c0ac9a24b243293721d28ea95","ed28e3d3530544f1cf2b43d1956b7bd13b63c612d963a8fb37387aa1a5e11460","05b127365cf115d4978a7997ee98f9b48f0ddc552b981c18aa2ee1b3e6df42c6","9d11dd6843f298b01b34bd7f7e4b1037489871531d14b58199b7cba1ac0841e6","f79e90fa4091de4fc2ec70f5bf67b24393285c112658e0d810e6bd711387fbb9","99f1fc0f09230ce745b6a256ba7082e6e51a2907abda3d9e735a5c8188bb4ba1","477f86cce983b9c91a36fdcd4a7ce21144a08dee9b1aafb91b9c70e57f717ce6","b03d2e6bb4a7d71c66a66ff9e9c93549cae4b593f634a4ea2a1f79f94200f5b4","9ddc0f53a81e631dcf39d5155f41ec12ed551b731efc3224f410667ba07b37dc","cf087ff9ae7c9954ad8612d071e5cdf34a6024ee1ae477217639e63a802a53dd","b64f62b94babb82cc78d3d1308631ae221552bb595202fc1d267e1c29ce7ba60","a91e24875f8a534497459e5ccb872c4438be3130d8d74b7e1104c5f94cdcf8c2","4f49f3d029eeeb3fed14d59625acd088b6b34f3b41c527afa09d29e4a7725c32","179795fd7ac7e7efcba3c36d539a1e8659fb40d77d0a3fab2c25562d99793086","4ba37d0b40b879eceaaca2802a1635f2e6d86d5c31e3ff2d2fd13e68dd2a6d3d","6b7f5dfba9cd3108f1410b56f6a84188eee23ab48a3621b209a67eea64293394","870c540da9fafde331a3316cee50c17ad76ddb9160b78b317bef2e6f6fc4bac0","470b4cccaea895d8a5820aed088357e380d66b8e7510f0a1ea9b575850160241","8a55f8942af0aec1e0df3ab328b974a7888ffd60ded48cc6862013da0f41afbc","2e51e8409f28baf93e665df2a9d646a1bf9ac8703cbf9a6766cfdefa249d5780","99ef1a23e95910287d39493d8d9d7d1f0b498286f2b1fdbc0b01495f10cf0958","6652200c53a4551efe2a7541072d817562812003f9d9ef0ec17995aa232378f8","39c6c01194df72dda97da2072335c38231ced9b39afa280452afcca901e73643","12097e411d948f77b7b6fa4656c6573481c1b4e2864c1fca9d5b296096707c45","cbe53bf1976aee6cec830a848c6ac132def1503cffde82ccfe5bd15e75cbaa72","eeab5dcfff92dbabb7e285445aba47bd5135a4a3502df59ac546847aeb5a964f","5ea8279a578027abefab9c17cef186cccf000306685e5f2ee78bdf62cae568dd","0607767d89ad9c7686dbb01b37248290b2fa7364b2bf37d86afd51b88756fe66","e4fd5f45c08b52dae40f4cdff45e8681e76b5af5761356c4caed4ca750dc65cd","145b1c82caa2a6d703108444a5cf03e9cb8c3cd3f19299582a564276dbbba734","736b22ec91ae9b4b2b15e8d8c220f6c152d4f2228f6d46c16e6a9b98b4733120","ac776cb8b40f92cdd307b16b83e18eeb1fbaa5b5d6bd992b3fda0b4d6de8524c","65ba30e2202fdf6f37da0f7cfe31dfb5308c9209885aaf4cef4d572fd14e2903","54e8389455ec2252de063e83d3ce72529d674e6d2dc2070661f01d4f76b63475","fbbbfb525dd0255ee332d51f59648265aaa20c2e9eff007765cf4d4a6940a849","8de5e418f34d04f6ea947ce31852092a24a705862e6b810ca9f83c2d5f9cda4d","ea6040989964f012fd3a92a3170891f5f155430b8bbfa4976cde8d11513b62d9","14d94547b5deca767137fbd14dae73e888f3516c742fad18b83be333b38f0b88","47f05203f6368d56158cda2e79167777fc9dcb0c671ef3aabc205a1636c26a29"];
let gv,masterInstance, tokenController, mr;
contract("Market", ([ab1, ab2, ab3, ab4, dr1, dr2, dr3, notMember]) => {
  it("1.if DR panel accepts", async () => {
    masterInstance = await OwnedUpgradeabilityProxy.deployed();
    masterInstance = await Master.at(masterInstance.address);
      
    let allMarkets = await masterInstance.getLatestAddress(web3.utils.toHex("AM"));
    allMarkets = await AllMarkets.at(allMarkets);
    ethChainlinkOracle = await EthChainlinkOracle.deployed();

    dr = await DisputeResolution.at(await masterInstance.getLatestAddress(toHex("DR")));
    cyclicMarkets = await CyclicMarkets.at(await masterInstance.getLatestAddress(toHex("CM")));
    await assertRevert(dr.setMasterAddress(dr.address, dr.address));
    await increaseTime(3600*4);
    let nxmToken = await PlotusToken.deployed();
    let address = await masterInstance.getLatestAddress(web3.utils.toHex("GV"));
    let plotusToken = await PlotusToken.deployed();
    await plotusToken.transfer(masterInstance.address, "10000000000000000000000");
    let masterInstanceBalanceBefore = await plotusToken.balanceOf(masterInstance.address);
    await cyclicMarkets.createMarket(0,0, 0);
    await plotusToken.transfer(ab2, "50000000000000000000000");
    await plotusToken.transfer(ab3, "50000000000000000000000");
    await plotusToken.transfer(ab4, "50000000000000000000000");
    await plotusToken.transfer(dr1, "50000000000000000000000");
    await plotusToken.transfer(dr2, "50000000000000000000000");
    await plotusToken.transfer(dr3, "50000000000000000000000");
    await plotusToken.approve(allMarkets.address, "10000000000000000000000");
    // Cannot raise dispute if there is no participation
    // await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute","this is description","this is solution hash"));
    await cyclicMarkets.setNextOptionPrice(9);
    await allMarkets.depositAndPlacePrediction("10000000000000000000000", 7, plotusToken.address, 100*1e8, 1);
    // cannot raise dispute if market is open
    await plotusToken.approve(allMarkets.address, "10000000000000000000000");
    await assertRevert(dr.raiseDispute(7, 1400000000000, "this is description"));
    
    await increaseTime(3601);
    // cannot raise dispute if market is closed but result is not out
    await plotusToken.approve(allMarkets.address, "10000000000000000000000");
    await assertRevert(dr.raiseDispute(7, 1400000000000, "this is solution hash"));
   
    await ethChainlinkOracle.setLatestAnswer("10000000000000000000");
    await increaseTime(8*3600);
    await cyclicMarkets.settleMarket(7, 1);
    let allMarketsBalanceBefore = await plotusToken.balanceOf(allMarkets.address);
    let masterInstanceBalance = await plotusToken.balanceOf(masterInstance.address);
    // let fee = "1999999960000000000";
    let daoFee = "399999980000000000";
    assert.equal(masterInstanceBalance*1, masterInstanceBalanceBefore/1+daoFee*1);
     // cannot raise dispute with less than minimum stake
    await plotusToken.approve(dr.address, "10000000000000000000000");
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute",{from : notMember}));
    //can raise dispute in cooling period and stake
    await plotusToken.approve(dr.address, "10000000000000000000000");
    let functionSignature = encode3("raiseDispute(uint256,uint256,string)",7,1,"raise dispute");
    await signAndExecuteMetaTx(
      privateKeyList[0],
      ab1,
      functionSignature,
      dr,
      "DR"
      );
    // await allMarkets.raiseDispute(7,1,"raise dispute","this is description","this is solution hash");
    // cannot raise dispute multiple times
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute"));
    await assertRevert(dr.declareResult(7));
    let winningOption_af = await allMarkets.getMarketResults(7)
    let userBalBefore = await plotusToken.balanceOf(ab1);
    
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr1});
    
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr2});
    
    await assertRevert(dr.submitVote(7, toWei(100), 1, {from:dr3})) //reverts as tokens not locked
  
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr3});
    
    await dr.submitVote(7, toWei("1000"), 1, {from:dr1});
    await dr.submitVote(7, toWei("1000"), 1, {from:dr2});
    await dr.submitVote(7, toWei("1000"), 1, {from:dr3});
    await increaseTime(604800);
    await dr.declareResult(7);
    let winningOption_afterVote = await allMarkets.getMarketResults(7);
    assert.notEqual(winningOption_af[0]/1, winningOption_afterVote[0]/1);
    assert.equal(winningOption_afterVote[0]/1, 1);

    let allMarketsBalanceAfter = await plotusToken.balanceOf(allMarkets.address);
    let commission = 3.6 * 1e18;
    // let marketCreatorIncentives = 99.95*((0.05)/100) * 1e18;
    let masterInstanceBalanceAfter = await plotusToken.balanceOf(masterInstance.address);
    let votingReward = "500000000000000000000";
    assert.equal(masterInstanceBalanceBefore*1  + daoFee*1 - votingReward*1, masterInstanceBalanceAfter*1);

    assert.equal((allMarketsBalanceAfter/1), allMarketsBalanceBefore/1, "Tokens staked for dispute not burned");
    // let data = await plotusNewInstance.marketDisputeData(marketInstance.address)
    // assert.equal(data[0], proposalId,"dispute proposal mismatch");
    // let marketDetails = await plotusNewInstance.getMarketDetails(marketInstance.address);
    // assert.equal(marketDetails[7]/1, 3, "status not updated");

    let userBalAfter = await plotusToken.balanceOf(ab1);
    assert.equal(userBalAfter/1e18, userBalBefore/1e18+500);
  });

  it("Should be able to withdraw locked tokens of voters after lock period is completed", async()=> {
      await assertRevert(dr.withdrawLockedTokens(7, {from:dr1}));
      await increaseTime(15*86400);
      await dr.withdrawLockedTokens(7, {from:dr1});
      await dr.withdrawLockedTokens(7, {from:dr2});
      await dr.withdrawLockedTokens(7, {from:dr3});
  })
  it("Should not be able to withdraw locked tokens twice", async()=> {
      await assertRevert(dr.withdrawLockedTokens(7, {from:dr1}));
  })
});

contract("Market", ([ab1, ab2, ab3, ab4, dr1, dr2, dr3, notMember]) => {
  it("1.DR panel accepts and proper transfer of assets between AllMarkets and MarketCreationRewards", async () => {
    masterInstance = await OwnedUpgradeabilityProxy.deployed();
    masterInstance = await Master.at(masterInstance.address);
      
    allMarkets = await masterInstance.getLatestAddress(web3.utils.toHex("AM"));
    allMarkets = await AllMarkets.at(allMarkets);
    dr = await DisputeResolution.at(await masterInstance.getLatestAddress(toHex("DR")));

    await increaseTime(3600*4);
    let nxmToken = await PlotusToken.deployed();
    let address = await masterInstance.getLatestAddress(web3.utils.toHex("GV"));
    plotusToken = await PlotusToken.deployed();
    await plotusToken.transfer(masterInstance.address, "10000000000000000000000");
    await plotusToken.transfer(dr1, "50000000000000000000000");
    await plotusToken.approve(allMarkets.address, "30000000000000000000000", {from:dr1});
    // await plotusToken.transfer(masterInstance.address, "100000000000000000000");
    let masterInstanceBalanceBefore = await plotusToken.balanceOf(masterInstance.address);
    await cyclicMarkets.createMarket(0,0, 0,{from:dr1});
   
    await plotusToken.transfer(ab2, "50000000000000000000000");
    await plotusToken.transfer(ab3, "50000000000000000000000");
    await plotusToken.transfer(ab4, "50000000000000000000000");
    await plotusToken.transfer(dr2, "50000000000000000000000");
    await plotusToken.transfer(dr3, "50000000000000000000000");
    await plotusToken.approve(dr.address, "30000000000000000000000");
    await plotusToken.approve(allMarkets.address, "30000000000000000000000");
    // Cannot raise dispute if there is no participation
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute"));
    await cyclicMarkets.setNextOptionPrice(9);
    await allMarkets.depositAndPlacePrediction("10000000000000000000000", 7, plotusToken.address, 100*1e8, 1);
    await allMarkets.depositAndPlacePrediction("20000000000000000000000", 7, plotusToken.address, 200*1e8, 3);
    // cannot raise dispute if market is open
    await plotusToken.approve(dr.address, "10000000000000000000000");
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute"));
    
    await increaseTime(3601);
    // cannot raise dispute if market is closed but result is not out
    await plotusToken.approve(dr.address, "10000000000000000000000");
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute"));
   
    await ethChainlinkOracle.setLatestAnswer("10000000000000000000");
    await increaseTime(8*3600);
    let allMarketsBalanceBefore = await plotusToken.balanceOf(allMarkets.address);
    await cyclicMarkets.settleMarket(7, 1);
    let masterInstanceBalance = await plotusToken.balanceOf(masterInstance.address);
    let commission = 7.2 * 1e18;
    let rewardPool = 163.33333333*1e18;
    let marketCreatorIncentive = 0 * 0.5/100;
    let fee = "3999999960000000000"/1;
    let daoFee = "799999980000000000";
    assert.equal(masterInstanceBalance*1, masterInstanceBalanceBefore/1 + daoFee/1);
     // cannot raise dispute with less than minimum stake
    await plotusToken.approve(dr.address, "10000000000000000000000",{from : notMember});
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute",{from : notMember}));
    //can raise dispute in cooling period and stake
    await plotusToken.approve(dr.address, "10000000000000000000000");
    await dr.raiseDispute(7,1,"raise dispute");
    // cannot raise dispute multiple times
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute"));
    await assertRevert(dr.declareResult(7));
    let winningOption_af = await allMarkets.getMarketResults(7)
    let userBalBefore = await plotusToken.balanceOf(ab1);
    
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr1});
    
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr2});

    await assertRevert(dr.submitVote(7, toWei(100), 1, {from:dr3})) //reverts as tokens not locked
  
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr3});
    await dr.submitVote(7, toWei(2000), 1, {from:dr1});
    assert.equal((await dr.getUserVoteValue(dr1, 7))/1, toWei(2000));
    await dr.submitVote(7, toWei(2000), 1, {from:dr2});
    assert.equal((await dr.getUserVoteValue(dr2, 7))/1, toWei(2000));
    await dr.submitVote(7, toWei(2000), 1, {from:dr3});
    assert.equal((await dr.getUserVoteValue(dr3, 7))/1, toWei(2000));
    await increaseTime(604800);
    await dr.declareResult(7);
    await assertRevert(dr.declareResult(7));

    let winningOption_afterVote = await allMarkets.getMarketResults(7);
    assert.notEqual(winningOption_af[0]/1, winningOption_afterVote[0]/1);
    assert.equal(winningOption_afterVote[0]/1, 1);

    let allMarketsBalanceAfter = await plotusToken.balanceOf(allMarkets.address);
    // let marketCreatorIncentives = 99.95*((0.05)/100) * 1e18;
    let masterInstanceBalanceAfter = await plotusToken.balanceOf(masterInstance.address);
    let votingReward = "500000000000000000000";
    assert.equal(((masterInstanceBalanceBefore*1 + daoFee/1 - votingReward/1)/1e18).toFixed(8), (masterInstanceBalanceAfter/1e18).toFixed(8));
    // assert.equal((allMarketsBalanceAfter/1), allMarketsBalanceBefore/1 - fee/1 , "Tokens staked for dispute not burned");
    // let data = await plotusNewInstance.marketDisputeData(marketInstance.address)
    // assert.equal(data[0], proposalId,"dispute proposal mismatch");
    // let marketDetails = await plotusNewInstance.getMarketDetails(marketInstance.address);
    // assert.equal(marketDetails[7]/1, 3, "status not updated");
    let userBalAfter = await plotusToken.balanceOf(ab1);
    assert.equal(~~(userBalAfter/1e16), ~~(userBalBefore/1e16)+50000);
  });
  it("Should be able to claim rewards for voting in DR", async() => {
    let rewards = [16666666667, 16666666667, 16666666667]
    let voters = [dr1, dr2, dr3];
    for(let i = 0;i<3;i++) {
      let pendingReward = await dr.getPendingReward(voters[i]);
      assert.equal(rewards[i], (pendingReward/1e10).toFixed(0));
      let userBalanceBefore = await plotusToken.balanceOf(voters[i]);
      await dr.claimReward(voters[i], 100);
      let userBalanceAfter = await plotusToken.balanceOf(voters[i]);
      assert.equal(userBalanceBefore/1e10 + rewards[i], (userBalanceAfter/1e10).toFixed(0));
    }
  });
  it("Claim rewards for multiple DR", async()=> {
    await increaseTime(4*3600);
    await cyclicMarkets.createMarket(0,0,1);
    await cyclicMarkets.createMarket(1,0,0);
    await increaseTime(4*3600);
    await cyclicMarkets.createMarket(0,0,1);
    await increaseTime(8*3600);
    await cyclicMarkets.settleMarket(8, 1);
    await cyclicMarkets.settleMarket(9, 1);
    await cyclicMarkets.settleMarket(10, 1);
    await dr.raiseDispute(8, 1, "Raise dispute");
    await dr.raiseDispute(9, 1, "Raise dispute");
    await dr.raiseDispute(10, 1, "Raise dispute");
    await dr.submitVote(8, toWei(2000), 1, {from:dr2});
    await dr.submitVote(8, toWei(2000), 0, {from:dr2});
    await dr.submitVote(9, toWei(2000), 1, {from:dr2});
    await dr.submitVote(10, toWei(2000), 1, {from:dr2});
    await increaseTime(86500*3);
    await dr.declareResult(9);
    let pendingReward = await dr.getPendingReward(dr2);
    assert.equal(pendingReward/1e18, 500);
    await dr.claimReward(dr2, 100);
    await assertRevert(allMarkets.postMarketResult(8, 10000));
    await dr.declareResult(8);
    await dr.declareResult(10);
    pendingReward = await dr.getPendingReward(dr2);
    assert.equal(pendingReward/1e18, 1000);
    await dr.claimReward(dr2, 100);
    await assertRevert(dr.claimReward(dr2, 100));
  });
  it("Should not be able to withdraw tokens from dao", async() => {
    await assertRevert(masterInstance.withdrawForDRVotingRewards(toWei(100)));
  });
});
contract("Market", ([ab1, ab2, ab3, ab4, dr1, dr2, dr3, notMember]) => {
  it("1.if quorum not reached proposal should be rejected", async () => {
    masterInstance = await OwnedUpgradeabilityProxy.deployed();
    masterInstance = await Master.at(masterInstance.address);

    let allMarkets = await masterInstance.getLatestAddress(web3.utils.toHex("AM"));
    allMarkets = await AllMarkets.at(allMarkets);

    await increaseTime(3600*4);
    await cyclicMarkets.createMarket(0,0, 0);
    let nxmToken = await PlotusToken.deployed();
    let plotusToken = await PlotusToken.deployed();
    await plotusToken.transfer(masterInstance.address, "100000000000000000000");
   
    await plotusToken.transfer(ab2, "50000000000000000000000");
    await plotusToken.transfer(ab3, "50000000000000000000000");
    await plotusToken.transfer(ab4, "50000000000000000000000");
    await plotusToken.transfer(dr1, "50000000000000000000000");
    await plotusToken.transfer(dr2, "50000000000000000000000");
    await plotusToken.transfer(dr3, "50000000000000000000000");
    await cyclicMarkets.setNextOptionPrice(2);
    await plotusToken.approve(allMarkets.address, "100000000000000000000");
    await allMarkets.depositAndPlacePrediction("100000000000000000000", 7, plotusToken.address, 100*1e8, 1);
    // cannot raise dispute if market is open
    await plotusToken.approve(dr.address, "10000000000000000000000");
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute"));
    
    await increaseTime(3601);
    // cannot raise dispute if market is closed but result is not out
    await plotusToken.approve(dr.address, "10000000000000000000000");
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute"));
   
    await increaseTime(3600*8);
    await allMarkets.postResultMock(100000000000, 7);
     // cannot raise dispute with less than minimum stake
    await plotusToken.approve(dr.address, "10000000000000000000000",{from : notMember});
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute",{from : notMember}));
    //can raise dispute in cooling period and stake
    await plotusToken.approve(dr.address, "10000000000000000000000");
    await dr.raiseDispute(7, 1400000000000,"raise dispute");
    // cannot raise dispute multiple times
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute"));
    await assertRevert(dr.declareResult(7));
    let winningOption_af = await allMarkets.getMarketResults(7)
    let userBalBefore = await plotusToken.balanceOf(ab1);
    
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr1});
    
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr2});
    
    await assertRevert(dr.submitVote(7, toWei(100), 1, {from:dr3})) //reverts as tokens not locked
  
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr3});
    await increaseTime(604800);
    await dr.declareResult(7);
    // let data = await plotusNewInstance.marketDisputeData(marketInstance.address)
    // assert.equal(data[0], proposalId,"dispute proposal mismatch");
    // let marketDetails = await plotusNewInstance.getMarketDetails(marketInstance.address);
    // assert.equal(marketDetails[7]/1, 3, "status not updated");

    let userBalAfter = await plotusToken.balanceOf(ab1);
    let winningOption_afterVote = await allMarkets.getMarketResults(7)
    assert.equal(userBalAfter/1e18, userBalBefore/1e18, "Tokens not burnt");
    assert.equal(winningOption_af[0]/1, winningOption_afterVote[0]/1);
  });
});
contract("Market", ([ab1, ab2, ab3, ab4, dr1, dr2, dr3, notMember]) => {
  it("2.if DR panel rejects", async () => {
    masterInstance = await OwnedUpgradeabilityProxy.deployed();
    masterInstance = await Master.at(masterInstance.address);
  
    let allMarkets = await masterInstance.getLatestAddress(web3.utils.toHex("AM"));
    allMarkets = await AllMarkets.at(allMarkets);

    await increaseTime(3600*4);
    await cyclicMarkets.createMarket(0,0,0);
    let nxmToken = await PlotusToken.deployed();
    let plotusToken = await PlotusToken.deployed();

    await plotusToken.transfer(ab2, "50000000000000000000000");
    await plotusToken.transfer(ab3, "50000000000000000000000");
    await plotusToken.transfer(ab4, "50000000000000000000000");
    await plotusToken.transfer(dr1, "50000000000000000000000");
    await plotusToken.transfer(dr2, "50000000000000000000000");
    await plotusToken.transfer(dr3, "50000000000000000000000");
    await cyclicMarkets.setNextOptionPrice(2);
    await plotusToken.approve(allMarkets.address, "100000000000000000000");
    await allMarkets.depositAndPlacePrediction("100000000000000000000", 7, plotusToken.address, 100*1e8, 1);
    
    await increaseTime(3600*8);
    await allMarkets.postResultMock(100000000000, 7);
    //can raise dispute in cooling period and stake
    await plotusToken.approve(dr.address, "10000000000000000000000");
    let allMarketsBalanceBefore = await plotusToken.balanceOf(allMarkets.address);
    await dr.raiseDispute(7, 1400000000000,"raise dispute");
    await increaseTime(901);
     // cannot raise dispute if market cool time is over
    await plotusToken.approve(dr.address, "10000000000000000000000");
    await assertRevert(dr.raiseDispute(7, 1400000000000,"raise dispute"));
    
    let plotusContractBalanceBefore = await plotusToken.balanceOf(allMarkets.address);
    let winningOption_before = await allMarkets.getMarketResults(7)
    let userBalBefore = await plotusToken.balanceOf(ab1);
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr1});
    
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr2});
    
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : dr3});

    await dr.submitVote(7, toWei(2000), 0, {from:dr1});
    await dr.submitVote(7, toWei(2000), 0, {from:dr2});
    await dr.submitVote(7, toWei(2000), 0, {from:dr3});
    await increaseTime(3 * 86401);
    //SHould not allow to vote after time is over
    
    await plotusToken.approve(dr.address, "100000000000000000000000",{from : ab2});
    await assertRevert(dr.submitVote(7, toWei(100), 1, {from:ab1}))  
    
    let mcBalanceBefore = await plotusToken.balanceOf(masterInstance.address);
    await assertRevert(dr.burnLockedTokens(dr1, 7));
    await dr.declareResult(7);
    let mcBalanceAfter = await plotusToken.balanceOf(masterInstance.address);
    await increaseTime(86401);
    let plotusContractBalanceAfter = await plotusToken.balanceOf(allMarkets.address);
    // assert.isAbove(plotusContractBalanceBefore/1, plotusContractBalanceAfter/1);
    //Incentives will be burnt: 500 tokens i.e 500000000000000000000
    // assert.equal((plotusContractBalanceAfter/1e18).toFixed(2), (plotusContractBalanceBefore/1e18).toFixed(2), "Tokens staked for dispute not burned");
    let votingReward = 500;
    assert.equal((mcBalanceAfter/1e18).toFixed(2) - 500, (mcBalanceBefore/1e18).toFixed(2) -  votingReward/1, "Tokens staked for dispute not burned");
    let allMarketsBalanceAfter = await plotusToken.balanceOf(allMarkets.address);
    allMarketsBalanceAfter = allMarketsBalanceAfter.toString();
    allMarketsBalanceBefore = allMarketsBalanceBefore.toString();
    assert.equal((allMarketsBalanceAfter), allMarketsBalanceBefore, "Tokens staked for dispute not burned");
    let userBalAfter = await plotusToken.balanceOf(ab1);

    assert.equal(userBalAfter/1e18, userBalBefore/1e18, "Tokens not burnt");
    let winningOption_afterVote = await allMarkets.getMarketResults(7);
    assert.equal(winningOption_before[0]/1, winningOption_afterVote[0]/1);
  });

  it("Should burn all DR member's tokens if lock period is not completed", async function() {

    await dr.burnLockedTokens(dr1, 7)
    let tokensLockedOfDR1after = await dr.getUserVoteValue(dr1, 7);
    assert.equal(tokensLockedOfDR1after/1, 0, "Not burned");
  });
    
  it("Increase time to complete lock period", async function() {
    await increaseTime(8640000);
  });

  it("Should not burn DR member's tokens if lock period is completed", async function() {
    await assertRevert(dr.burnLockedTokens(dr2, 7));
  });

});