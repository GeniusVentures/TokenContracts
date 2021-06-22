const geniusAI = artifacts.require("geniusAI");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("geniusAI", function (/* accounts */) {
  it("should assert true", async function () {
    await geniusAI.deployed();
    return assert.isTrue(true);
  });
});
