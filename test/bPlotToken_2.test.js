const BLOT = artifacts.require('BPLOT');
const BLOT_2 = artifacts.require('BPLOT_2');
const BPLOTMigration = artifacts.require('bPLOTMigration');
const PLOT = artifacts.require('MockPLOT');
const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
const Master = artifacts.require("Master");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const { assert } = require('chai');
const { assertRevert } = require('./utils/assertRevert');
const { toWei } = require('./utils/ethTools');
var BLOTInstance;
const hash = '0x8da5e6ecc73d11e04b92e026989772d21e293c3943243c2d39ecf1439891d613';
const timestamp = 1613651613;
contract('bLOTToken', function([user1,user2,ecosystemAddress,authToBurn]){

    it('Minter can mint bLOTTokens',async function(){
        masterInstance = await OwnedUpgradeabilityProxy.deployed();
        masterInstance = await Master.at(masterInstance.address);
        PLOTInstance = await PLOT.deployed();
        nullAddress = await masterInstance.getLatestAddress(web3.utils.fromAscii("XX"))
        BLOTInstance = await BLOT.at(await masterInstance.getLatestAddress(web3.utils.fromAscii("BL")));
        await PLOTInstance.approve(BLOTInstance.address, "10000000000000000000000");
        let canMint = await BLOTInstance.mint(user1,"1000000000000000000000");
        await assertRevert(BLOTInstance.setMasterAddress(user1, user1));
        assert.ok(canMint)
    })


    it('Should upgrade contract to v2',async function(){
        masterInstance = await Master.at(masterInstance.address);
        let bPLOT_2 = await BLOT_2.new();
        await masterInstance.upgradeMultipleImplementations([web3.utils.fromAscii("BL")],[bPLOT_2.address]);
        BLOTInstance = await BLOT_2.at(await masterInstance.getLatestAddress(web3.utils.fromAscii("BL")));
    })

    it('Minter can mint bLOTToken in new contract',async function(){
        await PLOTInstance.approve(BLOTInstance.address, "100000000000000000000");
        let canMint = await BLOTInstance.mint(user1,"100000000000000000000");
        assert.ok(canMint)
    })

    it('Minter can transfer bLOT  tokens ,non minter cannot transfer bLOT token',async function(){
        PLOTInstance = await PLOT.deployed();
        // BLOTInstance = await BLOT.deployed();
        await PLOTInstance.approve(BLOTInstance.address, "10000000000000000000000");
        await BLOTInstance.mint(user1,"1000000000000000000000");
        let canTransfer = await BLOTInstance.transfer(user2,"100000000000000000",{from : user1});
        assert.ok(canTransfer)
        await assertRevert(BLOTInstance.transfer(user2,"100000000000000000",{from : user2}))
    })

    it('Should be able to set ecosystem and auth address to burn bPLOT',async function(){
        await BLOTInstance.setEcoSystemAddres(ecosystemAddress);
        await assertRevert(BLOTInstance.setEcoSystemAddres(nullAddress));
        await assertRevert(BLOTInstance.setEcoSystemAddres(ecosystemAddress, {from:user2}));

        await BLOTInstance.setAuthToBurnbPLOT(authToBurn);
        await assertRevert(BLOTInstance.setAuthToBurnbPLOT(authToBurn, {from:user2}));
    });

    it('Auth address should be able to burn bPLOT and plot to be sent to ecosystemAddress',async function(){
        await PLOTInstance.approve(BLOTInstance.address, toWei(100));
        await BLOTInstance.mint(user2, toWei(100));

        await assertRevert(BLOTInstance.burnUnusedbPLOT([user2], [toWei(100)]));
        let bPLOTUser2_before = await BLOTInstance.balanceOf(user2);
        let plotEcosystem_before = await PLOTInstance.balanceOf(ecosystemAddress);
        await BLOTInstance.burnUnusedbPLOT([user2], [toWei(100)], {from:authToBurn});
        let bPLOTUser2_after = await BLOTInstance.balanceOf(user2);
        let plotEcosystem_after = await PLOTInstance.balanceOf(ecosystemAddress);

        let bPLOTUser2_diff = bPLOTUser2_before/1e18 - bPLOTUser2_after/1e18
        let plotEcosystem_diff = plotEcosystem_after/1e18 - plotEcosystem_before/1e18
        assert.equal(bPLOTUser2_diff, plotEcosystem_diff);
    });

});
