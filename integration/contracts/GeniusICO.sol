
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GeniusICO is Ownable {

    uint256 public soldTokens = 0;
    uint256[] public rates = [1000, 800, 640, 512];
    // precompute this to simplify calculations
    uint256[] public tokensOnStage=[12500*1000,12500*800,12500*640,12500*512];
    uint256[] public stageStartsAt=[0,12500000,22500000,30500000,36900000];
    function gnusBalance() public view returns(uint256) {
        return IERC20(address(this)).balanceOf(address(this));
    }

    // Detect receiving eth
    receive () external payable {
        // Check gnus token before receive eth
        require(msg.value > 0, "You have sent 0 ether!");
        uint256 tokenAmount = calcTokenAmount(msg.value);
        require(gnusBalance() >= tokenAmount, "You have sent too much eth amount");
        soldTokens += tokenAmount;
        IERC20(address(this)).transfer(address(msg.sender), tokenAmount);
    }

    function getCurrentStage() public view returns(uint256) {
        uint256 step = 0;
        for (uint256 i = 0; i < stageStartsAt.length; i++) {
            if (soldTokens<stageStartsAt[i]) {
                step = i;
                break;
            }
        }
        return step;
    }

    function calcTokenAmount(uint256 ethAmount) private view returns(uint256) {
        uint256 stage= getCurrentStage();
        uint256 tokenAmount = 0;
        uint256 remainingEthAmount = ethAmount;
        bool capExceeded=false;
        while(remainingEthAmount!=0 && !capExceeded){
            uint256 nextStage=stageStartsAt[stage+1];
            uint256 remainingTokensInStage=nextStage-soldTokens;
            uint256 tokensSoldInStage=(remainingEthAmount*rates[stage])/10**18;
            if(tokensSoldInStage>remainingTokensInStage){
                // if we sold more than left in the current stage , and its last stage , we reached cap
                if(stage==3){
                    capExceeded=true;
                }
                tokensSoldInStage=remainingTokensInStage;
            }
            tokenAmount+=tokensSoldInStage;
            uint256 valueSold=(tokensSoldInStage*1e18)/rates[stage];
            remainingEthAmount-=valueSold;
        }
    } 
}

