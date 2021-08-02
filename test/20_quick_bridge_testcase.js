const QuickBridge = artifacts.require('QuickBridge');
const PLOT = artifacts.require('MockPLOT');
const DummyMappedToken = artifacts.require('MockPLOT');
// const OwnedUpgradeabilityProxy = artifacts.require("OwnedUpgradeabilityProxy");
// const Master = artifacts.require("Master");
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const { assertRevert } = require('./utils/assertRevert');
var PLOTInstance;
var QuickBridgeInstance;
const hash = '0x8da5e6ecc73d11e04b92e026989772d21e293c3943243c2d39ecf1439891d613';
const timestamp = 1613651613;
contract('QuickBridge' ,async function([user1,user2,user3,user4]){


    it('1. Should not allow to mint to zero address',async function(){
        PLOTInstance = await PLOT.deployed();
        QuickBridgeInstance = await QuickBridge.new([PLOTInstance.address], user3, user4);

        await PLOTInstance.approve(PLOTInstance.address, "10000000000000000000000");
        await assertRevert(PLOTInstance.mint(ZERO_ADDRESS,"1000000000000000000000"));
    });

    it('2. Should authorise the txn when called from authController', async function() {
        await (QuickBridgeInstance.whitelistMigration(hash,user1,user2,timestamp,"1000000000000000000000",PLOTInstance.address,{from:user3}));
    });

    it('3. Should not authorise when the same txn is authorised again', async function() {
        await assertRevert(QuickBridgeInstance.whitelistMigration(hash,user1,user2,timestamp,"1000000000000000000000",PLOTInstance.address,{from:user3}));
    });

    it('4. Should not be able to migrate tokens if migration contract doesnt hold bPLOT', async function() {
        await assertRevert(QuickBridgeInstance.migrate(hash,user1,user2,timestamp,"1000000000000000000000",PLOTInstance.address,{from:user4}));
    });

    it('5. Should migrate tokens as authorised when called from migrationController', async function() {
        await PLOTInstance.mint(QuickBridgeInstance.address,"10000000000000000000000")
        await (QuickBridgeInstance.migrate(hash,user1,user2,timestamp,"1000000000000000000000",PLOTInstance.address,{from:user4}));
    });

    it('6.Should not migrate tokens if the authorised txn is already migrated', async function() {
        await assertRevert(QuickBridgeInstance.migrate(hash,user1,user2,timestamp,"1000000000000000000000",PLOTInstance.address,{from:user4}));
    });

    it('7.Should not migrate tokens if the txn is not authorised', async function() {
        await assertRevert(QuickBridgeInstance.migrate(hash,user1,user2,timestamp,"2000000000000000000000",PLOTInstance.address,{from:user4}));
    });

    it('8.Should revert when not called from authController', async function() {
        await assertRevert(QuickBridgeInstance.whitelistMigration(hash,user1,user2,timestamp,"2000000000000000000000",PLOTInstance.address,{from:user2}));
    });

    it('9.Should revert when not called from migrationController', async function() {
        await assertRevert(QuickBridgeInstance.migrate(hash,user1,user2,timestamp,"2000000000000000000000",PLOTInstance.address,{from:user2}));
    });

})