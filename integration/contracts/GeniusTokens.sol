// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GeniusICO.sol";

contract GeniusTokens is Ownable, ERC20, GeniusICO {
    // modify token name
    string private constant NAME = "Genius Tokens";
    // modify token symbol
    string private constant SYMBOL = "GNUS";
    // modify token decimal
    uint8 private constant DECIMALS = 18;

    uint256 public constant INIT_SUPPLY = 7380000 * (10**uint256(DECIMALS)); // 7.38 million tokens
    uint256 public constant ICO_SUPPLY = 36900000 * (10**uint256(DECIMALS));  // 36.9 million tokens
    uint256 public constant MAX_SUPPLY = 50000000 * (10**uint256(DECIMALS)); // 50 million tokens

    mapping (address => bool) _minters;
    mapping (address => bool) _burners;

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
        require(soldTokens + tokenAmount <= ICO_SUPPLY, "ERC20Capped: cap exceeded");
        _mint(address(msg.sender), tokenAmount);
        soldTokens += tokenAmount;
    }

    // Withdraw GNUS tokens
    function withdrawGNUS(address to, uint256 amount) external onlyOwner {
        require(to == address(to),"Invalid address");
        uint256 tokenAmount = amount;
        require(gnusBalance() >= tokenAmount, "You have sent too much eth amount");
        IERC20(address(this)).transfer(address(to), tokenAmount);
    }
}
