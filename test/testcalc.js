

var soldTokens = 0;
var rates = [1000, 800, 640, 512];
var stageEndsAt = [12500000*1e18, 22500000*1e18, 305000000*1e18, 36900000*1e18];

var soldTokens = calcTokenAmount(12501*1e18);

console.log('soldTokens amount is: ' + soldTokens.toFixed().toString());

function getCurrentStage() {
    var stage;
    for (stage = 0; stage < stageEndsAt.length; stage++) {
        if (soldTokens < stageEndsAt[stage]) {
            break;
        }
    }
    return stage;
}

function calcTokenAmount(weiAmount) {
    var stage = getCurrentStage();
    var tokenAmount = 0;
    var remainingWeiAmount = weiAmount;
    var curTokensSold = soldTokens;
    while ((remainingWeiAmount != 0) && (stage < stageEndsAt.length)) {
        var remainingTokensInStage = (stageEndsAt[stage] - curTokensSold);
        var tokensSoldInStage = (remainingWeiAmount * rates[stage]);
        var valueSold;
        if (tokensSoldInStage > remainingTokensInStage) {
            tokensSoldInStage = remainingTokensInStage;
            valueSold = (tokensSoldInStage / rates[stage]);
            stage++;
        } else {
            valueSold = (tokensSoldInStage / rates[stage]);
        }
        tokenAmount += tokensSoldInStage;
        curTokensSold += tokensSoldInStage;
        remainingWeiAmount -= valueSold;
    }
    return tokenAmount;
}
