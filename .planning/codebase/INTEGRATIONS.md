# External Integrations

**Analysis Date:** 2026-06-06

## Blockchain Interaction

### Contract Architecture

The system is a multi-contract token ecosystem built on the **EIP-2535 Diamond Standard**, organized as:

1. **GeniusDiamond** (`gnus-ai/contracts/gnus-ai/GeniusDiamond.sol`) - The core diamond that hosts all GNUS token logic. Implements ERC-1155, ERC-20 (via bridge), access control, NFT factory, and bridge functionality through facet delegation.
2. **ProxyDiamond** (`erc20-gnus-proxy/contracts/erc20-gnus-proxy/ProxyDiamond.sol`) - A separate diamond providing an ERC-20 interface wrapper around a single ERC-1155 child token.
3. **GeniusTokens** (`gnus-token/contracts/GeniusTokens.sol`) - The original standalone ERC-20 ICO contract (pre-diamond, deployed independently via Truffle).

### Active Networks

Deployments exist or are configured for:

| Network | Chain ID | Purpose |
|---------|---------|---------|
| Ethereum Mainnet | 1 | Production GNUS token |
| Polygon Mainnet | 137 | Production |
| Base Mainnet | 8453 | Production |
| BSC Mainnet | 56 | Production |
| Arbitrum Mainnet | 42161 | Production |
| Sepolia | 11155111/11155112 | Test |
| Polygon Amoy | 80002 | Test |
| Base Sepolia | 84532 | Test |
| Arbitrum Sepolia | 421614 | Test |
| BSC Testnet | 97 | Test |

Deployment configurations: `gnus-ai/diamonds/GeniusDiamond/deployments/` and `erc20-gnus-proxy/diamonds/GeniusDiamond/deployments/`

### RPC Providers

- dRPC (primary, via `lb.drpc.org/ogrpc`)
- Chainstack (Sepolia, Base Sepolia, BSC Testnet)
- P2Pify (Sepolia)
- Infura (used in gnus-token legacy config at `gnus-token/truffle-config.js`)
- Local Hardhat fork (development/testing)

## Submodules

The project uses four git submodules defined in `.gitmodules`:

### gnus-ai (ERC-1155 Parent/Child Token System)
- **Path:** `gnus-ai/`
- **Remote:** `../gnus-ai.git` (relative, sibling repository)
- **Contracts location:** `gnus-ai/contracts/gnus-ai/`
- **Version:** 1.4.0 (`gnus-ai/package.json`)
- **What it does:** The core diamond-based ERC-1155 token system with hierarchical parent/child tokens, NFT factory, bridge, and access control.
- **Key contracts:**
  - `GNUSBridge.sol` - Minting, burning, bridging, and token withdrawal (child-to-GNUS redemption)
  - `GNUSNFTFactory.sol` - Creates hierarchical ERC-1155 parent/child token trees; mints child tokens (burning GNUS for direct GNUS children)
  - `ERC1155ProxyOperator.sol` - Proxy operator approvals for gas-free listings
  - `GNUSControl.sol` - Blacklists, bridge fees, chain ID, protocol version management
  - `GeniusAccessControl.sol` - Role-based access control with super admin safeguards
  - `GeniusDiamond.sol` - Diamond contract constructor, ERC-165 interface registration
  - `DiamondInitFacet.sol` - Initialization facet (roles, withdrawal limiter defaults)
  - `GNUSERC1155MaxSupply.sol` - Supply capping, pausing, burn, banned transferors, withdrawal limiter hooks
  - `GNUSContractAssets.sol` - Withdraw mistakenly-sent tokens (not GNUS itself)
  - `ERC20TransferBatch.sol` - Batch ERC-20-style transfers/mints/burns
  - `GeniusOwnershipFacet.sol` - Diamond ownership transfer functionality
  - `GNUSNFTCollectionName.sol` - Optional per-collection naming
  - `GNUSWithdrawLimiter.sol` - Withdrawal limiter management functions
  - `libraries/TransferHelper.sol` - Safe ERC-20 and ETH transfer helpers
  - `GNUSConstants.sol` - Global constants (GNUS_TOKEN_ID=0, max supply, decimals, hierarchy masks)
  - `GNUSNFTFactoryStorage.sol` - NFT metadata struct and diamond storage layout
  - `GNUSControlStorage.sol` - Blacklist, bridge fee, protocol version diamond storage
  - `GNUSWithdrawLimiterStorage.sol` - Bin-based withdrawal rate limiter with diamond storage
  - Mocks: `mocks/MockERC20.sol`, `mocks/MockBadERC20.sol`, `mocks/MockNonPayable.sol`, `mocks/TransferHelperWrapper.sol`
- **Testing:** Hardhat TypeScript tests + Foundry fuzz/invariant tests (`gnus-ai/test/foundry/`)
- **Multi-chain testing:** Uses `hardhat-multichain` for cross-chain simulation

### erc20-gnus-proxy (ERC-20 Proxy Diamond)
- **Path:** `erc20-gnus-proxy/`
- **Remote:** `../erc20-gnus-proxy` (relative, sibling repository)
- **Version:** 1.0.2
- **Contracts location:** `erc20-gnus-proxy/contracts/erc20-gnus-proxy/`
- **What it does:** A separate diamond that wraps a single ERC-1155 child token from GeniusDiamond as an ERC-20-compatible token. Does NOT perform child-to-GNUS conversion. It is a view/transfer facade only.
- **Key contracts:**
  - `ProxyDiamond.sol` - Diamond constructor registering ERC-20 and ERC-165 interfaces
  - `ERC20ProxyFacet.sol` - ERC-20 interface methods (`totalSupply`, `balanceOf`, `transfer`, `approve`, `allowance`, `transferFrom`) all delegating to the underlying ERC-1155 child token
  - `ERC20ProxyStorage.sol` - Diamond storage layout storing: ERC-1155 contract reference, child token ID, name, symbol
- **Approval behavior caveat:** `allowance()` returns `type(uint256).max` or `0` based on ERC-1155 `isApprovedForAll()`. `approve()` calls ERC-1155 `setApprovalForAll()` - this is all-or-nothing, not normal ERC-20 allowance semantics.
- **Also contains a copy of gnus-ai contracts** at `erc20-gnus-proxy/contracts/gnus-ai/` (GeniusAI, GeniusDiamond, GNUSBridge, GNUSNFTFactory, GNUSControl, etc.) for compilation dependencies.

### ZoKrates (zkSNARK Tooling)
- **Path:** `ZoKrates/`
- **Remote:** `https://github.com/ZoKrates/ZoKrates` (upstream)
- **Build system:** Cargo/Rust (not built as part of Solidity workflow)
- **What it does:** Toolbox for zkSNARKs on Ethereum. Used for zero-knowledge proof generation and verification. Not directly compiled into current Solidity contracts but planned for future SuperGenius integration and privacy features.

### sushi-assets / sushi-list (SushiSwap Integration)
- **Path:** `sushi-assets/`, `sushi-list/`
- **What they do:** Token logos, token lists, and pair lists for SushiSwap DEX integration. Contains JSON token lists and pair configurations across multiple chains (Ethereum, Polygon, Avalanche, Fantom).
- **sushi-list structure:** Contains token-lists (chainlink-token-list, etc.) and pair-lists (limit-order-pair-list, default-pair-list, etc.)

## External Contract Dependencies

### @gnus.ai/contracts-upgradeable-diamond (v4.5.0)
- **Source:** npm package, resolved via `@gnus.ai/` import prefix
- **What it provides:** OpenZeppelin contracts forked and adapted for EIP-2535 diamond pattern compatibility. Key modules:
  - **Access:** `AccessControlUpgradeable.sol`, `AccessControlEnumerableUpgradeable.sol`, `IAccessControlUpgradeable.sol`
  - **Token:** `ERC20/` (IERC20Upgradeable, ERC20Storage), `ERC1155/` (IERC1155Upgradeable, ERC1155Storage, ERC1155SupplyUpgradeable, ERC1155SupplyStorage, ERC1155BurnableUpgradeable, IERC1155ReceiverUpgradeable)
  - **Security:** `PausableUpgradeable.sol`
  - **Proxy:** `Initializable.sol` (diamond-compatible initialization pattern)
  - **Utils:** `ContextUpgradeable.sol`, `ERC165StorageUpgradeable.sol`
  - **Interfaces:** `IERC20Upgradeable`, `IERC1155Upgradeable`, `IERC165Upgradeable`, etc.
- **Storage pattern:** Uses diamond storage layout pattern with assembly-based slot access (e.g., `ERC1155Storage.layout()`, `ERC20Storage.layout()`, `ERC1155SupplyStorage.layout()`) to avoid storage collisions between facets.
- **Foundry remapping:** `@gnus.ai/=node_modules/@gnus.ai/` in `foundry.toml`

### contracts-starter (mudgen/diamond-2-hardhat)
- **Source:** GitHub dependency `https://github.com/mudgen/diamond-2-hardhat.git` via npm
- **What it provides:** The reference EIP-2535 diamond implementation:
  - `Diamond.sol` - Base diamond contract with `delegatecall` fallback
  - `DiamondCutFacet.sol` - Facet add/replace/remove functionality
  - `DiamondLoupeFacet.sol` - Facet introspection
  - `libraries/LibDiamond.sol` - Diamond storage struct, interface registration, ownership
  - Both `GeniusDiamond` and `ProxyDiamond` inherit from `Diamond`

### diamonds (GeniusVentures/diamonds#develop)
- **Source:** GitHub dependency
- **What it provides:** Diamond deployment configuration and management (diamond configuration JSON files, deployment callbacks, ABI generation). Used by `hardhat-diamonds` plugin.

### hardhat-diamonds (GeniusVentures/hardhat-diamonds#develop)
- **Source:** GitHub dependency
- **What it provides:** Hardhat tasks for diamond lifecycle: `diamond:generate-abi`, `diamond:generate-abi-typechain`, `diamond:deploy`, etc.

### hardhat-multichain (GeniusVentures/hardhat-multichain#main)
- **Source:** GitHub dependency
- **What it provides:** Multi-chain testing by forking multiple networks simultaneously. Configured in `hardhat.config.ts` under `chainManager.chains`.

### openzeppelin-contracts-diamond
- **Path:** `openzeppelin-contracts-diamond/` (standalone directory, not a submodule but a local copy)
- **Version:** 4.4.1 (OpenZeppelin Contracts Upgradeable)
- **What it provides:** Original OpenZeppelin upgradeable contracts (interface definitions, utility libraries). Contains `token/`, `access/`, `proxy/`, `utils/`, `governance/`, `interfaces/` directories.

### openzeppelin-transpiler
- **Path:** `openzeppelin-transpiler/` (local copy with Hardhat test scaffolding)
- **What it does:** Tooling to transpile standard OpenZeppelin contracts to diamond-compatible forms. Contains transform contracts like `TransformImmutable.sol`, `TransformConstructor.sol`, `GenerateWithInit.sol`, etc. that handle the conversion from OZ upgradeable pattern to diamond storage pattern.

## Facet Structure (GeniusDiamond)

The GeniusDiamond deploys with multiple facets registered via `DiamondCutFacet`. Key facets and their responsibilities:

| Facet | Contract | Responsibility |
|-------|---------|----------------|
| DiamondCut | `DiamondCutFacet.sol` (from contracts-starter) | Add/replace/remove facets |
| DiamondLoupe | `DiamondLoupeFacet.sol` (from contracts-starter) | Enumerate facets and selectors |
| DiamondInit | `gnus-ai/contracts/gnus-ai/DiamondInitFacet.sol` | Initialize roles, limiter, ERC20 interface support |
| GNUSBridge | `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` | Mint/burn/bridge/withdraw tokens |
| GNUSNFTFactory | `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` | Create and mint hierarchical NFTs |
| ERC1155ProxyOperator | `gnus-ai/contracts/gnus-ai/ERC1155ProxyOperator.sol` | Proxy operator approvals, supply queries |
| GNUSControl | `gnus-ai/contracts/gnus-ai/GNUSControl.sol` | Blacklists, fees, protocol config |
| GNUSContractAssets | `gnus-ai/contracts/gnus-ai/GNUSContractAssets.sol` | Withdraw stuck tokens/ETH |
| ERC20TransferBatch | `gnus-ai/contracts/gnus-ai/ERC20TransferBatch.sol` | Batch ERC-20 mint/transfer/burn |
| GeniusOwnership | `gnus-ai/contracts/gnus-ai/GeniusOwnershipFacet.sol` | Diamond ownership management |
| GNUSWithdrawLimiter | `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiter.sol` | Withdrawal limiter management |
| GNUSNFTCollectionName | `gnus-ai/contracts/gnus-ai/GNUSNFTCollectionName.sol` | Per-token collection naming |

**Storage facets (not registered as diamond facets, used as libraries):**
- `GNUSNFTFactoryStorage.sol` - Per-token NFT metadata (name, symbol, URI, exchangeRate, maxSupply, creator, childCurIndex, nftCreated)
- `GNUSControlStorage.sol` - Blacklists, bridgeFee, protocolVersion, chainID
- `GNUSWithdrawLimiterStorage.sol` - Bin-based withdrawal rate limiter data

## Facet Structure (ProxyDiamond)

The ProxyDiamond deploys with a single custom facet:

| Facet | Contract | Responsibility |
|-------|---------|----------------|
| ERC20ProxyFacet | `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyFacet.sol` | ERC-20 interface over ERC-1155 child token |
| ERC20ProxyStorage | `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyStorage.sol` | Storage layout (ERC-1155 contract, childTokenId, name, symbol) |

## Contract Integration Flows

### Child Token Mint Flow (Current Burn/Mint Model)
1. Creator calls `GNUSNFTFactory.createNFT(parentID=0, name, symbol, exchRate, max_supply, uri)` to create a direct GNUS child token
2. Creator calls `GNUSNFTFactory.mint(to, id, amount, data)` to mint child tokens
3. `beforeMint()` checks: only direct GNUS children (`id >> 128 == GNUS_TOKEN_ID`) burn GNUS from caller: `convAmount = amount * exchangeRate`, then `_burn(sender, 0, convAmount)`
4. For deeper descendants (grandchildren), no GNUS is burned on mint

### Withdraw/Redemption Flow (Current Burn/Mint Model)
1. User calls `GNUSBridge.withdraw(amount, id)` with a child token
2. Contract checks: token created, not GNUS itself, sufficient balance, `exchangeRate > 0`, `amount >= exchangeRate`
3. Calculates `convAmount = amount / exchangeRate`
4. If not super admin, checks withdrawal limiter: `GNUSWithdrawLimiterStorage.checkAndRecordWithdraw(sender, convAmount)`
5. Burns child token, mints GNUS tokens to sender
6. **Critical issue:** Any created non-GNUS token with `exchangeRate > 0` can be withdrawn, not just direct GNUS children. See `.planning/Update-Smart-Contracts-Architecture.md` for analysis.

### Bridge Cross-Chain Flow (Current Burn/Mint Model)
1. User calls `GNUSBridge.bridgeOut(amount, id, destChainID)`
2. Contract burns tokens and emits `BridgeSourceBurned` event with sourceChainID, destChainID
3. Relayer observes event, mints equivalent tokens on destination chain
4. **Planned change:** Moving to lock/release model per architecture plan

### ERC-20 Proxy Flow
1. `ProxyDiamond` is deployed separately with `ERC20ProxyFacet` configured to point at a GeniusDiamond ERC-1155 instance + specific childTokenId
2. `ERC20ProxyFacet.transfer()` calls underlying ERC-1155 `safeTransferFrom()` for that child token
3. `ERC20ProxyFacet.balanceOf()` queries underlying ERC-1155 `balanceOf(account, childTokenId)`
4. The proxy is a **view/transfer facade only** - it does not implement redemption, swap, or bridge logic

### Hierarchical Token ID Scheme
- Token IDs use a 256-bit composite: upper 128 bits = parent ID, lower 128 bits = child index
- `GNUS_TOKEN_ID = 0` is the root parent
- Direct child of GNUS: `(0 << 128) | childCurIndex++`
- Grandchild of child A: `(childA_ID << 128) | childCurIndex++`
- Masks defined in `GNUSConstants.sol`: `PARENT_MASK = uint256(MAX_UINT128) << 128`, `CHILD_MASK = MAX_UINT128`
- **Risk:** Left-shifting an already-composite ID can discard upper 128 bits, causing deeper descendants to collide with other branches

## Access Control

**Role** (`GeniusAccessControl.sol`):
- `DEFAULT_ADMIN_ROLE` (= `0x00`) - Full admin: grant/revoke roles, set URI, pause, create NFTs
- `MINTER_ROLE` (= `keccak256("MINTER_ROLE")`) - Mint and burn tokens via bridge
- `CREATOR_ROLE` (= `keccak256("CREATOR_ROLE")`) - Create direct child NFTs of GNUS
- `UPGRADER_ROLE` (= `keccak256("UPGRADER_ROLE")`) - Diamond upgrade authorization
- `NFT_PROXY_OPERATOR_ROLE` (= `keccak256("NFT_PROXY_OPERATOR_ROLE")`) - ERC-1155 operator approval bypass
- **Super Admin** (= `contractOwner` in `LibDiamond.DiamondStorage`) - Special role for ownership, initialization, limiter bypass, blacklisting, critical config; cannot renounce/be revoked from `DEFAULT_ADMIN_ROLE`

## Withdrawal Limiter Integration

The `GNUSWithdrawLimiterStorage` provides bin-based rate limiting on GNUS outflows:
- Default: 100,000 GNUS per 24-hour window, tracked in 24 hourly bins
- Applied on `GNUSBridge.withdraw()` and `ERC20TransferBatch._transferBatch()`
- Super admin bypasses all limits
- Per-account custom configurations supported via `AccountConfig` struct
- Lazy bin expiration cleanup on each check

## Monitoring & Observability

**Error Tracking:**
- Events emitted for all significant state changes (BridgeSourceBurned, Transfer, TransferSingle, Approval, WithdrawLimiterTriggered, WithdrawRecorded, InitLog, AddToBlackList, RemoveFromBlackList, etc.)
- OpenZeppelin Defender integration for security monitoring (`@openzeppelin/defender-sdk`)

**Logs:**
- Winston logger (`winston`) for TypeScript/JavaScript side
- Contract emits structured events
- `erc20-gnus-proxy/scripts/utils/logger.ts` and `logEvents.ts` for event monitoring

**Artifact Provenance:**
- SLSA attestation generation
- Sigstore signing and verification
- Artifact signature validation
- Provenance validation scripts

## CI/CD & Deployment

**Hosting:**
- Multi-chain on-chain deployment (see Active Networks section)
- Diamond deployment via `hardhat-diamonds` plugin using configuration files in `diamonds/` directories
- Local deployment scripts in `erc20-gnus-proxy/scripts/setup/`

**CI Pipeline:**
- Pre-commit via Husky: linting, audit, tests, commitlint
- Security scanning pipeline: `yarn security-check` (audit + Snyk + Socket + OSV + Semgrep + Slither + git-secrets)
- Performance monitoring scripts
- Supply chain risk assessment
- Container build/push management for reproducible environments

## Environment Configuration

**Required env vars** (from `hardhat.config.ts` analysis):
- `PRIVATE_KEY` - Deployer private key
- `DRPC_API_KEY` - dRPC provider key
- `ETHERSCAN_API_KEY` - Contract verification
- `POLYGONSCAN_API_KEY` - Polygon verification
- `BSCSCAN_API_KEY` - BSC verification
- `BASESCAN_API_KEY` - Base verification
- `ARBITRUM_API_KEY` - Arbitrum verification
- `CHAINSTACK_ETH_TEST_API_KEY` - Sepolia RPC
- `CHAINSTACK_BASE_TEST_API_KEY` - Base Sepolia RPC
- `CHAINSTACK_BSC_TEST_API_KEY` - BSC Testnet RPC
- `SOCKET_CLI_API_TOKEN` - Socket Security scanning
- Chain-specific RPC URLs: `MAINNET_RPC`, `SEPOLIA_RPC`, `POLYGON_RPC`, `POLYGON_AMOY_RPC`, `BASE_RPC`, `BASE_SEPOLIA_RPC`, `BSC_RPC`, `BSC_TESTNET_RPC`
- Chain-specific block numbers: `MAINNET_BLOCK`, `SEPOLIA_BLOCK`, `POLYGON_BLOCK`, `POLYGON_AMOY_BLOCK`, `BASE_BLOCK`, `BASE_SEPOLIA_BLOCK`, `BSC_BLOCK`, `BSC_TESTNET_BLOCK`
- `FORK_URL` and `FORK_BLOCK_NUMBER` - Optional Hardhat fork configuration
- `REPORT_GAS` - Enable gas reporting
- `HH_CHAIN_ID` - Custom Hardhat chain ID override

**Secrets location:**
- `.env` file in each package root (gitignored)

**`gnus-token` legacy env vars** (from `truffle-config.js`):
- `privateKey` - Deployer key
- `infuraKey` - Infura project ID
- `publicAddress` - Deployer address
- `etherKey` / `ETHERSCAN_API_KEY` - Verification

## Webhooks & Callbacks

**Incoming:**
- None (contracts receive ETH via `receive()` in `GeniusTokens.sol`; no webhook patterns in facet contracts)

**Outgoing:**
- `GNUSContractAssets.withdrawToken()` transfers ERC-20/ETH out of contract
- `GNUSBridge.bridgeOut()` emits `BridgeSourceBurned` event consumed by off-chain relayers
- Standard ERC-20/ERC-1155 events consumed by indexers and explorers

---

*Integration audit: 2026-06-06*
