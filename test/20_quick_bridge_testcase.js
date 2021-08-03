const QuickBridge = artifacts.require('QuickBridge');
const ChildChainManager = artifacts.require('MockChildChainManager');
const DummyTokenMock = artifacts.require('DummyTokenMock');
const ERC20 = artifacts.require("TokenMock");

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const { assertRevert } = require('./utils/assertRevert');
const { toHex, toWei } = require("./utils/ethTools.js");
const hash = '0x8da5e6ecc73d11e04b92e026989772d21e293c3943243c2d39ecf1439891d613';
const timestamp = 1613651613;

let quickBridge,childChainManager;
let rootToken1,rootToken2,rootToken3,rootDummyToken;
let childToken1,childToken2,childToken3,childDummyToken;
contract('QuickBridge' ,async function([user1,user2,user3,user4]){


    before(async function () {
    childChainManager = await ChildChainManager.new();
    rootToken1 = await ERC20.new("RT1","RT1");
    rootToken2 = await ERC20.new("RT2","RT2");
    rootToken3 = await ERC20.new("RT3","RT3");
    rootDummyToken = await DummyTokenMock.new("rootDummy","rootDummy");
    childToken2 = await ERC20.new("CT2","CT2");
    childDummyToken = await DummyTokenMock.new("childDummy","childDummy");
    await childChainManager.setRootToChildToken(rootToken2.address,childToken2.address);
    await childChainManager.setRootToChildToken(rootDummyToken.address,childDummyToken.address);
    quickBridge = await QuickBridge.new([rootToken1.address,rootToken2.address,rootDummyToken.address],user2,childChainManager.address);

    await childToken2.mint(quickBridge.address,toWei(1000));
    });

    describe('Quick Bridge', function () {

        it('Quick Bridge contract should initialize correctly', async function () {
          assert.equal(await quickBridge.migrationController(), user2);
          assert.equal(await quickBridge.childChainManager(), childChainManager.address);
          assert.equal(await quickBridge.authController(), user1);
        });

        it('Authorised user should be able to whitelist new allowed token', async function () {
          
          assert.equal(await quickBridge.tokenStatus(rootToken3.address), false);
          await quickBridge.whitelistNewToken([rootToken3.address]);
          assert.equal(await quickBridge.tokenStatus(rootToken3.address), true);

        });

        it('Authorised user should be able to remove allowed token from whitelist', async function () {
          
          assert.equal(await quickBridge.tokenStatus(rootToken3.address), true);
          await quickBridge.disableToken(rootToken3.address);
          assert.equal(await quickBridge.tokenStatus(rootToken3.address), false);

        });

        it('Authorised user should be able to whitelist migration record', async function () {
            let migrationHash = await quickBridge.migrationHash(hash,user4,user3,timestamp,toWei(100),rootToken2.address);
            let migrationStatus = await quickBridge.migrationStatus(migrationHash);
            assert.equal(migrationStatus[0],false);
            await quickBridge.whitelistMigration(hash,user4,user3,timestamp,toWei(100),rootToken2.address);
            migrationStatus = await quickBridge.migrationStatus(migrationHash);
            assert.equal(migrationStatus[0],true);

        });

        it('Migration controller should be able to migrate', async function () {
            let migrationHash = await quickBridge.migrationHash(hash,user4,user3,timestamp,toWei(100),rootToken2.address);
            let migrationStatus = await quickBridge.migrationStatus(migrationHash);
            assert.equal(migrationStatus[0],true);
            assert.equal(migrationStatus[1],false);
            let userBalBefore = await childToken2.balanceOf(user4);
            let contractBalBefore = await childToken2.balanceOf(quickBridge.address);
            await quickBridge.migrate(hash,user4,user3,timestamp,toWei(100),rootToken2.address,{from:user2});
            migrationStatus = await quickBridge.migrationStatus(migrationHash);
            assert.equal(migrationStatus[0],true);
            assert.equal(migrationStatus[1],true);
            let userBalAfter = await childToken2.balanceOf(user4);
            let contractBalAfter = await childToken2.balanceOf(quickBridge.address);
            assert.equal(userBalAfter-userBalBefore,toWei(100));
            assert.equal(contractBalBefore-contractBalAfter,toWei(100));

        });

        it('Authorised account should be able to change authorised account', async function () {
          assert.equal(await quickBridge.authController(),user1);

          await quickBridge.updateAuthController(user2);

          assert.equal(await quickBridge.authController(),user2);
          await quickBridge.updateAuthController(user1,{from:user2});
          assert.equal(await quickBridge.authController(),user1);
        });

        it('Migration controller should be able to change Migration controller account', async function () {
          assert.equal(await quickBridge.migrationController(),user2);

          await quickBridge.updateMigrationController(user3,{from:user2});

          assert.equal(await quickBridge.migrationController(),user3);
          await quickBridge.updateMigrationController(user2,{from:user3});
          assert.equal(await quickBridge.migrationController(),user2);
        });



    describe('Reverts', function () {
        it('should revert if non-authorised tries to call authorised functions', async function () {
          await assertRevert(quickBridge.whitelistMigration(hash,user4,user3,timestamp,toWei(1000),rootToken2.address,{from:user2}));
          await assertRevert(quickBridge.whitelistNewToken([],{from:user2}));
          await assertRevert(quickBridge.disableToken(user2,{from:user2}));
          await assertRevert(quickBridge.updateAuthController(user2,{from:user2}));
        });

        it('should revert if non-migrator tries to call migrator specific functions', async function () {
          await assertRevert(quickBridge.migrate(hash,user4,user3,timestamp,toWei(1000),rootToken2.address,{from:user1}));
          await assertRevert(quickBridge.updateMigrationController(user2,{from:user1}));
        });

        it('should revert if tries to make null address as authorised/ migration controller', async function () {
          await assertRevert(quickBridge.updateAuthController(ZERO_ADDRESS));
          await assertRevert(quickBridge.updateMigrationController(ZERO_ADDRESS,{from:user2}));
        });

        it('should revert if tries to add null token or existing token', async function () {
          await assertRevert(quickBridge.whitelistNewToken([ZERO_ADDRESS]));
          await assertRevert(quickBridge.whitelistNewToken([rootToken1.address]));
        });

        it('should revert if tries to remove null token or non-existing token', async function () {
          await assertRevert(quickBridge.disableToken(ZERO_ADDRESS));
          await assertRevert(quickBridge.disableToken(rootToken3.address));
        });

        it('should revert if tries to whitelist migration with invalid arguments', async function () {
          // If tries to pass null address in _to address
          await assertRevert(quickBridge.whitelistMigration(hash,ZERO_ADDRESS,user3,timestamp,toWei(1000),rootToken2.address));
          // If tries to pass null address in _from address
          await assertRevert(quickBridge.whitelistMigration(hash,user2,ZERO_ADDRESS,timestamp,toWei(1000),rootToken2.address));
          // If tries to pass 0 timestamp
          await assertRevert(quickBridge.whitelistMigration(hash,user2,user3,0,toWei(1000),rootToken2.address));
          // If tries to pass 0 amount
          await assertRevert(quickBridge.whitelistMigration(hash,user2,user3,timestamp,0,rootToken2.address));
          // If tries to pass null address in root token address
          await assertRevert(quickBridge.whitelistMigration(hash,user2,user3,timestamp,toWei(1000),ZERO_ADDRESS));
          // If tries to migrate token that is not whitelisted
          await assertRevert(quickBridge.whitelistMigration(hash,user2,user3,timestamp,toWei(1000),rootToken3.address));
          // If tries to migrate same record multiple times
          await assertRevert(quickBridge.whitelistMigration(hash,user4,user3,timestamp,toWei(100),rootToken2.address));
        });

        it('should revert if tries to migrate with invalid arguments', async function () {
          await quickBridge.whitelistMigration(hash,user2,user3,timestamp,toWei(100),rootToken1.address);
          await quickBridge.whitelistMigration(hash,user2,user3,timestamp,toWei(100),rootDummyToken.address);

          // If tries to migrate non-whitelisted token
          await assertRevert(quickBridge.migrate(hash,user2,user3,timestamp,toWei(1000),rootToken3.address,{from:user2}));
          // If tries to migrate non-whitelisted migration record
          await assertRevert(quickBridge.migrate(hash,user2,user3,timestamp,toWei(1000),rootToken1.address,{from:user2}));
          // If tries to migrate more than 1 times
          await assertRevert(quickBridge.migrate(hash,user4,user3,timestamp,toWei(100),rootToken2.address,{from:user2}));
          // If tries to migrate for root token with null child token
          await assertRevert(quickBridge.migrate(hash,user2,user3,timestamp,toWei(100),rootToken1.address,{from:user2}));
          // If ERC20 transfer fails
          await assertRevert(quickBridge.migrate(hash,user2,user3,timestamp,toWei(100),rootDummyToken.address,{from:user2}));
          
        });

    });
    });

})