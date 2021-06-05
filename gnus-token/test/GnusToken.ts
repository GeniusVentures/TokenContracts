const GeniusTokens = artifacts.require("GeniusTokens");

contract('GeniusTokens', (accounts) => {
    it('should put 7380000 GNUS Tokens in the first account', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        const balance = await gnusTokenInstance.getBalance(accounts[0]);

        assert.equal(balance.toString(), "7380000", "7380000 wasn't in the first account");
    });
    it('should call a function that depends on a linked library', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        const gnusTokenBalance = (await gnusTokenInstance.gnusTokenBalance(accounts[0])).toNumber();
        const gnusTokenEthBalance = (await gnusTokenInstance.ethBalance(accounts[0])).toNumber();

        // need to check all balances here based on step in the ICO
        assert.equal(gnusTokenEthBalance, 1000 * gnusTokenBalance, 'Library function returned unexpected function, linkage may be broken');
    });
    it('should send GNUS token correctly', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();

        // Setup 2 accounts.
        const accountOne = accounts[0];
        const accountTwo = accounts[1];

        // Get initial balances of first and second account.
        const accountOneStartingBalance = (await gnusTokenInstance.getBalance(accountOne)).toNumber();
        const accountTwoStartingBalance = (await gnusTokenInstance.getBalance(accountTwo)).toNumber();

        // Make transaction from first account to second.
        const amount = 10;
        await gnusTokenInstance.sendCoin(accountTwo, amount, { from: accountOne });

        // Get balances of first and second account after the transactions.
        const accountOneEndingBalance = (await gnusTokenInstance.getBalance(accountOne)).toNumber();
        const accountTwoEndingBalance = (await gnusTokenInstance.getBalance(accountTwo)).toNumber();

        assert.equal(accountOneEndingBalance, accountOneStartingBalance - amount, "Amount wasn't correctly taken from the sender");
        assert.equal(accountTwoEndingBalance, accountTwoStartingBalance + amount, "Amount wasn't correctly sent to the receiver");
    });
});