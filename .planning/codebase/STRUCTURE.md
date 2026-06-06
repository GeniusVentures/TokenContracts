# Codebase Structure

**Analysis Date:** 2026-06-06

## Directory Layout

```
TokenContracts/                              # Root -- multi-submodule mono-repo
├── gnus-ai/                                 # [GIT SUBMODULE] Core GNUS diamond proxy ecosystem
│   ├── contracts/
│   │   ├── gnus-ai/                         # All GNUS facets and storage libraries
│   │   └── mocks/                           # Test mock contracts (MockBadERC20, MockERC20, MockNonPayable)
│   ├── diamonds/
│   │   └── GeniusDiamond/                   # Diamond cut configs + deployment artifacts per network
│   │       ├── *.config.json                # Facet registration (geniusdiamond.config.json, v2.5 upgrade, ERC1155 override)
│   │       └── deployments/                 # Deployed facet addresses per network (JSON)
│   ├── test/                                # Test suites (Foundry + Hardhat)
│   │   ├── foundry/                         # Foundry fuzz/invariant/integration tests
│   │   ├── unit/                            # Hardhat unit tests (*.test.ts)
│   │   ├── integration/                     # Hardhat integration tests
│   │   ├── deployment/                      # Deployment tests
│   │   ├── gas/                             # Gas comparison tests
│   │   └── utils/                           # Test utilities (logger, network-utils)
│   ├── scripts/                             # Deployment and management scripts
│   ├── config/                              # Network configuration files
│   └── typechain-types/                     # Generated TypeScript type bindings
│
├── erc20-gnus-proxy/                        # [GIT SUBMODULE] ERC-20 wrapper for single ERC-1155 child token
│   ├── contracts/
│   │   ├── erc20-gnus-proxy/                # Proxy diamond and facet
│   │   └── gnus-ai/                         # Symlinks/references to gnus-ai facets (for diamond build)
│   ├── diamonds/
│   │   ├── ProxyDiamond/                    # Proxy diamond config (single facet: ERC20ProxyFacet)
│   │   └── GeniusDiamond/                   # Seeded reference diamond configs
│   ├── test/                                # Hardhat test suites
│   │   ├── unit/                            # Unit tests for proxy
│   │   ├── integration/                     # Integration tests
│   │   └── deployment/                      # Deployment test scripts
│   └── scripts/                             # Deployment scripts for proxy
│
├── gnus-token/                              # [LOCAL] Legacy ITO (Initial Token Offering) contract
│   ├── contracts/
│   │   └── GeniusTokens.sol                 # Non-upgradeable ERC-20 ITO with staged pricing
│   ├── test/
│   └── migrations/                          # Truffle migration scripts (v1 legacy)
│
├── openzeppelin-contracts-diamond/          # [GIT SUBMODULE] Diamond-adapted OpenZeppelin contracts
│   ├── contracts/
│   │   ├── token/ERC1155/                   # ERC-1155 upgradeable + diamond storage
│   │   ├── token/ERC20/                     # ERC-20 storage library
│   │   ├── access/                          # AccessControlEnumerable + Ownable upgradeable
│   │   ├── proxy/                           # Diamond proxy infrastructure
│   │   ├── security/                        # Pausable upgradeable
│   │   └── ...
│   └── test/                                # Tests for adapted contracts
│
├── openzeppelin-transpiler/                 # [GIT SUBMODULE] AST-based Solidity transpiler (dev tool)
│   ├── src/                                 # TypeScript transpiler source
│   └── contracts/                           # Test input contracts for transpiler
│
├── ZoKrates/                                # [GIT SUBMODULE] Zero-knowledge proof toolkit (Rust)
│   └── ...                                  # ZK circuit compiler and libraries
│
├── sushi-list/                              # [UNTRACKED] SushiSwap token list
├── sushi-assets/                            # [GIT SUBMODULE] SushiSwap asset images
├── GeniusDiamond/                           # [EMPTY] Sparse -- only .idea IDE config, no contracts
├── test/                                    # Root-level test (package.json + testcalc.js -- minimal)
│
├── .planning/                               # GSD planning documents
│   ├── codebase/                            # Codebase map documents (this directory)
│   └── Update-Smart-Contracts-Architecture.md  # Architectural migration plan
│
├── README.md                                # Project overview
├── .gitmodules                              # Submodule definitions (5 tracked submodules)
├── .gitignore                               # Git ignore rules
└── LICENSE                                  # MIT license
```

## Git Submodule Map

This repository is a meta-repository that assembles multiple submodules:

| Submodule Path | Remote | Purpose | Tracked |
|---------------|--------|---------|---------|
| `gnus-ai` | `../gnus-ai.git` | Core GNUS ecosystem: diamond, facets, factory, bridge, limiter | Yes |
| `erc20-gnus-proxy` | `../erc20-gnus-proxy` | ERC-20 proxy facade for single ERC-1155 child token | Yes |
| `openzeppelin-contracts-diamond` | (included in `gnus-ai`) | Diamond-adapted OpenZeppelin contracts (ERC-1155, ERC-20, access control) | Yes |
| `openzeppelin-transpiler` | (included in `gnus-ai`) | Source-to-source Solidity transpiler (version upgrades, diamond adaptation) | Yes |
| `ZoKrates` | `https://github.com/ZoKrates/ZoKrates` | Zero-knowledge proof toolkit for privacy (Rust, future use) | Yes |
| `sushi-assets` | `../sushi-assets.git` | SushiSwap token asset images | Yes |
| `sushi-list` | (listed in .gitignore) | SushiSwap token list (untracked in git status) | No |

The `gnus-ai` submodule incorporates `openzeppelin-contracts-diamond` and `openzeppelin-transpiler` via its own submodule chain. The `erc20-gnus-proxy` submodule references `gnus-ai` contracts via its own import structure.

## Directory Purposes

**gnus-ai/contracts/gnus-ai/:**
- Purpose: All core GNUS ecosystem Solidity contracts -- facets, storage libraries, access control, bridge, factory, limiter
- Contains: 18 Solidity source files (excluding mocks)
- Key files: `GNUSBridge.sol` (404 lines), `GNUSNFTFactory.sol` (204 lines), `GNUSWithdrawLimiterStorage.sol` (223 lines), `GNUSWithdrawLimiter.sol` (241 lines), `GNUSControl.sol` (152 lines)

**gnus-ai/contracts/mocks/:**
- Purpose: Test doubles for unit and integration testing
- Contains: `MockBadERC20.sol`, `MockERC20.sol`, `MockNonPayable.sol`, `TransferHelperWrapper.sol`

**gnus-ai/diamonds/GeniusDiamond/:**
- Purpose: Diamond Standard configuration and deployment artifacts
- Contains: JSON config files defining facets, versions, priorities, init functions, and deployment addresses per network
- Key files: `geniusdiamond.config.json` (v2.5 main config), `geniusdiamond-sepolia-v2.5-step1.config.json` (v2.41 to v2.5 upgrade path), `geniusdiamond-erc1155override.config.json` (ERC-1155 proxy operator override variant)
- Deployments: JSON files per network containing deployed facet addresses (base, base_sepolia, bsc, bsc_testnet, hardhat, mainnet, polygon, polygon_amoy, sepolia)

**gnus-ai/test/:**
- Purpose: All test suites
- Contains:
  - `foundry/` -- Foundry tests: `base/` (test base class), `fuzz/` (14 fuzz test files for access control, bridge, diamond, ERC1155, ERC20, factory, limiter, security), `invariant/` (8 invariant tests), `integration/` (6 integration tests), `poc/` (3 proof-of-concept tests), `security/` (sybil attack test), `unit/` (2 unit tests)
  - `unit/` -- Hardhat unit tests (19 `.test.ts` files covering all facets)
  - `integration/` -- Hardhat integration tests (4 `.test.ts` files)
  - `deployment/` -- Deployment test
  - `gas/` -- Gas comparison test

**erc20-gnus-proxy/contracts/erc20-gnus-proxy/:**
- Purpose: ERC-20 proxy facet and its diamond, storage, and base contract
- Contains: `ERC20ProxyFacet.sol`, `ERC20ProxyStorage.sol`, `ProxyDiamond.sol`

**erc20-gnus-proxy/contracts/gnus-ai/:**
- Purpose: Required gnus-ai contracts for proxy diamond compilation (imported via remappings)
- Contains: Same contracts as gnus-ai with one addition: `GeniusAI.sol` and `GeniusAIStorage.sol`

**erc20-gnus-proxy/diamonds/:**
- Purpose: Diamond configs for both the proxy diamond and seeded GeniusDiamond references
- Contains:
  - `ProxyDiamond/proxydiamond.config.json` -- Single facet (ERC20ProxyFacet), protocol version 0.0
  - `ProxyDiamond/callbacks/` -- Callback configuration for token creation
  - `ProxyDiamond/deployments/` -- Deployment addresses
  - `GeniusDiamond/` -- Seeded reference configs and deployment addresses

**gnus-token/:**
- Purpose: Legacy ITO (Initial Token Offering) contract -- pre-diamond, separate deployment
- Contains: `contracts/GeniusTokens.sol` -- ERC-20 with staged ETH-to-GNUS pricing (1000/800/640/512 rates), `test/GnusToken.ts`, `migrations/` (Truffle)

**openzeppelin-contracts-diamond/:**
- Purpose: Diamond-adapted OpenZeppelin library contracts used as the foundation for all facets
- Contains: Modified OpenZeppelin contracts where all state variables use the library `Layout` storage pattern instead of contract-level state variables
- Key directories: `token/ERC1155/` (upgradeable base, supply, burn extensions), `token/ERC20/` (storage library), `access/` (AccessControlEnumerable, Ownable), `proxy/` (Diamond base contracts), `security/` (Pausable)

**openzeppelin-transpiler/:**
- Purpose: Development tool that transforms standard OpenZeppelin Solidity contracts into diamond-compatible upgradeable forms and performs Solidity version upgrades
- Contains: TypeScript AST-based transformers (`src/transform-0.8.ts`, `src/generate-with-init.ts`, `src/find-already-initializable.ts`), test contracts, and CLI entry point

**ZoKrates/:**
- Purpose: Future zero-knowledge proof support for private transactions on the SuperGenius chain
- Contains: Rust-based ZK toolkit (`zokrates_core`, `zokrates_cli`, `zokrates_field`, `zokrates_proof_systems`, etc.)
- Status: Present but not yet integrated with the Solidity contracts

**sushi-list/ and sushi-assets/:**
- Purpose: SushiSwap token list entries and asset images for GNUS tokens on DEX listings
- Status: Supporting assets, not contract logic

**GeniusDiamond/:**
- Purpose: Sparse directory containing only `.idea` IDE configuration
- Status: Appears vestigial -- contracts previously here have been moved into the `gnus-ai` submodule

**.planning/:**
- Purpose: GSD planning workspace
- Contains: `Update-Smart-Contracts-Architecture.md` (chat-exported architectural migration analysis), `codebase/` (codebase map documents)

## Key File Locations

**Entry Points:**
- `gnus-ai/contracts/gnus-ai/GeniusDiamond.sol`: Main diamond proxy constructor -- registers IERC1155, IERC165, IDiamondCut, IDiamondLoupe
- `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ProxyDiamond.sol`: ERC-20 proxy diamond constructor -- registers IERC20
- `gnus-ai/contracts/gnus-ai/DiamondInitFacet.sol`: Initialization orchestrator (`diamondInitialize250()`)

**Configuration:**
- `gnus-ai/diamonds/GeniusDiamond/geniusdiamond.config.json`: Main facet registration (v2.5, 13 facets)
- `gnus-ai/diamonds/GeniusDiamond/geniusdiamond-erc1155override.config.json`: ERC-1155 operator override variant
- `gnus-ai/diamonds/GeniusDiamond/geniusdiamond-sepolia-v2.5-step1.config.json`: Sepolia v2.41 to v2.5 upgrade path
- `erc20-gnus-proxy/diamonds/ProxyDiamond/proxydiamond.config.json`: Proxy diamond config (single facet)
- `.gitmodules`: Submodule URL definitions

**Core Logic (order by line count):**
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` (404 lines): Bridge, mint/burn, withdraw, transfer, ERC-20 interface
- `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiter.sol` (241 lines): Limiter admin facet
- `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiterStorage.sol` (223 lines): Limiter engine (bin logic, validation)
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` (204 lines): Token creation, hierarchical IDs, mint with burn
- `gnus-ai/contracts/gnus-ai/ERC20TransferBatch.sol` (202 lines): Batch GNUS mint/transfer/burn
- `gnus-ai/contracts/gnus-ai/GNUSControl.sol` (152 lines): Protocol security, bans, fees
- `gnus-ai/contracts/gnus-ai/GNUSERC1155MaxSupply.sol` (96 lines): Shared base with hooks

**Storage:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactoryStorage.sol`: NFT metadata struct + `mapping(uint256 => NFT)` layout
- `gnus-ai/contracts/gnus-ai/GNUSControlStorage.sol`: Ban lists, bridge fee, protocol version, chain ID, diamond delegatecall helper
- `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiterStorage.sol`: Account states, bin arrays, configs, defaults, checkAndRecordWithdraw
- `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyStorage.sol`: ERC-1155 contract ref, child token ID, name, symbol

**Access Control:**
- `gnus-ai/contracts/gnus-ai/GeniusAccessControl.sol`: Role definitions, super admin protection, `onlySuperAdminRole` modifier
- `gnus-ai/contracts/gnus-ai/GeniusOwnershipFacet.sol`: EIP-173 ownership transfer with role migration

**Constants:**
- `gnus-ai/contracts/gnus-ai/GNUSConstants.sol`: `GNUS_TOKEN_ID` (0), `GNUS_MAX_SUPPLY` (50M * 10^18), `PARENT_MASK`, `CHILD_MASK`, `ETHER` address

**Utility:**
- `gnus-ai/contracts/gnus-ai/libraries/TransferHelper.sol`: Safe ERC-20 approve/transfer/transferFrom and ETH transfer
- `gnus-ai/contracts/gnus-ai/GNUSContractAssets.sol`: Super admin withdrawal of accidentally sent tokens (not GNUS)
- `gnus-ai/contracts/gnus-ai/GNUSNFTCollectionName.sol`: Collection name constant

**Testing:**
- `gnus-ai/test/foundry/base/GeniusDiamondTestBase.sol`: Foundry test base class
- `gnus-ai/test/foundry/handlers/GeniusDiamondHandler.sol`: Foundry handler for fuzz testing
- `gnus-ai/test/unit/GNUSBridge.test.ts`: GNUSBridge unit tests (Hardhat)
- `gnus-ai/test/unit/GNUSNFTFactoryEnhanced.test.ts`: Factory unit tests (Hardhat)
- `gnus-ai/test/unit/GNUSWithdrawLimiter.test.ts`: Limiter unit tests (Hardhat)
- `gnus-ai/test/foundry/fuzz/BridgeFuzz.t.sol`: Bridge fuzz tests (Foundry)
- `gnus-ai/test/foundry/fuzz/NFTFactoryFuzz.t.sol`: Factory fuzz tests (Foundry)
- `gnus-ai/test/foundry/invariant/EconomicInvariant.t.sol`: Economic invariant tests (Foundry)

**Legacy:**
- `gnus-token/contracts/GeniusTokens.sol`: Non-diamond ERC-20 ITO contract (separate deployment)
- `gnus-token/migrations/`: Truffle migration scripts (v1)

**Planning:**
- `.planning/Update-Smart-Contracts-Architecture.md`: Migration plan from burn/mint to treasury/reserve model, from mint/burn bridge to lock/release bridge

## Naming Conventions

**Files:**
- PascalCase for contract files: `GNUSBridge.sol`, `GNUSNFTFactory.sol`, `GeniusAccessControl.sol`
- `*Storage.sol` suffix for storage library files: `GNUSNFTFactoryStorage.sol`, `GNUSControlStorage.sol`
- `*Facet.sol` suffix for diamond facet contracts: `DiamondInitFacet.sol`, `ERC20ProxyFacet.sol`
- `.config.json` suffix for diamond configuration: `geniusdiamond.config.json`
- `.test.ts` suffix for Hardhat TypeScript tests
- `.t.sol` suffix for Foundry Solidity tests
- Mock prefix for test contracts: `MockERC20.sol`, `MockBadERC20.sol`

**Directories:**
- Lowercase with hyphens: `gnus-ai`, `erc20-gnus-proxy`, `gnus-token`, `openzeppelin-contracts-diamond`
- `contracts/` for Solidity source
- `test/` for test files
- `diamonds/` for diamond standard configuration and deployment artifacts

**Contracts:**
- PascalCase: `GNUSBridge`, `GNUSNFTFactory`, `GNUSControl`, `GeniusAccessControl`
- `GNUS*` prefix for GNUS-specific contracts
- `Genius*` prefix for shared infrastructure

**Functions:**
- camelCase (standard Solidity style): `createNFT()`, `bridgeOut()`, `checkAndRecordWithdraw()`
- Internal functions prefixed with underscore: `_mint()`, `_beforeTokenTransfer()`, `_mintWithBridgeFee()`
- Public functions have no underscore prefix
- Init functions use pattern `ContractName_Initialize()`: `GNUSNFTFactory_Initialize()`, `GNUSControl_Initialize230()`
- Versioned init functions include version suffix: `GNUSNFTFactory_Initialize230()`, `diamondInitialize250()`

**Variables:**
- camelCase for local and storage variables
- UPPER_CASE for constants: `GNUS_TOKEN_ID`, `GNUS_MAX_SUPPLY`, `MAX_FEE`, `FEE_DOMINATOR`
- Role identifiers use `keccak256("UPPER_CASE")`: `MINTER_ROLE`, `CREATOR_ROLE`, `NFT_PROXY_OPERATOR_ROLE`
- Storage position constants: `keccak256("gnus.ai.nft.factory.storage")`

## Where to Add New Code

**New Facet (new feature on GeniusDiamond):**
- Primary code: `gnus-ai/contracts/gnus-ai/NewFeature.sol` -- implement facet logic
- Storage: `gnus-ai/contracts/gnus-ai/NewFeatureStorage.sol` -- library with Layout struct and `layout()` accessor
- Diamond config: Add entry to `gnus-ai/diamonds/GeniusDiamond/geniusdiamond.config.json` under `facets` with priority, versions, and optional init functions
- Tests:
  - Hardhat: `gnus-ai/test/unit/NewFeature.test.ts`
  - Foundry fuzz: `gnus-ai/test/foundry/fuzz/NewFeatureFuzz.t.sol`
  - Foundry invariant: `gnus-ai/test/foundry/invariant/NewFeatureInvariant.t.sol`

**New Facet (new feature on ProxyDiamond):**
- Primary code: `erc20-gnus-proxy/contracts/erc20-gnus-proxy/NewFacet.sol`
- Diamond config: Add to `erc20-gnus-proxy/diamonds/ProxyDiamond/proxydiamond.config.json`

**New Storage Library:**
- Location: `gnus-ai/contracts/gnus-ai/XxxStorage.sol`
- Follow pattern: Wrap struct in `library`, use `keccak256("gnus.ai.xxx.storage")` for slot, access via `layout()` with inline assembly

**New Constant:**
- Location: `gnus-ai/contracts/gnus-ai/GNUSConstants.sol` (if GNUS-specific) or new constants file

**New Test:**
- Hardhat unit: `gnus-ai/test/unit/ContractName.test.ts` -- co-located with source but in `test/` directory
- Foundry fuzz: `gnus-ai/test/foundry/fuzz/FeatureFuzz.t.sol`
- Foundry invariant: `gnus-ai/test/foundry/invariant/FeatureInvariant.t.sol`

**New Deployment:**
- Network definition: `gnus-ai/diamonds/GeniusDiamond/deployments/base.json` (add network JSON)
- Deployment addresses: `gnus-ai/diamonds/GeniusDiamond/deployments/geniusdiamond-{network}-{chainId}.json`

**New Bridge Integration:**
- The bridge currently uses burn-on-source + event emission. Any new bridge logic (lock/release) would go in a new facet (e.g., `GNUSBridgeVault.sol` + `GNUSBridgeLedgerStorage.sol`)
- See `.planning/Update-Smart-Contracts-Architecture.md` for planned bridge architecture changes

**Architecture Migration (burn/mint to treasury/reserve):**
- See `.planning/Update-Smart-Contracts-Architecture.md` for the full migration plan
- Key changes would touch: `GNUSNFTFactory.sol` (mint flow), `GNUSBridge.sol` (withdraw flow), `GNUSNFTFactoryStorage.sol` (add reserve fields to NFT struct)

## Special Directories

**gnus-ai/diamonds/GeniusDiamond/deployments/:**
- Purpose: Contains deployed facet addresses per network
- Generated: Yes (by deployment scripts)
- Committed: Yes (tracked in git)
- Files: `geniusdiamond-{network}-{chainId}.json` (e.g., `geniusdiamond-sepolia-11155111.json`)

**gnus-ai/typechain-types/:**
- Purpose: Generated TypeScript type bindings from contract ABIs
- Generated: Yes (by TypeChain)
- Committed: In submodule, may be generated locally

**gnus-ai/artifacts/ and gnus-ai/cache/:**
- Purpose: Hardhat compilation artifacts and cache
- Generated: Yes (by Hardhat)
- Committed: No (gitignored, regenerated on build)

**gnus-ai/coverage/:**
- Purpose: Code coverage reports (lcov/html)
- Generated: Yes (by solidity-coverage)
- Committed: No

**ZoKrates/:**
- Purpose: Zero-knowledge proof compiler and toolkit (Rust)
- Generated: Compiled via Rust/Cargo
- Committed: Yes (as submodule reference)

**sushi-list/ and sushi-assets/:**
- Purpose: SushiSwap token list entries and images for DEX integration
- Generated: No (manually curated)
- Committed: sushi-assets yes (submodule), sushi-list untracked

---

*Structure analysis: 2026-06-06*
