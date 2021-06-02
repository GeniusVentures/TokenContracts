
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GeniusICO is Ownable {

    uint256 public soldTokens = 0;
    uint256[] public limits = [12500 * 10 ** 18, 12500 * 10 ** 18, 12500 * 10 ** 18, 12500 * 10 ** 18];
    uint256[] public rates = [1000, 800, 640, 512];

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

    function defineStep() public view returns(uint256) {
        uint256 step = 3;
        for (uint256 i = 0; i < limits.length - 1; i++) {
            if (limits[i] * rates[i] > soldTokens) {
                step = i;
                break;
            }
        }
        return step;
    }

    function calcTokenAmount(uint256 ethAmount) private view returns(uint256) {
        uint256 step = defineStep();
        uint256 tokenAmount = 0;
        uint256 step0 = limits[0] * rates[0];  // 1000
        uint256 step1 = limits[1] * rates[1];  // 800
        uint256 step2 = limits[2] * rates[2];  // 640
        if (step == 0) {
            // first step
            if ((soldTokens + ethAmount * rates[0]) <= step0) tokenAmount = ethAmount * rates[0];
            else {
                tokenAmount += step0 - soldTokens;
                uint256 remainedETH = ethAmount - uint256(tokenAmount / rates[0]);
                if (remainedETH <= limits[1]) {
                    tokenAmount += remainedETH * rates[1];
                } else if (remainedETH > limits[1] && remainedETH <= limits[1] + limits[2]) {
                    tokenAmount += step1 + (remainedETH - limits[1]) * rates[2];
                } else {
                    tokenAmount += step1 + step2 + (remainedETH - limits[1] - limits[2]) * rates[3];
                }
            }
        } else if (step  == 1) {
            // second step
            if ((soldTokens + ethAmount * rates[1] - step0) <= step1) tokenAmount = ethAmount * rates[1];
            else {
                tokenAmount = step0 + step1 - soldTokens;
                uint256 remainedETH = ethAmount - uint256(tokenAmount / rates[1]);
                if (remainedETH <= limits[2]) {
                    tokenAmount += remainedETH * rates[2];
                } else {
                    tokenAmount += step2 + (remainedETH - limits[2]) * rates[3];
                }
            }
        } else if (step  == 2) {
            // third step
            if ((soldTokens + ethAmount * rates[0] - step0 - step1) <= step2) tokenAmount = ethAmount * rates[2];
            else {
                tokenAmount = step0 + step1 + step2 - soldTokens;
                uint256 remainedETH = ethAmount - uint256(tokenAmount / rates[2]);
                tokenAmount += remainedETH * rates[3];
            }
        } else {
            // the last step
            tokenAmount = ethAmount * rates[3];  // 512
        }
        return tokenAmount;
    }

    /**
    e.g. [[12500, 1000], [12500, 800], [12500, 640], [12500, 512]]
    limits = [12500, 12500, 12500, 12500]
    rates = [1000, 800, 640, 512]
    */
    function dynamicConvTable(uint256[][] memory convTable) external onlyOwner {
        require(convTable.length == 4, "Invalid data");
        for (uint256 i = 0; i < convTable.length; i++) {
            require(convTable[i].length == 2 && convTable[i][0] > 0 && convTable[i][1] > 0, "Invalid data item");
        }
        for (uint256 j = 0; j < convTable.length; j++) {
            limits[j] = convTable[j][0];
            rates[j] = convTable[j][1];
        }
    }

}

