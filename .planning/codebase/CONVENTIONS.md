# Coding Conventions

**Analysis Date:** 2026-06-06

## Solidity Versions

The project uses three different Solidity pragma versions across its contract groups:

| Version | Used In | Files |
|---------|---------|-------|
| `^0.8.0` | Legacy ICO token | `gnus-token/contracts/GeniusTokens.sol` |
| `^0.8.2` | ERC20 proxy contracts | `erc20-gnus-proxy/contracts/erc20-gnus-proxy/*.sol`, `erc20-gnus-proxy/contracts/gnus-ai/*.sol` |
| `^0.8.19` | Main diamond ecosystem (gnus-ai) | `gnus-ai/contracts/gnus-ai/*.sol` and all test files |

**Guidance:** New contracts go in the gnus-ai diamond ecosystem and must use `pragma solidity ^0.8.19;`.

## Naming Patterns

### Contracts and Libraries
- **Contracts:** PascalCase. Examples: `GeniusDiamond`, `GeniusAccessControl`, `GeniusOwnershipFacet`, `GNUSNFTFactory`, `GNUSWithdrawLimiter`, `GNUSContractAssets`, `ERC1155ProxyOperator`, `GNUSERC1155MaxSupply`, `GNUSBridge`, `GNUSNFTCollectionName`, `ProxyDiamond`, `ERC20ProxyFacet`, `DiamondInitFacet`
- **Libraries:** PascalCase. Examples: `GNUSWithdrawLimiterStorage`, `GNUSControlStorage`, `GNUSNFTFactoryStorage`, `ERC20ProxyStorage`, `TransferHelper`
- **Abstract contracts:** PascalCase. Factored for shared logic. Example: `GeniusAccessControl` (abstract)

### Functions
- **Internal/private functions:** camelCase with leading underscore. Examples: `_mintWithBridgeFee()`, `_beforeTokenTransfer()`, `_setupInitialBalances()`, `_grantMinterRole()`
- **Public/external functions:** camelCase without underscore. Examples: `transferOwnership()`, `getAccountConfig()`, `setDefaultLimitAmount()`, `createNFT()`, `mint()`, `withdrawToken()`
- **Initialization functions:** PascalCase with underscore convention. Examples: `GNUSNFTFactory_Initialize()`, `GNUSNFTFactory_Initialize230()`, `GNUSBridge_Initialize()`, `diamondInitialize250()`, `initializeERC20Proxy()`
- **Internal init functions:** camelCase with double-underscore prefix (OZ-style). Examples: `__GeniusAccessControl_init()`, `__GeniusAccessControl_init_unchained()`
- **View functions for state queries:** Use `get` prefix. Examples: `getAccountConfig()`, `getWithdrawLimiterConfig()`, `getAccountWithdrawStatus()`, `getNFTInfo()`
- **Boolean queries:** Use `is` prefix or descriptive names. Examples: `isApprovedForAll()`, `isBannedTransferor()`, `supportsInterface()`

### State Variables and Constants
- **Public constants (roles):** UPPER_SNAKE_CASE. Examples: `MINTER_ROLE`, `UPGRADER_ROLE`, `DEFAULT_ADMIN_ROLE`, `CREATOR_ROLE`, `PAUSER_ROLE`, `NFT_PROXY_OPERATOR_ROLE`
- **Global constants:** UPPER_SNAKE_CASE. Defined in `GNUSConstants.sol`. Examples: `GNUS_NAME`, `GNUS_SYMBOL`, `GNUS_DECIMALS`, `GNUS_MAX_SUPPLY`, `GNUS_TOKEN_ID`, `GNUS_URI`, `MAX_UINT128`, `PARENT_MASK`, `CHILD_MASK`, `ETHER`
- **Private constants:** UPPER_SNAKE_CASE. Examples: `FEE_DOMINATOR` (in `GNUSBridge.sol`), `NAME`, `SYMBOL` (in `GeniusTokens.sol`)
- **Immutable state variables:** camelCase. Examples: `superAdmin`, `weiReceived`, `GNUSSoldTokens`
- **Storage position constants:** UPPER_SNAKE_CASE with descriptive suffix. Examples: `GNUS_WITHDRAW_LIMITER_STORAGE_POSITION`, `GNUS_CONTROL_STORAGE_POSITION`, `GNUS_NFT_FACTORY_STORAGE_POSITION`
- **Function parameters:** Inconsistent. The older `GeniusTokens.sol` does not use underscore prefixes. The gnus-ai contracts sometimes use leading underscore (`_newOwner`, `_contractOwner`) and sometimes not. Prefer leading underscore for constructor/init parameters to distinguish from state variables.

### Files
- Contract files: PascalCase matching contract name. Examples: `GeniusDiamond.sol`, `GNUSWithdrawLimiter.sol`, `GNUSNFTFactoryStorage.sol`
- Test files: `{Name}.t.sol`. Examples: `GNUSUnit.t.sol`, `DiamondAccessControl.t.sol`, `ERC20Fuzz.t.sol`
- Test file prefixes indicate test type: `*Fuzz.t.sol`, `*Invariant.t.sol` for fuzz/invariant tests. Standard `*Test.t.sol` or `*.t.sol` for unit/integration.

### Structs
- Storage layout structs: PascalCase, named `Layout`. Examples: `GNUSWithdrawLimiterStorage.Layout`, `GNUSControlStorage.Layout`, `GNUSNFTFactoryStorage.Layout`
- Domain structs: PascalCase. Examples: `NFT`, `WithdrawBin`, `AccountConfig`, `AccountState`

### Events
- PascalCase, past-tense or descriptive. Examples: `WithdrawLimiterConfigUpdated`, `AccountConfigUpdated`, `BridgeSourceBurned`, `WithdrawToken`, `WithdrawRecorded`, `WithdrawLimiterTriggered`

## Code Style

### Formatting
- **Tool:** Foundry's built-in `forge fmt`
- Config in `gnus-ai/foundry.toml`:
  - `line_length = 120`
  - `tab_width = 4`
  - `bracket_spacing = true`
  - `int_types = "long"` (uses `uint256` not `uint`)
  - `multiline_func_header = "all"`
  - `quote_style = "double"`
  - `number_underscore = "thousands"`
  - `wrap_comments = true`

### Linting
- **Solhint:** Config at `gnus-ai/.solhint.json`
  - Extends `solhint:recommended`
  - `compiler-version` enforced to `^0.8.0`
  - `func-visibility` warns on missing visibility (ignores constructors)
  - `gnus-ai/.solhintignore` excludes `node_modules`
- **Slither:** Config at `gnus-ai/slither.config.json`
  - Excludes informational, optimization, and low-severity findings
  - Reports medium and high findings
  - Filter paths: excludes `node_modules`, `artifacts`, `cache`, test directories, `flat/`
  - Run via `yarn slither:scan` or `yarn slither:check` (checklist format)

### SPDX Headers
Every contract file starts with `// SPDX-License-Identifier: MIT`.

### Documentation
- **Doxygen/Natspec style** used in gnus-ai contracts (`/// @notice`, `/// @dev`, `/// @param`, `/// @return`)
- `/// @custom:security-contact support@gnus.ai` tag on security-critical contracts
- Required tags per function: `@notice` (description), `@dev` (implementation details), `@param` (for each parameter), `@return` (for each return value)
- Multi-line doc comments use `/** */` blocks for contract-level documentation; single-line `///` for function-level

### Bracing
- Opening braces on the same line as the declaration -- NOT Allman style. Examples from the codebase:
  ```solidity
  function transferOwnership(address _newOwner) external override {
  contract GeniusDiamond is Diamond, ERC165StorageUpgradeable {
  ```

## Import Organization

### Import Styles
Two import styles are used, sometimes mixed in the same file:

1. **Path-based imports:**
   ```solidity
   import "@gnus.ai/contracts-upgradeable-diamond/access/AccessControlUpgradeable.sol";
   import "contracts-starter/contracts/libraries/LibDiamond.sol";
   ```

2. **Named imports (ES module style):**
   ```solidity
   import { LibDiamond } from "contracts-starter/contracts/libraries/LibDiamond.sol";
   import { GeniusDiamondTestBase } from "../base/GeniusDiamondTestBase.sol";
   ```

### Import Resolution (Remappings)
Defined in `gnus-ai/foundry.toml`:
| Remapping | Path |
|-----------|------|
| `@gnus.ai/` | `node_modules/@gnus.ai/` |
| `@openzeppelin/` | `node_modules/@openzeppelin/` |
| `contracts-starter/` | `node_modules/contracts-starter/` |
| `@diamondslab/` | `node_modules/@diamondslab/` |
| `@helpers/` | `test/foundry/helpers/` |
| `forge-std/` | `lib/forge-std/src/` |

### Import Order
No enforced order convention observed. Typical grouping: (1) diamond infrastructure imports, (2) access control imports, (3) token standard imports, (4) local project imports. Recommend grouping by dependency layer.

## Error Handling

### Primary Pattern: `require()` with String Messages
The dominant pattern across all contracts. Every require has a human-readable error message.

```solidity
require(LibDiamond.diamondStorage().contractOwner == msg.sender, "Only SuperAdmin allowed");
require(binCount > 0, "Bin count must be greater than 0");
require(nft.nftCreated, "NFT must have been created to set the URI for");
require(id != GNUS_TOKEN_ID, "Shouldn't mint GNUS tokens tokens, only deposit and withdraw");
```

### Custom Errors (Solc 0.8.4+)
Limited adoption. Only used in `GNUSContractAssets.sol`:
```solidity
error ErrorWithdrawingEther();
error CannotWithdrawGNUS();
```
Used with `revert` statement:
```solidity
if (token == address(this)) {
    revert CannotWithdrawGNUS();
}
```

### Revert without require
Used in `GNUSWithdrawLimiterStorage.sol` for the rate limit enforcement:
```solidity
revert("Withdrawal limit exceeded for time window");
```

### Short Error Codes (TransferHelper)
The `TransferHelper.sol` library uses terse two-character error codes:
```solidity
require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');   // SafeApprove
require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');   // SafeTransfer
require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');  // SafeTransferFrom
require(success, 'STE');  // SafeTransferETH
```
This is a gas-optimization pattern -- short revert strings cost less gas.

### Guidance for New Code
- Use `require()` with descriptive messages as the primary pattern (matches existing convention)
- Custom errors are acceptable for gas-sensitive paths
- Do NOT use the terse two-character error codes outside of transfer helper utilities

## Access Control Patterns

### Role-Based Access Control
The project uses OpenZeppelin's `AccessControlEnumerableUpgradeable` (diamond-compatible variant from `@gnus.ai/contracts-upgradeable-diamond`).

**Defined Roles:**
| Role | Hash | Purpose |
|------|------|---------|
| `DEFAULT_ADMIN_ROLE` | `0x00` | Top-level admin. Can grant/revoke all other roles. |
| `MINTER_ROLE` | `keccak256("MINTER_ROLE")` | Can mint tokens via bridge |
| `PAUSER_ROLE` | `keccak256("PAUSER_ROLE")` | Can pause/unpause token transfers |
| `UPGRADER_ROLE` | `keccak256("UPGRADER_ROLE")` | Can perform diamond upgrades (facet cuts) |
| `CREATOR_ROLE` | `keccak256("CREATOR_ROLE")` | Can create new NFT collections |
| `NFT_PROXY_OPERATOR_ROLE` | `keccak256("NFT_PROXY_OPERATOR_ROLE")` | Auto-approved operator for gas-free listings |

### Super Admin Guard
The `GeniusAccessControl.sol` abstract contract adds a `onlySuperAdminRole` modifier that checks the diamond's contract owner (stored in `LibDiamond.DiamondStorage.contractOwner`). The super admin identity is tied to the EIP-173 diamond owner, NOT to the `DEFAULT_ADMIN_ROLE`.

```solidity
modifier onlySuperAdminRole {
    require(LibDiamond.diamondStorage().contractOwner == msg.sender, "Only SuperAdmin allowed");
    _;
}
```

### Super Admin Protection
Both `renounceRole()` and `revokeRole()` are overridden to prevent removing `DEFAULT_ADMIN_ROLE` from the contract owner:
```solidity
function renounceRole(bytes32 role, address account) public virtual override {
    require(
        !(hasRole(DEFAULT_ADMIN_ROLE, account) && (LibDiamond.diamondStorage().contractOwner == account)),
        "Cannot renounce superAdmin from Admin Role"
    );
    super.renounceRole(role, account);
}
```

### Role Granting Pattern
When granting roles in facet initialization:
```solidity
function __GeniusAccessControl_init_unchained() internal onlyInitializing {
    address superAdmin = _msgSender();
    _grantRole(DEFAULT_ADMIN_ROLE, superAdmin);
    _grantRole(UPGRADER_ROLE, superAdmin);
}
```

### Ownership Transfer
`GeniusOwnershipFacet.transferOwnership()` updates the diamond owner AND migrates roles from old owner to new owner:
```solidity
function transferOwnership(address _newOwner) external override {
    LibDiamond.enforceIsContractOwner();
    LibDiamond.setContractOwner(_newOwner);
    _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
    _grantRole(UPGRADER_ROLE, _newOwner);
    if (msg.sender != _newOwner) {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(UPGRADER_ROLE, msg.sender);
    }
}
```

### Legacy Access Control (GeniusTokens.sol)
The old ICO contract uses standard OZ `AccessControl` with custom modifiers:
```solidity
modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins.");
    _;
}
```
This contract also tracks a separate `superAdmin` address for additional guard on `renounceRole`/`revokeRole`.

## Storage Patterns

### EIP-2535 Diamond Storage
All gnus-ai contracts use the diamond storage pattern. Each module defines a storage library with:
1. A `Layout` struct containing all state variables
2. A `keccak256` storage position constant
3. A `layout()` function using inline assembly to access the slot

**Template:**
```solidity
library MyModuleStorage {
    struct Layout {
        // state variables here
    }

    bytes32 constant MY_MODULE_STORAGE_POSITION = keccak256("gnus.ai.my.module.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MY_MODULE_STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }
}
```

**Storage Position Naming Convention:** `keccak256("gnus.ai.<module>.<purpose>.storage")`

**Registered Storage Modules:**
| Library | Storage Slot Hash | File |
|---------|-------------------|------|
| `GNUSWithdrawLimiterStorage` | `keccak256("gnus.ai.withdraw.limiter.storage")` | `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiterStorage.sol` |
| `GNUSControlStorage` | `keccak256("gnus.ai.control.storage")` | `gnus-ai/contracts/gnus-ai/GNUSControlStorage.sol` |
| `GNUSNFTFactoryStorage` | `keccak256("gnus.ai.nft.factory.storage")` | `gnus-ai/contracts/gnus-ai/GNUSNFTFactoryStorage.sol` |
| `ERC20ProxyStorage` | `keccak256("erc20.proxy.storage")` | `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyStorage.sol` |

**Usage Pattern in Contracts:**
Contracts use `using Library for Library.Layout` and access storage via `Library.layout()`:
```solidity
contract GNUSWithdrawLimiter is GeniusAccessControl {
    function setDefaultLimitAmount(uint256 limitAmount) external onlySuperAdminRole {
        GNUSWithdrawLimiterStorage.Layout storage l = GNUSWithdrawLimiterStorage.layout();
        l.defaultLimitAmount = limitAmount;
    }
}
```

### Upgrade Pattern
The project uses the EIP-2535 Diamond Standard (multi-facet proxy). Key characteristics:
- `GeniusDiamond.sol` is the proxy entry point, inheriting from `Diamond` (contracts-starter) and `ERC165StorageUpgradeable`
- Facets are separate contracts deployed independently, then added/removed via `diamondCut()`
- Initialization uses OZ `Initializable` pattern with a twist: `InitializableStorage.layout()._initialized = false` is set after init to allow re-initialization across upgrades
- Versioned init functions (e.g., `GNUSNFTFactory_Initialize230()`, `diamondInitialize250()`) allow staged upgrades

### Constants File
`GNUSConstants.sol` serves as the single source of truth for token parameters:
- `GNUS_NAME`, `GNUS_SYMBOL`, `GNUS_DECIMALS`, `GNUS_MAX_SUPPLY`
- `GNUS_TOKEN_ID = 0` (the ERC1155 token ID for the main GNUS ERC20-compatible token)
- Bitmask constants for parent/child token ID encoding: `PARENT_MASK`, `CHILD_MASK`, `MAX_UINT128`
- `ETHER` sentinel address: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`

## Math and Rate Handling

### Token ID Encoding
Token IDs encode parent-child relationships using bit packing:
- Upper 128 bits: parent token ID
- Lower 128 bits: child index
- `PARENT_MASK = uint256(MAX_UINT128) << 128`
- `CHILD_MASK = MAX_UINT128`
- Child of GNUS check: `(id >> 128) == GNUS_TOKEN_ID`

### Decimal Handling
All tokens use 18 decimals. `GNUS_DECIMALS = 10 ** 18`. Amounts are expressed in wei (raw token units).

### Exchange Rate Math
NFT-to-GNUS exchange rates stored in `NFT.exchangeRate`. When minting a child NFT of GNUS:
```solidity
uint256 convAmount = amount * nft.exchangeRate;
require(balanceOf(sender, GNUS_TOKEN_ID) >= convAmount, "Not enough GNUS_TOKEN to burn");
_burn(sender, GNUS_TOKEN_ID, convAmount);
```
The multiplier `exchangeRate` converts NFT amount to equivalent GNUS amount for burning.

### Bridge Fee Calculation
```solidity
uint256 private constant FEE_DOMINATOR = 1000;
// In _mintWithBridgeFee:
amount = (amount * (FEE_DOMINATOR - bridgeFee)) / FEE_DOMINATOR;
```
Fee is expressed in basis points relative to 1000. Safe against overflow due to Solidity 0.8.x built-in checks.

### Legacy ICO Math (GeniusTokens.sol)
The legacy contract uses a staged pricing model with `rates[]` and `stageEndsAtWei[]` arrays:
```solidity
uint256[] public rates = [1000, 800, 640, 512];
```
Each stage has a wei cap. Tokens are calculated as `WeiToUse * rates[curStage]`.

## Module Design

### Contract Structure
- **Facets:** Deployed as standalone contracts, serve as logic implementations for diamond proxy. Examples: `GeniusOwnershipFacet`, `GNUSWithdrawLimiter`, `ERC1155ProxyOperator`
- **Abstract base contracts:** Provide shared logic inherited by facets. Example: `GeniusAccessControl`
- **Storage libraries:** Contain all state layout and state-accessing logic. Example: `GNUSWithdrawLimiterStorage`
- **Utility libraries:** Stateless helper functions. Example: `TransferHelper`

### Inheritance
Deep inheritance is common due to OZ upgradeable contract chains:
```solidity
contract GNUSBridge is Initializable, GNUSERC1155MaxSupply, GeniusAccessControl, IERC20Upgradeable {
```
```solidity
contract GNUSERC1155MaxSupply is ERC1155SupplyUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable {
```

### `using` Statements
`using Library for Library.Layout` is the standard pattern for storage library usage:
```solidity
using GNUSNFTFactoryStorage for GNUSNFTFactoryStorage.Layout;
using GNUSControlStorage for GNUSControlStorage.Layout;
using ERC20ProxyStorage for ERC20ProxyStorage.Layout;
```

## Function Design

### Modifiers
Used for access control and state guards. Defined in the contract or inherited:
```solidity
modifier onlySuperAdminRole { ... }
modifier onlyOwnerRole { ... }
modifier onlyAdmin { ... }
modifier onlyMinter { ... }
```

### Function Visibility
- Public functions use `public` (not `external`) even when only called externally, unless gas optimization is critical
- Internal helpers prefix with underscore: `_mintWithBridgeFee()`, `_beforeMint()`
- Test files use both `public` and `external` for test/handler functions

### Return Value Naming
Named return values are common, with trailing underscore convention:
```solidity
function owner() external override view returns (address owner_) {
    owner_ = LibDiamond.contractOwner();
}
```

---

*Convention analysis: 2026-06-06*
