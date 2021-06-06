const GeniusTokens = artifacts.require("GeniusTokens");
const BN = require('bn.js');

contract('GeniusTokens', (accounts) => {
    it('should put 7380000 GNUS Tokens in the first account', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        const balance = web3.utils.fromWei(await gnusTokenInstance.balanceOf(accounts[0]));

        assert.equal(balance, "7380000", "7380000 wasn't in the first account");
    });
    it('should make sure ETH added is equal to minted GNUS * ICO steps', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        const gnusTokenBalance = (new BN(web3.utils.fromWei(await gnusTokenInstance.gnusBalance()))).mul(new BN("1000"));
        const gnusTokenEthBalance = new BN(web3.utils.fromWei(await gnusTokenInstance.ethBalance()));

        assert(gnusTokenBalance.eq(gnusTokenEthBalance), 'Eth Token Balance not equal to GNUS * 1000, ' + gnusTokenBalance.toString() + ',' + gnusTokenEthBalance.toString());
    });
    it('should send GNUS token correctly', async () => {
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
});