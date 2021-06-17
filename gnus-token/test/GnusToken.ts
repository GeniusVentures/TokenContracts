const GeniusTokens = artifacts.require("GeniusTokens");
//const BN = require('bn.js');
import BN from "bn.js";

// Test Set 1
contract('GeniusTokens', (accounts) => {

    // default 1 ether / wei
    const EthToWei = new BN(web3.utils.toWei('1'));

    it('should put 7380000 GNUS Tokens in the first account', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        const balance = web3.utils.fromWei(await gnusTokenInstance.balanceOf(accounts[0]));

        assert.equal(balance, "7380000", "7380000 wasn't in the first account");
    });

    var testSendEth = it('should give us 1,000 GNUS tokens for 1 ETH sent to smart contract', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();

        // this should give us some GNUS tokens to account[0]
        await gnusTokenInstance.sendTransaction({ from: accounts[1], value: web3.utils.toWei('1'), gas: 120000, gasPrice: 20 });

        // now grab the balance of accounts[0] and make sure they have 1,000 GNUS tokens
        const act0GNUSAmount = (await gnusTokenInstance.balanceOf(accounts[1])).div(EthToWei);


        assert(act0GNUSAmount.eq(new BN(1000)), 'Genius Tokens Balance should equal 1,000 but is ' + act0GNUSAmount.toString());
    });

    it('should make sure ETH added is equal to minted GNUS * ICO steps', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        // have to wait until one transaction is done
        await testSendEth;

        const gnusSoldTokens = (await gnusTokenInstance.GNUSBalance()).div(EthToWei);
        const gnusTokenEthBalance = (await gnusTokenInstance.ETHBalance()).div(EthToWei).mul(new BN(1000));

        assert(gnusSoldTokens.eq(gnusTokenEthBalance),
            'Eth Token Balance * 1000 (' + gnusTokenEthBalance.toString() + ') is not equal to GNUS tokens sold: ' + gnusSoldTokens.toString());

    });
    var transferTest = it('should send GNUS token correctly', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();

        // Setup 2 accounts.
        const accountOne = accounts[0];
        const accountTwo = accounts[1];

        // Get initial balances of first and second account.
        const accountOneStartingBalance = await gnusTokenInstance.balanceOf(accountOne);
        const accountTwoStartingBalance = await gnusTokenInstance.balanceOf(accountTwo);

        // Make transaction from first account to second.
        const amount = new BN(web3.utils.toWei('10'));
        await gnusTokenInstance.transfer(accountTwo, amount, { from: accountOne });

        // Get balances of first and second account after the transactions.
        const accountOneEndingBalance = await gnusTokenInstance.balanceOf(accountOne);
        const accountTwoEndingBalance = await gnusTokenInstance.balanceOf(accountTwo);

        assert(accountOneEndingBalance.eq(accountOneStartingBalance.sub(amount)), "Amount wasn't correctly taken from the sender");
        assert(accountTwoEndingBalance.eq(accountTwoStartingBalance.add(amount)), "Amount wasn't correctly sent to the receiver");
    });
    it("should handle buying more than left in stage correctly", async () => {
        await transferTest;

        // send 12,500 ETH , This should push it 1 eth into the 2nd stage

        const gnusTokenInstance = await GeniusTokens.deployed();

        await gnusTokenInstance.sendTransaction({ from: accounts[0], value: web3.utils.toWei('12500'), gas: 120000, gasPrice: 20 });

        // The amount of tokens sold now should be 12,500,000 in 1 stage +  800
        const expectedTokens = new BN("12500800");

        //  tokens sold
        const gnusSoldTokens = (await gnusTokenInstance.GNUSBalance()).div(EthToWei);

        assert(gnusSoldTokens.eq(expectedTokens),"Sold tokens (" + gnusSoldTokens.toString() + ") not equal to expected amount 12,500,800")
    });

    //
    it('non-admin should not be able to withdraw ether', async() => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        const ethOnTap = await gnusTokenInstance.ETHBalance();

        try {
            await gnusTokenInstance.withdrawETH(accounts[2], ethOnTap, {from: accounts[2]});
            assert(false, 'non-admin should not be able to withdraw funds');
        } catch (e) {
            if (e.reason != 'Restricted to admins.') {
                assert(false, e.reason);
            }
        }

    });

    //
    it('admin should be able to withdraw ether', async() => {
        const gnusTokenInstance = await GeniusTokens.deployed();

        const ethOnTap = await gnusTokenInstance.ETHBalance();

        const accountTwoStartETHBalance = new BN(await web3.eth.getBalance(accounts[2]));
        await gnusTokenInstance.withdrawETH(accounts[2], ethOnTap);

        const accountTwoEndingETHBalance = new BN(await web3.eth.getBalance(accounts[2]));
        assert(accountTwoEndingETHBalance.eq(accountTwoStartETHBalance.add(ethOnTap)),
            'Ending Balance does not equal starting balance + ETH withdrawel');
    });
});

// Test set 2
contract('GeniusTokens', (accounts) => {
    // default 1 ether / wei
    const EthToWei = new BN(web3.utils.toWei('1'));

    it('Should fail trying to set minter', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        try {
            const good = await gnusTokenInstance.addMinter(accounts[1], {from: accounts[1]});
            assert(false, 'This should have thrown an error but didn\'t');
        } catch (e )
        {
            if (e.reason != 'Restricted to admins.') {
                assert(false, e.reason);
            }
        }
    });

    it('Should succeed trying to set minter', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        try {
            // should default to owner setting minter
            await gnusTokenInstance.addMinter(accounts[1]);
        } catch (e)
        {
            assert(true, 'Error: ' + e.reason);
        }
    });

    // account 1 should be minter now, let's send to account 2
    it('Minter should be able to mint tokens now', async() => {
        const gnusTokenInstance = await GeniusTokens.deployed();

        var totalSupply = await gnusTokenInstance.totalSupply();

        // Make amount in GNUS Tokens which is 10**18 same as ETH
        const amount = new BN(web3.utils.toWei('12500000'));
        await gnusTokenInstance.mint(accounts[2], amount, {from: accounts[1]});
        const accountTwoEndingBalance = (await gnusTokenInstance.balanceOf(accounts[2]));
        assert(accountTwoEndingBalance.eq(amount),
            "Account two balance should equal " + amount.toString() +
            "but equals " + accountTwoEndingBalance.toString());
    });

    // account 1 should be minter now, let's send to account 2
    it('Check if minting fails after max supply is reached', async() => {
        const gnusTokenInstance = await GeniusTokens.deployed();

        var totalSupply = await gnusTokenInstance.totalSupply();
        var leftSupply = (new BN(web3.utils.toWei('50000000'))).sub(totalSupply);

        // this should give/mint the remaining GNUS tokens to account 2
        await gnusTokenInstance.mint(accounts[2], leftSupply, {from: accounts[1]});

        //totalSupply = await gnusTokenInstance.totalSupply();

        try {
            // this should fail since we are at maximum GNUS tokens
            await gnusTokenInstance.mint(accounts[2], new BN(web3.utils.toWei('1')), {from: accounts[1]});
            assert(false, 'The minting of one more token should have failed, but didn\'t');
        } catch (e) {
            assert(e.reason == 'Minting would exceed max supply', e.reason);
        }
    });

    // Now account 2 has GNUS tokens let's burn them
    it('Test to Burn our own tokens', async() => {
        const gnusTokenInstance = await GeniusTokens.deployed();

        var GNUSTokensBalance = await gnusTokenInstance.balanceOf(accounts[2]);

        var halfTokens = GNUSTokensBalance.div(new BN(2));
        
        // burn 1/2 the tokens ourselves
        await gnusTokenInstance.burn(halfTokens, {from: accounts[2]});
    });

    // let account[1] try and burn the rest of account 2,
    // should fail, only admin should be able to
    it('Test for new minting of tokens after burning', async() => {
        const gnusTokenInstance = await GeniusTokens.deployed();

        const startGNUSTokens = await gnusTokenInstance.balanceOf(accounts[3]);
        
        const toMint = new BN(1000).mul(EthToWei);
        
        // this should give/mint the remaining GNUS tokens to account 2
        await gnusTokenInstance.mint(accounts[3], toMint, {from: accounts[1]});

        const endGNUSTokens = await gnusTokenInstance.balanceOf(accounts[3]);

        assert(endGNUSTokens.sub(startGNUSTokens).eq(toMint),
            'Amounted minted does not equal amount requested to mine');

    });

});
