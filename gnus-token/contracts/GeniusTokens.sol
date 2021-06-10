// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GeniusTokens is Ownable, ERC20 {
    // modify token name
    string private constant NAME = "Genius Tokens";
    // modify token symbol
    string private constant SYMBOL = "GNUS";
    uint256 public constant DECIMALS = 10 ** 18;
    // ICO data
    uint256 public GNUSSoldTokens = 0;
    uint256 public weiReceived = 0;
    uint256[] public rates = [1000, 800, 640, 512];
    uint256[] public stageEndsAtWei = [12500 * DECIMALS,25000 * DECIMALS,37500 * DECIMALS,50000 * DECIMALS];
    uint8 internal stage = 0;
    uint256 public constant INIT_SUPPLY = 7380000 * DECIMALS;  // 7.38 million tokens
    uint256 public constant ICO_SUPPLY = 36900000 * DECIMALS;  // 36.9 million tokens
    uint256 public constant MAX_SUPPLY = 50000000 * DECIMALS;  // 50 million tokens

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

    function GNUSBalance() public view returns(uint256) {
        return GNUSSoldTokens;
    }

    function ETHBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function WEIReceived() public view returns(uint256) {
        return weiReceived;
    }

    // owner can withdraw eth to any address
    function withdrawETH(address _address, uint256 _amount) external onlyOwner {
        require(_amount < ETHBalance(), "Not enough eth balance");
        address payable to = payable(_address);
        to.transfer(_amount);
    }

    // Detect receiving eth
    receive () external payable {
        // Check GNUS token before receive ETH
        require(msg.value > 0, "You have sent 0 ether!");
        uint256 tokenAmount = calcTokenAmount(msg.value);
        require(GNUSSoldTokens <= ICO_SUPPLY, "ERC20Capped: cap exceeded");
        _mint(address(msg.sender), tokenAmount);
    }

    // Withdraw GNUS tokens
    function withdrawGNUS(address to, uint256 amount) external onlyOwner {
        require(to == address(to),"Invalid address");
        uint256 tokenAmount = amount;
        require(GNUSBalance() >= tokenAmount, "You are trying to withdraw too many GNUS tokens");
        IERC20(address(this)).transfer(address(to), tokenAmount);
    }

    // this is the function to scale the ICO with early adopters getting better deals.
    function calcTokenAmount(uint256 weiAmount) internal returns(uint256) {
        uint256 curWeiReceived = weiReceived;
        uint256 remainingWeiAmount = weiAmount;
        uint256 GNUSTokenAmount = 0;
        uint8 curStage = stage;
        while ((remainingWeiAmount != 0) && (curStage < stageEndsAtWei.length)) {
            uint256 weiLeftInStage = stageEndsAtWei[curStage] - curWeiReceived;
            uint256 WeiToUse = (weiLeftInStage <  remainingWeiAmount) ? weiLeftInStage : remainingWeiAmount;
            GNUSTokenAmount += (WeiToUse * rates[curStage]);
            remainingWeiAmount -= WeiToUse;
            curWeiReceived += WeiToUse;
            if (remainingWeiAmount != 0) {
                curStage++;
            }
    }

    require(remainingWeiAmount == 0, 'To Much Ethereum Sent');

    stage = curStage;
    weiReceived = curWeiReceived;
    GNUSSoldTokens += GNUSTokenAmount;
    return GNUSTokenAmount;
    }
}
