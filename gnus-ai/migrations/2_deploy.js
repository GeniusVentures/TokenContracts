const GeniusAI = artifacts.require('GeniusAI');

const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
    const instance = await deployProxy(GeniusAI, { deployer });
    console.log('Deployed', instance.address);
}

