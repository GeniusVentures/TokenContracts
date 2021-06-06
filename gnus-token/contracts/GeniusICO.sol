
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GeniusICO {

    uint256 public soldTokens = 0;
    uint256[] public rates = [1000, 800, 640, 512];
    uint256[] public stageStartsAt=[0,12500000,22500000,30500000,36900000];

    function getCurrentStage() internal view returns(uint256) {
        uint256 step = 0;
        for (uint256 i = 0; i < stageStartsAt.length; i++) {
            if (soldTokens > stageStartsAt[i]) {
                step = i;
                break;
            }
        }
        return step;
    }

    function calcTokenAmount(uint256 ethAmount) internal view returns(uint256) {
        uint256 stage= getCurrentStage();
        uint256 tokenAmount = 0;
        uint256 remainingEthAmount = ethAmount;
        bool capExceeded = false;
        while (remainingEthAmount !=0 && !capExceeded) {
            uint256 nextStage = stageStartsAt[stage+1];
            uint256 remainingTokensInStage = (nextStage - soldTokens)*10**18;
            uint256 tokensSoldInStage = (remainingEthAmount*rates[stage]);
            if (tokensSoldInStage > remainingTokensInStage){
                // if we sold more than left in the current stage , and its last stage , we reached cap
                if (stage == rates.length){
                    capExceeded = true;
                }
                tokensSoldInStage = remainingTokensInStage;
            }
            tokenAmount += tokensSoldInStage;
            uint256 valueSold = (tokensSoldInStage / rates[stage]);
            remainingEthAmount -= valueSold;
        }
        require(!capExceeded, "Not enough tokens left for ETH sent!");
        return tokenAmount;
    } 
}

