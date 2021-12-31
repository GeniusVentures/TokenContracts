// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


/// @custom:security-contact support@gnus.ai
contract PolyGNUSToken is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, PausableUpgradeable,
    ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable
{
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");


    // Reserve Currency/Token Name
    string private constant GNUS_NAME = "Genius Tokens";
    // Reserve Currency/Token Symbol
    string private constant GNUS_SYMBOL = "GNUS";
    uint256 public constant GNUS_DECIMALS = 10 ** 18;
    uint256 public constant GNUS_MAX_SUPPLY = 50000000 * GNUS_DECIMALS;  // 50 million tokens
    string private constant GNUS_URI = "https://nft.gnus.ai/{id}";
    uint256 public GNUS_TOKEN_ID = 0;
    address superAdmin;

    uint256 public NFTCurIndex = GNUS_TOKEN_ID + 1;         // can be either token or NFT starts from ID 1

    struct Token {
        string name;
        string symbol;
        uint256 exchangeRate;
        uint256 maxSupply;      // maximum supply of tokens
        string uri;             // custom URI for child token base
        address owner;          // the creator of the token
        bool tokenCreated;      // if there is a mapping/token created
    }

    struct ChildNFT {
        uint256 parentID;           // the parent token of this NFT
        uint256 maxSupply;      // maximum supply of tokens
        string uri;             // custom URI for child token base
        bool nftCreated;        // if the NFT was created
    }

    // unique ID for Token to extra data for tokens
    mapping(uint256 => Token) Tokens;

    // unique ID for ChildNFTs with parent Token
    mapping(uint256 => ChildNFT) ChildNFTs;

    // let's reserve some space of upgrades as a base contract
    uint256 private _reserved1;
    uint256 private _reserved2;
    uint256 private _reserved3;

    string private _reserved4;
    string private _reserved5;
    string private _reserved6;

    bytes32 public constant _reserved7 = keccak256("RESERVED7");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function __PolyGNUSToken_init() initializer internal {
        __ERC1155_init("");
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        createToken(GNUS_NAME, GNUS_SYMBOL, 1.0 * GNUS_DECIMALS, GNUS_MAX_SUPPLY, GNUS_URI);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
        Tokens[GNUS_TOKEN_ID].uri = newuri;
    }

    function setURI(string memory newuri, uint256 id) public onlyRole(MINTER_ROLE) {

        address operator = _msgSender();
        require(Tokens[id].tokenCreated, "Base Token must have been created to set the URI for");
        require((Tokens[id].owner == operator) || hasRole(DEFAULT_ADMIN_ROLE, operator), "Only Admin or Owner can set URI of Token");
        Tokens[id].uri = newuri;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {

        if (Tokens[id].tokenCreated) {
            return Tokens[id].uri;
        } else {
            require(ChildNFTs[id].nftCreated, "Token or NFT must already be created to get the URI for it");
            return Tokens[ChildNFTs[id].parentID].uri;
        }
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }


    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlyRole(MINTER_ROLE) {

        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        // if minting a token, then have to have on deposit (GNUS tokens / conversion)
        // tokens to mint them and be the owner
        if (Tokens[id].tokenCreated) {
            require((operator == Tokens[id].owner) || hasRole(DEFAULT_ADMIN_ROLE, operator), "Owner or Admin can only mint tokens");
            uint256 convAmount = amount * Tokens[id].exchangeRate;
            _burn(operator, GNUS_TOKEN_ID, convAmount);
        } else {
            require(ChildNFTs[id].nftCreated, "Token ID doesn't match any precreated Token, so nothing to mint");
            require((Tokens[ChildNFTs[id].parentID].owner == operator) || hasRole(DEFAULT_ADMIN_ROLE, operator), "caller must be Admin or Owner of parent token of NFT");
        }

        _mint(account, id, amount, data);

    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external
        onlyRole(MINTER_ROLE) {

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (Tokens[id].tokenCreated) {
                require((operator == Tokens[id].owner) || hasRole(DEFAULT_ADMIN_ROLE, operator), "Owner or Admin can only mint tokens");
                uint256 convAmount = amounts[i] * Tokens[id].exchangeRate;
                // if minting any child token, then have to have on deposit (GNUS tokens / conversion),
                // tokens to mint them and be the owner
                _burn(operator, GNUS_TOKEN_ID, convAmount);
            }
        }

        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids,
        uint256[] memory amounts, bytes memory data) internal whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool) {

        return super.supportsInterface(interfaceId);
    }

    function _createToken(address owner, string memory name, string memory symbol, uint256 exchRate, uint256 max_supply,
        string memory newuri) internal {

        Tokens[NFTCurIndex++] = Token({name : name, symbol : symbol, exchangeRate : exchRate, maxSupply : max_supply, uri : newuri, owner : owner, tokenCreated : true});

    }

    // create new token that will be the base token for other NFTs
    function createToken(string memory name, string memory symbol, uint256 exchRate, uint256 max_supply,
        string memory newuri) public onlyRole(MINTER_ROLE) {

        _createToken(_msgSender(), name, symbol, exchRate, max_supply, newuri);
    }

    // Admin create new token that will be the base token for other NFTs
    function createToken(address owner, string memory name, string memory symbol, uint256 exchRate, uint256 max_supply,
        string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {

        _createToken(owner, name, symbol, exchRate, max_supply, newuri);
    }

    // create a sub NFT for an existing parent Token
    function createNFT(uint256 parentID, uint256 max_supply, string memory newuri) external onlyRole(MINTER_ROLE) {

        address operator = _msgSender();
        require(Tokens[parentID].tokenCreated, "Parent token should have been created first");
        require((Tokens[parentID].owner == operator) || hasRole(DEFAULT_ADMIN_ROLE, operator), "Caller must be Admin or Owner of parent Token to create MFTs");
        ChildNFTs[NFTCurIndex++] = ChildNFT({parentID: parentID, maxSupply: max_supply, uri: newuri, nftCreated: true});
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    // The following functions are for the Ethereum -> Polygon Bridge for GNUS Tokens
    // Deposit ERC20 Tokens
    function deposit(address user, bytes calldata depositData) external onlyRole(PROXY_ROLE) {

        uint256 amount = abi.decode(depositData, (uint256));

        require(totalSupply(GNUS_TOKEN_ID) + amount <= GNUS_MAX_SUPPLY, "Minting this amount would exceed max supply of tokens");

        // `amount` token getting minted here & equal amount got locked in RootChainManager
        _mint(user, GNUS_TOKEN_ID, amount, "");

        // emit ERC20 Transfer notification
        emit Transfer(address(0), user, amount);
    }

    // withdraw ERC 20 tokens (GNUS Tokens)
    function withdraw(uint256 amount) public {

        address operator = _msgSender();

        _burn(operator, GNUS_TOKEN_ID, amount);

        // emit ERC20 Transfer notification
        emit Transfer(operator, address(0), amount);

    }

    // this will withdraw a child token to a GNUS Token on the Ethereum network
    function withdraw(uint256 amount, uint256 id) external {

        address operator = _msgSender();

        require(Tokens[id].tokenCreated, "This token can't be withdrawn, as it hasn't been created yet!");
        // first burn the child createToken
        require(balanceOf(operator, id) >= amount, "Not enough child tokens to withdraw");
        uint256 convAmount = Tokens[id].exchangeRate / amount;
        _burn(operator, id, amount);
        _mint(operator, GNUS_TOKEN_ID, convAmount, "");

        withdraw(convAmount);
    }

    function _mintChildToken(address operator, uint256 id, uint256 amount, address to) internal {

        require(balanceOf(operator, id) + amount <= Tokens[id].maxSupply, "Conversion would exceed Max Supply of Child Token");
        uint256 convAmount = Tokens[id].exchangeRate * amount;
        // this will assert with underflow
        _burn(operator, GNUS_TOKEN_ID, convAmount);
        _mint(to, id, amount, "");
    }



}

