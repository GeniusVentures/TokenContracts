# Architecture

**Analysis Date:** 2026-06-06

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────┐
│                     Diamond Proxy (EIP-2535)                          │
│  GeniusDiamond / ProxyDiamond                                         │
│  `gnus-ai/contracts/gnus-ai/GeniusDiamond.sol`                       │
│  `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ProxyDiamond.sol`      │
├────────────┬──────────────┬──────────────┬──────────────┬────────────┤
│  Diamond-  │  GNUSNFT-    │  GNUSBridge  │  ERC1155-    │  ERC20-    │
│  CutFacet  │  Factory     │              │  ProxyOper-  │  Transfer- │
│            │              │              │  ator        │  Batch     │
├────────────┼──────────────┼──────────────┼──────────────┼────────────┤
│  Diamond-  │  GNUS-       │  GNUS-       │  Diamond-    │  Genius-   │
│  Loupe-    │  Control     │  Withdraw-   │  InitFacet   │  Ownership-│
│  Facet     │              │  Limiter     │              │  Facet      │
├────────────┼──────────────┼──────────────┼──────────────┼────────────┤
│  GNUSNFT-  │  GNUS-       │  ERC20Proxy  │              │            │
│  Collection│  Contract-   │  Facet       │              │            │
│  Name      │  Assets      │  (proxy)     │              │            │
└────────────┴──────────────┴──────────────┴──────────────┴────────────┘
         │                │
         ▼                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    Storage Layer (Diamond Pattern)                     │
│  Each facet uses dedicated storage slots via keccak256("namespace")   │
│  `gnus-ai/contracts/gnus-ai/GNUSNFTFactoryStorage.sol`               │
│  `gnus-ai/contracts/gnus-ai/GNUSControlStorage.sol`                  │
│  `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiterStorage.sol`          │
│  `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyStorage.sol` │
└──────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Underlying Token Standards: ERC-1155 (primary) + ERC-20 (dual)       │
│  `openzeppelin-contracts-diamond/contracts/token/ERC1155/`           │
│  `openzeppelin-contracts-diamond/contracts/token/ERC20/`             │
└──────────────────────────────────────────────────────────────────────┘
```

## Architecture Pattern

**Overall:** EIP-2535 Diamond Proxy (multi-facet upgradeable proxy)

The GNUS ecosystem uses the Diamond Standard for modular, upgradeable smart contracts. Two distinct diamond deployments exist:

| Diamond | Base Contract | Purpose |
|---------|-------------|---------|
| GeniusDiamond | `gnus-ai/contracts/gnus-ai/GeniusDiamond.sol` | Main GNUS token ecosystem -- ERC-1155 factory, bridge, control, limiter |
| ProxyDiamond | `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ProxyDiamond.sol` | ERC-20 view/transfer facade over one ERC-1155 child token ID |

**Key Characteristics:**
- All state is stored in library-managed structs accessed via deterministic slots (`keccak256("namespace")`)
- Facets are the functional units, deployed independently and registered via `diamondCut`
- Protocol versioning is managed via `GNUSControlStorage.protocolVersion` (currently v2.5)
- Upgrade paths track `fromVersions` in diamond config files to ensure safe faceted upgrades
- Access control uses OpenZeppelin AccessControlEnumerable via the `GeniusAccessControl` abstract base

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| GeniusDiamond | Diamond proxy base, registers IERC1155+IERC165+IDiamondCut+IDiamondLoupe | `gnus-ai/contracts/gnus-ai/GeniusDiamond.sol` |
| ProxyDiamond | Diamond proxy base for ERC-20 wrapper, registers IERC20 | `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ProxyDiamond.sol` |
| DiamondCutFacet | Add/replace/remove facets (EIP-2535 cut operations) | `openzeppelin-contracts-diamond/contracts/proxy/...` |
| DiamondLoupeFacet | Facet introspection (EIP-2535 loupe) | `openzeppelin-contracts-diamond/contracts/proxy/...` |
| DiamondInitFacet | Initialization orchestrator, sets up roles and limiter defaults | `gnus-ai/contracts/gnus-ai/DiamondInitFacet.sol` |
| GNUSNFTFactory | ERC-1155 token creation, hierarchical parent/child IDs, minting with burn-on-mint for direct GNUS children | `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` |
| GNUSBridge | Mint/burn bridge operations, child-token withdrawal to GNUS, cross-chain burn events, ERC-20 dual interface for GNUS | `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` |
| GNUSControl | Protocol security -- global/token-specific transfer bans, bridge fee, chain ID, protocol version | `gnus-ai/contracts/gnus-ai/GNUSControl.sol` |
| GNUSWithdrawLimiter | Administrative facet for withdrawal rate limiting config | `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiter.sol` |
| GNUSWithdrawLimiterStorage | Rate limiter engine -- bin-based aggregation, time-window limits, per-account config | `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiterStorage.sol` |
| ERC1155ProxyOperator | Proxy operator approval (bypass NFT_PROXY_OPERATOR_ROLE), totalSupply/creators views | `gnus-ai/contracts/gnus-ai/ERC1155ProxyOperator.sol` |
| ERC20TransferBatch | Batch mint/transfer/burn of ERC-20-like GNUS tokens via ERC-1155 balances | `gnus-ai/contracts/gnus-ai/ERC20TransferBatch.sol` |
| GNUSERC1155MaxSupply | Supply enforcement, pausable transfers, burnable tokens, ban checks, limiter hook | `gnus-ai/contracts/gnus-ai/GNUSERC1155MaxSupply.sol` |
| GeniusAccessControl | Role-based access control (DEFAULT_ADMIN_ROLE, UPGRADER_ROLE, MINTER_ROLE, CREATOR_ROLE) with superAdmin protection | `gnus-ai/contracts/gnus-ai/GeniusAccessControl.sol` |
| GeniusOwnershipFacet | EIP-173 ownership transfer with role migration | `gnus-ai/contracts/gnus-ai/GeniusOwnershipFacet.sol` |
| GNUSContractAssets | Super admin withdrawal of accidentally sent ERC-20/ETH (prevents GNUS withdrawal) | `gnus-ai/contracts/gnus-ai/GNUSContractAssets.sol` |
| GNUSNFTCollectionName | NF collection name constant ("Genius NFT Collection") | `gnus-ai/contracts/gnus-ai/GNUSNFTCollectionName.sol` |
| ERC20ProxyFacet | ERC-20 view/transfer facade over one ERC-1155 child token (proxy-specific) | `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyFacet.sol` |
| GeniusTokens | Legacy ERC-20 ITO contract (separate deployment, pre-diamond) | `gnus-token/contracts/GeniusTokens.sol` |

## Layers

**Diamond Proxy Layer:**
- Purpose: Request routing from single deployment address to facet implementations via `delegatecall`
- Location: `gnus-ai/contracts/gnus-ai/GeniusDiamond.sol` (main), `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ProxyDiamond.sol` (proxy)
- Contains: Constructor that registers base interfaces (IERC1155, IERC165, IDiamondCut, IDiamondLoupe), depends on `LibDiamond` for storage
- Depends on: `contracts-starter/contracts/Diamond.sol`, `openzeppelin-contracts-diamond`

**Facet Layer:**
- Purpose: Business logic deployed as independent contracts registered on the diamond
- Location: `gnus-ai/contracts/gnus-ai/*.sol`, `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyFacet.sol`
- Contains: All application logic -- token factory, bridge, control, limiter, proxy facade
- Depends on: Diamond proxy routing, storage libraries, OpenZeppelin upgradeable contracts

**Storage Layer:**
- Purpose: Diamond-compatible storage using deterministic `keccak256` slots to avoid collisions between facets
- Location: `gnus-ai/contracts/gnus-ai/GNUSNFTFactoryStorage.sol`, `GNUSControlStorage.sol`, `GNUSWithdrawLimiterStorage.sol`, `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyStorage.sol`
- Contains: `Library.Layout` structs with assembly slot accessors
- Used by: All facets

**OpenZeppelin Diamond Foundation:**
- Purpose: Upgradeable ERC-1155, ERC-20, access control, security primitives adapted for diamond storage
- Location: `openzeppelin-contracts-diamond/contracts/token/`, `openzeppelin-contracts-diamond/contracts/access/`
- Contains: ERC1155Upgradeable, ERC1155SupplyUpgradeable, ERC1155BurnableUpgradeable, IERC20Upgradeable, ERC20Storage, AccessControlEnumerableUpgradeable, PausableUpgradeable
- Depends on: Diamond storage pattern (every storage variable is in a library Layout struct)

**Transpiler Tool:**
- Purpose: Source-to-source transformation of OpenZeppelin contracts into diamond-compatible upgradeable forms, and Solidity version upgrades (0.6.x to 0.8.x)
- Location: `openzeppelin-transpiler/src/`
- Contains: TypeScript-based AST transformer
- Used by dev workflow only, not at runtime

## Data Flow

### Primary Flow: Minting a Direct Child Token (Burn/Mint Model)

1. Creator/Admin calls `GNUSNFTFactory.mint(to, id, amount)` (`gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol:115`)
2. `beforeMint()` checks creator/admin permission, verifies `id != GNUS_TOKEN_ID` (`GNUSNFTFactory.sol:98`)
3. If `(id >> 128) == GNUS_TOKEN_ID` (direct GNUS child), calculates `convAmount = amount * exchangeRate` and burns that amount of GNUS from caller (`GNUSNFTFactory.sol:102-106`)
4. `_mint()` creates child tokens via ERC-1155 mint hook (`GNUSNFTFactory.sol:118`)
5. `_beforeTokenTransfer` in `GNUSERC1155MaxSupply` enforces max supply, pause state, and ban checks (`gnus-ai/contracts/gnus-ai/GNUSERC1155MaxSupply.sol:40-73`)

### Primary Flow: Withdrawing Child Token to GNUS (Burn/Mint Reversal)

1. User calls `GNUSBridge.withdraw(amount, id)` (`gnus-ai/contracts/gnus-ai/GNUSBridge.sol:149`)
2. Validates token created, not GNUS itself, user has balance (`GNUSBridge.sol:151-153`)
3. Reads `exchangeRate` from NFT storage -- requirement: `amount >= exchangeRate` (`GNUSBridge.sol:156-157`)
4. Calculates `convAmount = amount / exchangeRate` (NFTs per GNUS) (`GNUSBridge.sol:160`)
5. Checks withdrawal limiter for non-super-admin (`GNUSBridge.sol:163-165`)
6. Burns child tokens (`_burn(sender, id, amount)`) (`GNUSBridge.sol:167`)
7. Mints GNUS tokens to sender with bridge fee applied (`_mintWithBridgeFee`) (`GNUSBridge.sol:168`)

### Bridge Out Flow (Cross-Chain via Burn + Event)

1. User calls `GNUSBridge.bridgeOut(amount, id, destChainID)` (`gnus-ai/contracts/gnus-ai/GNUSBridge.sol:177`)
2. Validates token created, user has balance, `destChainID` != current chainID (`GNUSBridge.sol:179-182`)
3. Burns the tokens on source chain (`_burn(sender, id, amount)`) (`GNUSBridge.sol:183`)
4. Emits `BridgeSourceBurned(sender, id, amount, srcChainID, destChainID)` for off-chain relayers to observe (`GNUSBridge.sol:184-189`)
5. No on-chain lock/release -- relies on off-chain relayers to observe event and call `mint()` on destination

### ERC-20 Proxy Flow (ERC-1155 Child as ERC-20)

1. Proxy is initialized with one ERC-1155 contract address and one `childTokenId` (`erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyFacet.sol:25-37`)
2. `totalSupply()` / `balanceOf()` read live from the underlying ERC-1155 contract (`ERC20ProxyFacet.sol:67-80`)
3. `transfer()` calls `safeTransferFrom` on ERC-1155 for the configured child ID (`ERC20ProxyFacet.sol:88-93`)
4. `approve()` maps to ERC-1155 `setApprovalForAll` (all-or-nothing, not amount-specific) (`ERC20ProxyFacet.sol:111-114`)
5. `transferFrom()` requires ERC-1155 operator approval, then calls `safeTransferFrom` (`ERC20ProxyFacet.sol:124-129`)

### Withdrawal Rate Limiter Flow

1. `checkAndRecordWithdraw(account, amount)` is called from both `GNUSBridge.withdraw()` and `ERC20TransferBatch._transferBatch()` and `GNUSERC1155MaxSupply._beforeTokenTransfer()`
2. If limiter is disabled globally, returns immediately (`GNUSWithdrawLimiterStorage.sol:187-189`)
3. Creates bin array on first withdrawal with account-specific or default config (`GNUSWithdrawLimiterStorage.sol:196-201`)
4. Zeros expired bins (lazy cleanup via timestamp comparison) (`GNUSWithdrawLimiterStorage.sol:205`)
5. Sums active bins and checks `activeTotal + amount <= limitAmount` (`GNUSWithdrawLimiterStorage.sol:208-213`)
6. Records withdrawal in the current bin with timestamp (`GNUSWithdrawLimiterStorage.sol:217-221`)
7. Super admin bypasses all limiter checks

## Hierarchical ERC-1155 Token ID System

**ID Encoding:**
Token IDs are `uint256` values split into two `uint128` halves:
- **Upper 128 bits:** Parent token ID (shifted left by 128)
- **Lower 128 bits:** Child index within parent

```text
parentID << 128 | childCurIndex++
```

The root token GNUS has `tokenID = 0` (`GNUS_TOKEN_ID` constant in `gnus-ai/contracts/gnus-ai/GNUSConstants.sol:29`).
A direct child of GNUS would be: `(0 << 128) | 0 = 0 | 0 = 0` -- IDs 1, 2, 3... are the actual direct children.
A grandchild token under child ID 5 would be: `(5 << 128) | 0`.

**Parent detection:** `(id >> 128) == GNUS_TOKEN_ID` checks if a token is a direct child of GNUS.

**Known architectural issue:** Deep hierarchies (child of a child of a child) can produce ID collisions because `(id >> 128)` on a composite ID discards the upper 128 bits. The current code does not check `!NFTs[newTokenID].nftCreated` before overwriting.

## The Burn/Mint Model (Current, Pre-Planned Update)

The current model for economic backing of child tokens is implicit and burn/mint-based:

```
Mint child token (direct GNUS child):
  Child mint happens
  + GNUS is burned from the minter (amount * exchangeRate)

Withdraw child token:
  Child token is burned
  + GNUS is minted to the withdrawer (amount / exchangeRate)
```

**Asymmetry:**
- `beforeMint()` only burns GNUS for direct GNUS children (checked via `(id >> 128) == GNUS_TOKEN_ID`)
- `withdraw()` allows any created non-GNUS token to be redeemed for GNUS if it has `exchangeRate > 0`
- This means deeply nested descendants can be minted without GNUS burn but redeemed for GNUS

**No per-token treasury:** The `NFT` struct stores `exchangeRate` and `maxSupply` but no reserve balance or backing ledger.

## State Management

All persistent state uses the diamond-compatible storage pattern:
- State is defined in `library XxxStorage { struct Layout { ... } }`
- Accessed via `layout()` functions using inline assembly with `keccak256` slot constants
- Storage is shared across all facets deployed on the same diamond

**Key storage layouts:**

| Storage Library | Slot Hash | Data |
|----------------|-----------|------|
| `GNUSNFTFactoryStorage` | `keccak256("gnus.ai.nft.factory.storage")` | `mapping(uint256 => NFT)` -- token metadata |
| `GNUSControlStorage` | `keccak256("gnus.ai.control.storage")` | Ban lists, bridge fee, protocol version, chain ID |
| `GNUSWithdrawLimiterStorage` | `keccak256("gnus.ai.withdraw.limiter.storage")` | Account states, configs, defaults, enabled flag |
| `ERC1155Storage` | (OpenZeppelin) | Balances, operator approvals |
| `ERC1155SupplyStorage` | (OpenZeppelin) | Total supply per token ID |
| `ERC20Storage` | (OpenZeppelin) | Allowances for ERC-20 compatibility |
| `ERC20ProxyStorage` | `keccak256("erc20.proxy.storage")` | ERC-1155 contract reference, child ID, name, symbol |

## Key Abstractions

**NFT Struct:**
- Purpose: Metadata and economic parameters for each token in the ERC-1155 hierarchy
- Defined in: `gnus-ai/contracts/gnus-ai/GNUSNFTFactoryStorage.sol:10-19`
- Fields: `name`, `symbol`, `uri`, `exchangeRate`, `maxSupply`, `creator`, `childCurIndex` (uint128), `nftCreated`
- Pattern: Stored in `mapping(uint256 => NFT)` inside the diamond storage layout

**GeniusAccessControl:**
- Purpose: Unified role-based access control across all facets
- Defined in: `gnus-ai/contracts/gnus-ai/GeniusAccessControl.sol`
- Roles: `DEFAULT_ADMIN_ROLE`, `UPGRADER_ROLE`, `MINTER_ROLE` (in GNUSBridge), `CREATOR_ROLE` (in GNUSNFTFactory), `NFT_PROXY_OPERATOR_ROLE` (in ERC1155ProxyOperator)
- Inherits: `AccessControlEnumerableUpgradeable`
- Key constraint: Super admin (diamond contract owner) cannot renounce or be revoked from `DEFAULT_ADMIN_ROLE`

**GNUSERC1155MaxSupply:**
- Purpose: Shared base contract for all ERC-1155 facets providing supply enforcement, pausing, burning, ban checks, and limiter integration
- Defined in: `gnus-ai/contracts/gnus-ai/GNUSERC1155MaxSupply.sol`
- Inherits: `ERC1155SupplyUpgradeable`, `PausableUpgradeable`, `ERC1155BurnableUpgradeable`
- Hooks `_beforeTokenTransfer` to enforce all transfer-time checks

**WithdrawBin + AccountState:**
- Purpose: Time-windowed withdrawal rate limiting using bin-based aggregation
- Defined in: `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiterStorage.sol:14-32`
- Default: 100,000 GNUS per day, 24 hourly bins
- Pattern: `(currentTime - baseTimestamp) / binLengthSeconds % binCount`

## Entry Points

**Diamond Proxy Entry Point:**
- Location: `gnus-ai/contracts/gnus-ai/GeniusDiamond.sol` (constructor) or deployed address
- Triggers: Any external call to the diamond address
- Responsibilities: Routes calls to the correct facet via `delegatecall` based on function selector in `LibDiamond.DiamondStorage.facets` mapping

**Facet Initialization:**
- Location: `gnus-ai/contracts/gnus-ai/DiamondInitFacet.sol` -- `diamondInitialize250()`
- Triggers: Called during diamond deployment as `deployInit` or during upgrades as `upgradeInit`
- Responsibilities: Sets up admin/minter/upgrader roles, registers ERC-20 interface support, initializes withdrawal limiter defaults

**Token Factory Initialization:**
- Location: `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` -- `GNUSNFTFactory_Initialize()`
- Triggers: Diamond deploy init or `GNUSNFTFactory_Initialize230()` for upgrades
- Responsibilities: Creates GNUS token (ID 0) with name, symbol, URI, exchange rate 1.0, max supply 50M

**Mint Entry Points:**
- `GNUSNFTFactory.mint(to, id, amount, data)` -- mints child tokens (burns GNUS for direct children)
- `GNUSNFTFactory.mintBatch(to, ids[], amounts[], data)` -- batch version
- `GNUSBridge.mint(user, amount)` -- privileged GNUS mint (MINTER_ROLE)
- `GNUSBridge.mint(user, tokenID, amount)` -- privileged ERC-1155 mint (MINTER_ROLE)
- `ERC20TransferBatch.mintBatch(destinations[], amounts[])` -- batch GNUS mint (DEFAULT_ADMIN_ROLE)

**Withdraw/Burn Entry Points:**
- `GNUSBridge.withdraw(amount, id)` -- child token to GNUS redemption
- `GNUSBridge.bridgeOut(amount, id, destChainID)` -- cross-chain burn + event
- `GNUSBridge.burn(user, amount)` -- privileged GNUS burn (MINTER_ROLE)

**Admin Entry Points:**
- `GNUSControl.*` -- manage bans, bridge fee, chain ID, protocol version
- `GNUSWithdrawLimiter.*` -- manage withdrawal limit config
- `GeniusOwnershipFacet.transferOwnership(_newOwner)` -- transfer contract ownership
- `GNUSNFTFactory.createNFT(parentID, ...)` / `createNFTs(parentID, ...)` -- create new child tokens under a parent

## Architectural Constraints

- **Threading/Concurrency:** Not applicable -- Solidity/EVM is single-threaded. No reentrancy guards beyond OpenZeppelin defaults. The withdrawal limiter uses `block.timestamp` for time-based limits.
- **Global state:** All state is in diamond storage slots. The diamond `contractOwner` stored in `LibDiamond.DiamondStorage` is a singleton that governs all admin operations.
- **Circular imports:** Not detected in Solidity source. Facets import storage libraries but storage libraries do not import facets.
- **Upgradeability:** All contracts use the diamond standard for upgradeability. Version tracking via `GNUSControlStorage.protocolVersion`. Legacy `gnus-token/contracts/GeniusTokens.sol` is non-upgradeable standard ERC-20.
- **Solidity version:** All current contracts use `^0.8.19`. Legacy `gnus-token` uses `^0.8.0`.

## Anti-Patterns

### Asymmetric Burn/Mint Backing

**What happens:** `beforeMint()` only burns GNUS for direct GNUS children (`(id >> 128) == GNUS_TOKEN_ID`), but `withdraw()` allows any non-GNUS created token to be redeemed for GNUS as long as `exchangeRate > 0`.
**Why it's wrong:** A grandchild token can be minted without burning GNUS, then later withdrawn to receive real GNUS. This creates an unbacked GNUS mint path.
**Do this instead:** Store explicit backing per token ID (reserve balance). Only allow withdrawal/redeem for tokens with documented backing. Alternatively, mirror the same parent-check in `withdraw()`. See `.planning/Update-Smart-Contracts-Architecture.md` for the planned treasury/reserve model fix.

### Inconsistent Exchange Rate Semantics

**What happens:** `beforeMint()` uses `amount * exchangeRate` (multiplication) while `withdraw()` uses `amount / exchangeRate` (division).
**Why it's wrong:** If `exchangeRate` means "child token units per 1 GNUS," mint should divide by it (not multiply). If it means "GNUS per 1 child unit," withdraw should multiply by it (not divide). Having opposing operations means one direction is always wrong.
**Do this instead:** Decide whether exchangeRate means "child per GNUS" or "GNUS per child," use the same formula in both directions, use fixed-point math, and enforce `amount % exchangeRate == 0` or equivalent divisibility checks.

### ERC-20 Approve Maps to ERC-1155 setApprovalForAll (Proxy)

**What happens:** `ERC20ProxyFacet.approve()` calls `erc1155Contract.setApprovalForAll(spender, amount > 0)`, making it all-or-nothing instead of amount-specific.
**Why it's wrong:** ERC-20 allowances are amount-specific. Any DEX or router expecting normal ERC-20 approval behavior will receive unexpected results. Additionally, ERC-1155 `setApprovalForAll` grants operator approval across ALL token IDs, not just the proxied child ID.
**Do this instead:** Implement real ERC-20 allowance storage in the proxy (using ERC20Storage pattern). Do not map ERC-20 approve to ERC-1155 setApprovalForAll.

### Hierarchical ID Collision Risk

**What happens:** Child IDs are computed as `(parentID << 128) | nft.childCurIndex++` without checking `!NFTs[newTokenID].nftCreated`.
**Why it's wrong:** For nested hierarchies beyond two levels, a left shift by 128 on a composite ID discards upper bits, making collisions possible across different branches.
**Do this instead:** Either restrict depth to one level, or check `require(!NFTs[newTokenID].nftCreated)` before assignment, or use a different hierarchy encoding.

### Bridge Burns Tokens (No Lock/Release)

**What happens:** `bridgeOut()` burns tokens and emits an event; off-chain relayers observe and call `mint()` on the destination chain.
**Why it's wrong:** This requires privileged mint access on the destination. The total global supply changes during bridging. A compromised relayer or exploited destination mint function could create unbacked tokens.
**Do this instead:** Use lock/release model: lock tokens in a bridge vault on source, release pre-funded tokens from a vault on destination. Never mint/burn for bridging. See `.planning/Update-Smart-Contracts-Architecture.md` for the planned lock/release bridge architecture.

## Error Handling

**Strategy:** Solidity `require()` statements with descriptive string messages. No custom error types beyond `GNUSContractAssets` which defines `ErrorWithdrawingEther()` and `CannotWithdrawGNUS()`.

**Patterns:**
- Access control: `require(hasRole(...), "message")` or `onlySuperAdminRole` / `onlyRole(...)` modifiers
- Input validation: `require(id != GNUS_TOKEN_ID, "message")`, `require(balanceOf(sender, id) >= amount, "Insufficient tokens.")`
- State validation: `require(nft.nftCreated, "Token not created.")`, `require(exchangeRate > 0, "Exchange rate...")`
- Supply enforcement: `require(totalSupply(id) <= ..., "Max Supply for NFT would be exceeded")`
- Error handling in the withdrawal limiter uses explicit `revert("Withdrawal limit exceeded for time window")`

## Cross-Cutting Concerns

**Logging:** Standard Solidity `event` emissions. Key events: `Transfer`, `TransferSingle`, `TransferBatch`, `BridgeSourceBurned`, `WithdrawRecorded`, `WithdrawLimiterTriggered`, `AddToBlackList`, `RemoveFromBlackList`, `UpdateBridgeFee`, `InitLog`.

**Validation:** Multi-layered: (1) Modifier-based access control (roles, super admin), (2) Require-based input validation in each function, (3) `_beforeTokenTransfer` hook for centralized transfer-time checks (paused, banned, max supply, limiter).

**Authentication:** Role-based via OpenZeppelin `AccessControlEnumerableUpgradeable`. Primary roles: `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, `CREATOR_ROLE`, `UPGRADER_ROLE`, `NFT_PROXY_OPERATOR_ROLE`. Diamond contract owner (`LibDiamond.diamondStorage().contractOwner`) has elevated privileges: bypasses limiter, cannot be revoked from admin, sole caller of `onlySuperAdminRole` functions.

---

*Architecture analysis: 2026-06-06*
