// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GeniusTokens is Ownable, ERC20 {
    // modify token name
    string private constant NAME = "Genius Tokens";
    // modify token symbol
    string private constant SYMBOL = "GNUS";
    // modify token decimal
    uint8 private constant DECIMALS = 18;

    uint256 public constant INIT_SUPPLY = 5000000 * (10**uint256(DECIMALS)); // 5 million tokens
    uint256 public constant MAX_SUPPLY = 50000000 * (10**uint256(DECIMALS)); // 50 million tokens

    mapping (address => bool) _minters;
    mapping (address => bool) _burners;

    uint256 public soldTokens = 0;
    uint256[] public limits = [12500 * 10 ** 18, 12500 * 10 ** 18, 12500 * 10 ** 18, 12500 * 10 ** 18];
    uint256[] public rates = [1000, 800, 640, 512];

    constructor () ERC20(NAME, SYMBOL) {
         _mint(msg.sender, INIT_SUPPLY);
    }

    function isMinter(address account) public view returns(bool) {
        return _minters[account];
    }

    function addMinter(address account) public onlyOwner {
        _minters[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
        _minters[account] = false;
    }

    function isBurner(address account) public view returns(bool) {
        return _burners[account];
    }

    function addBurner(address account) public onlyOwner {
        _burners[account] = true;
    }

    function removeBurner(address account) public onlyOwner {
        _burners[account] = false;
    }

    function mint(uint256 amount) public {
        require(isMinter(msg.sender), "You are not registered as a minter");
        require(IERC20(address(this)).totalSupply() + amount <= MAX_SUPPLY, "ERC20Capped: cap exceeded");
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public {
        require(isBurner(msg.sender), "You are not registered as a burner");
        _burn(msg.sender, amount);
    }

    function gnusBalance() public view returns(uint256) {
        return IERC20(address(this)).balanceOf(address(this));
    }

    function ethBalance() public view returns(uint256) {
        return address(this).balance;
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

    // owner can withdraw eth to any address
    function withdrawETH(address _address, uint256 _amount) external onlyOwner {
        require(_amount < ethBalance(), "Not enough eth balance");
        address payable to = payable(_address);
        to.transfer(_amount);
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

    // Withdraw GNUS tokens
    function withdrawGNUS(address to, uint256 amount) external onlyOwner {
        require(to == address(to),"Invalid address");
        uint256 tokenAmount = amount;
        require(gnusBalance() >= tokenAmount, "You have sent too much eth amount");
        IERC20(address(this)).transfer(address(to), tokenAmount);
    }
}
