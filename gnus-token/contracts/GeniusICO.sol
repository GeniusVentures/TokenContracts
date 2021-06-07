
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GeniusICO {

    uint256 public soldTokens = 0;
    uint256[] public rates = [1000, 800, 640, 512];
    uint256[] public stageEndsAt = [12500000*1e18,22500000*1e18,30500000*1e18,36900000*1e18];

    function getCurrentStage() internal view returns(uint8) {
        uint8 stage;
        for (stage = 0; stage < stageEndsAt.length; stage++) {
            if (soldTokens < stageEndsAt[stage]) {
                break;
            }
        }
        return stage;
    }

function calcTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        uint8 stage = getCurrentStage();
        uint256 tokenAmount = 0;
        uint256 remainingWeiAmount = weiAmount;
        uint256 curTokensSold = soldTokens;
        while ((remainingWeiAmount != 0) && (stage < stageEndsAt.length)) {
            uint256 remainingTokensInStage = (stageEndsAt[stage] - curTokensSold);
            uint256 tokensSoldInStage = (remainingWeiAmount * rates[stage]);
            uint256 valueSold;
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
        // don't let user buy rest of tokens, sent to much ETH
        require(remainingWeiAmount == 0, "Not enough tokens left for ETH sent!");
        return tokenAmount;
    } 
}

