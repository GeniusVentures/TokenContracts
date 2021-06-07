const GeniusTokens = artifacts.require("GeniusTokens");
const BN = require('bn.js');

contract('GeniusTokens', (accounts) => {

    // default 1 ether / wei
    const WeiToEth = new BN(web3.utils.toWei('1'));

    it('should put 7380000 GNUS Tokens in the first account', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        const balance = web3.utils.fromWei(await gnusTokenInstance.balanceOf(accounts[0]));

        assert.equal(balance, "7380000", "7380000 wasn't in the first account");
    });

    var testSendEth = it('should give us 1,000 GNUS tokens for 1 ETH sent to smart contract', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();

        // this should give us some GNUS tokens to account[0]
        await gnusTokenInstance.sendTransaction({ from: accounts[1], value: web3.utils.toWei('1'), gas: 100000, gasPrice: 20 });

        // now grab the balance of accounts[0] and make sure they have 1,000 GNUS tokens
        const act0GNUSAmount = (await gnusTokenInstance.balanceOf(accounts[1])).div(WeiToEth);


        assert(act0GNUSAmount.eq(new BN(1000)), 'Genius Tokens Balance should equal 1,000 but is ' + act0GNUSAmount.toString());
    });

    it('should make sure ETH added is equal to minted GNUS * ICO steps', async () => {
        const gnusTokenInstance = await GeniusTokens.deployed();
        // have to wait until one transaction is done
        await testSendEth;

        const gnusSoldTokens = (await gnusTokenInstance.gnusBalance()).div(WeiToEth);
        const gnusTokenEthBalance = (await gnusTokenInstance.ethBalance()).div(WeiToEth).mul(new BN(1000));

        assert(gnusSoldTokens.eq(gnusTokenEthBalance),
            'Eth Token Balance * 1000 (' + gnusTokenEthBalance.toString() + ') is not equal to GNUS tokens sold: ' + gnusSoldTokens.toString());

    });
    var transferTest=it('should send GNUS token correctly', async () => {
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
        console.log("this test will fail if ganache isn't started with the account balance option set above 12,5K ether");
        await transferTest;

        // send 12,500 ETH , This should push it 1 eth into the 2nd stage

        const gnusTokenInstance = await GeniusTokens.deployed();
        await gnusTokenInstance.sendTransaction({ from: accounts[0], value: web3.utils.toWei('12500'), gas: 500000, gasPrice: 20 });
        // The amount of tokens sold now should be 12,500,000 in 1 stage +  800
        const expectedTokens=new BN("12500800");

        //  tokens sold
        const gnusSoldTokens = (await gnusTokenInstance.gnusBalance()).div(WeiToEth);

        assert(gnusSoldTokens.eq(expectedTokens),"Sold tokens ("+gnusSoldTokens.toString() +") not equal to expected amount 12,500,800")
    });
});