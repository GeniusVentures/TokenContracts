
const BN = require('BN.js');

const DECIMALS = new BN("10")**new BN(18);
var GNUSSoldTokens = new BN(0) * DECIMALS;
var weiReceived = new BN(0) * DECIMALS
var rates = [new BN(1000), new BN(800), new BN(640), new BN(512)];
var stageEndsAtWei = [new BN(12500) * DECIMALS, new BN(25000) * DECIMALS,
    new BN(37500) * DECIMALS, new BN(50000) * DECIMALS];
var stage = 0;

console.log('Decimal places should be 1e18 : ' + DECIMALS.toString());

var testValue = calcTokenAmount(new BN(12501) * DECIMALS);

console.log('GNUS Tokens sold is: ' + testValue.toString() +
    ' Total GNUS Tokens: ' + GNUSSoldTokens.toString() + ' stage: ' + stage.toString());

// should throw assertion, but we want to continue.
testValue = calcTokenAmount(new BN(50000) * DECIMALS);

// go up to 49,999 ETH now
testValue = calcTokenAmount(new BN(37498) * DECIMALS);
console.log('GNUS Tokens sold is: ' + testValue.toString() +
    ' Total GNUS Tokens: ' + GNUSSoldTokens.toString() + ' stage: ' + stage.toString());

// go up to 50,000 ETH now
testValue = calcTokenAmount(new BN(1) * DECIMALS);
console.log('GNUS Tokens sold is: ' + testValue.toString() +
    ' Total GNUS Tokens: ' + GNUSSoldTokens.toString() + ' stage: ' + stage.toString());

if (weiReceived != stageEndsAtWei[stageEndsAtWei.length-1]) {
    console.log('Wei Received ' + weiReceived.toString() +
        ' does to equal max wei to sell: ' + stageEndsAtWei[stageEndsAtWei.length - 1].toString()
        + ' stage: ' + stage.toString());
}

weiReceived = new BN(0) * DECIMALS;
GNUSSoldTokens = new BN(0) * DECIMALS;
stage = 0;

testValue = calcTokenAmount(new BN(50000) * DECIMALS)

console.log('GNUS Tokens sold is: ' + testValue.toString() +
    ' Total GNUS Tokens: ' + GNUSSoldTokens.toString() + ' stage: ' + stage.toString());

console.log('End of Tests');

function calcTokenAmount(weiAmount) {
    var curWeiReceived = weiReceived;
    var remainingWeiAmount = weiAmount;
    var GNUSTokenAmount = new BN(0) * DECIMALS;
    var curStage = stage;
    while ((remainingWeiAmount != 0) && (curStage < stageEndsAtWei.length)) {
        var weiLeftInStage = stageEndsAtWei[curStage] - curWeiReceived;
        var WeiToUse = (weiLeftInStage <  remainingWeiAmount) ? weiLeftInStage : remainingWeiAmount;
        GNUSTokenAmount += (WeiToUse * rates[curStage]);
        remainingWeiAmount -= WeiToUse;
        curWeiReceived += WeiToUse;
        if (remainingWeiAmount != 0) {
            curStage++;
        }
    }

    if (remainingWeiAmount != 0) {
        console.log('To Much Ethereum Sent: ' + weiAmount.toString() +
            ' remaining ' + remainingWeiAmount.toString());
        return new BN(0) * DECIMALS;
    }
    stage = curStage;
    weiReceived = curWeiReceived;
    GNUSSoldTokens += GNUSTokenAmount;
    return GNUSTokenAmount;
}
