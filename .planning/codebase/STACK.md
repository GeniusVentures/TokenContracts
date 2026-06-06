# Technology Stack

**Analysis Date:** 2026-06-06

## Languages

**Primary:**
- Solidity 0.8.19 - All gnus-ai contracts (`gnus-ai/contracts/gnus-ai/*.sol`)
- Solidity 0.8.9 - erc20-gnus-proxy compilation target (`erc20-gnus-proxy/hardhat.config.ts`)
- Solidity 0.8.2 - erc20-gnus-proxy facet/storage files (`erc20-gnus-proxy/contracts/erc20-gnus-proxy/*.sol`)
- Solidity 0.8.0 - gnus-token ICO contract (`gnus-token/contracts/GeniusTokens.sol`)

**Secondary:**
- TypeScript 5.9.3 - Build scripts, test suites, Hardhat config, DevOps tooling
- Rust (via ZoKrates submodule) - zkSNARK proof generation and verification (`ZoKrates/Cargo.toml`)
- JavaScript (via openzeppelin-transpiler) - Solidity-to-diamond transpiler tooling

## Runtime

**Environment:**
- Node.js >= 18.0.0 (required by erc20-gnus-proxy `@types/node` dependency)
- Yarn 4.x (project uses Yarn Berry with PnP, `.yarnrc.yml` implied by `packageManager` field)
- Truffle v5.3.7 (gnus-token only - legacy deployment framework)

**Package Manager:**
- Yarn 4.9.4 (`erc20-gnus-proxy/package.json`) / Yarn 4.10.3 (`gnus-ai/package.json`)
- npm (gnus-token/package-lock.json present)
- Lockfiles: `yarn.lock` present in erc20-gnus-proxy and gnus-ai; `package-lock.json` in gnus-token

## Frameworks

**Core:**
- Hardhat 2.26.x - Primary compilation, testing, and deployment framework (`erc20-gnus-proxy/hardhat.config.ts`, `gnus-ai/hardhat.config.ts`)
- Foundry (forge) 0.8.19 - Secondary build, fuzz testing, and gas reporting (`gnus-ai/foundry.toml`)
- Truffle 5.3.7 (gnus-token only - legacy ICO contract framework) (`gnus-token/truffle-config.js`)

**Testing:**
- Mocha + Chai (via @nomicfoundation/hardhat-toolbox) - Hardhat TypeScript tests
- Chai-as-promised - Async test assertions
- Sinon - Mocking framework
- Foundry Forge - Solidity-native fuzz testing and invariant tests (`gnus-ai/test/foundry/`)
- Foundry fuzz config: 256 runs dev, 10,000 runs CI, 50,000 runs intense mode
- Multi-chain testing via `hardhat-multichain` plugin (tests bridging across simulated chains)

**Build/Dev:**
- TypeScript 5.9.3 - Compilation for scripts and tests
- `ts-node` - Direct TypeScript execution
- TypeChain 8.x - TypeScript bindings from contract ABIs
- ESLint 9.x + Prettier 3.x - Code quality and formatting
- Husky + lint-staged - Pre-commit hooks (commitlint, audit, tests)
- Solhint - Solidity linting

## Key Dependencies

**Critical:**
- `@gnus.ai/contracts-upgradeable-diamond` 4.5.0 - Custom OpenZeppelin fork adapted for EIP-2535 Diamond pattern storage. Provides upgradeable ERC20, ERC1155, access control, security, and utility libraries with diamond-compatible storage layouts.
- `contracts-starter` (mudgen/diamond-2-hardhat) - Reference EIP-2535 Diamond implementation including `Diamond.sol`, `DiamondCutFacet.sol`, `DiamondLoupeFacet.sol`, and `LibDiamond.sol`. The foundation for both `GeniusDiamond` and `ProxyDiamond`.
- `@openzeppelin/contracts` 4.1.0 (gnus-token only) - Standard (non-upgradeable, non-diamond) OpenZeppelin contracts for the original ERC-20 ICO contract.

**Infrastructure:**
- `diamonds` (GeniusVentures/diamonds#develop) - Diamond deployment configuration and management tooling
- `hardhat-diamonds` (GeniusVentures/hardhat-diamonds#develop) - Hardhat plugin for diamond ABI generation, deployment, and typechain
- `hardhat-multichain` (GeniusVentures/hardhat-multichain#main) - Plugin for testing across multiple simulated blockchain chains
- `hardhat-abi-exporter` - Exports contract ABIs
- `hardhat-gas-reporter` - Gas usage reporting in USD
- `solidity-coverage` 0.8.x - Test coverage instrumentation

**Security Scanning:**
- Snyk - Dependency vulnerability scanning
- Semgrep - Static analysis security testing
- Slither - Solidity static analysis (`slither.config.json`)
- Socket Security - Supply chain risk assessment
- OSV Scanner - Open source vulnerability scanning
- OpenZeppelin Defender SDK - Security monitoring and incident response

**Verification:**
- SLSA attestation + Sigstore signing (artifact provenance)
- Supply chain risk assessment tooling
- `hardhat-verify` / `@nomicfoundation/hardhat-verify` - Etherscan/Polygonscan/BscScan contract verification

## Configuration

**Environment:**
- `.env` file - Contains RPC URLs, API keys, and private keys (never committed)
- Environment variables required: `PRIVATE_KEY`, `DRPC_API_KEY`, `ETHERSCAN_API_KEY`, `POLYGONSCAN_API_KEY`, `CHAINSTACK_*_API_KEY`, `BSCSCAN_API_KEY`, `BASESCAN_API_KEY`, `ARBITRUM_API_KEY`
- Chain RPC URLs: `MAINNET_RPC`, `SEPOLIA_RPC`, `POLYGON_RPC`, `POLYGON_AMOY_RPC`, `BASE_RPC`, `BASE_SEPOLIA_RPC`, `BSC_RPC`, `BSC_TESTNET_RPC`
- Block numbers for each chain (forking start points)

**Build:**
- `gnus-ai/hardhat.config.ts` - Compiler version 0.8.19, optimizer enabled (1,000 runs) via `@gnus.ai/contracts-upgradeable-diamond` import resolution
- `erc20-gnus-proxy/hardhat.config.ts` - Compiler version 0.8.9, optimizer enabled (1,000 runs), evmVersion default
- `gnus-token/truffle-config.js` - Compiler version 0.8.0, optimizer enabled (1,000 runs), evmVersion "istanbul"
- `gnus-ai/foundry.toml` - Compiler version 0.8.19, optimizer runs 200, EVM version "paris", 120-char line length, remappings for @gnus.ai, contracts-starter, forge-std, @openzeppelin, @diamondslab

**Build Commands (gnus-ai / erc20-gnus-proxy):**
```bash
yarn compile         # Hardhat compile + diamond ABI generation + typechain
yarn test            # Hardhat test suite
yarn clean-compile   # Clean artifacts, then compile
yarn forge:test      # Foundry fuzz testing
yarn test:all        # Hardhat + Foundry tests
```

**Build Commands (gnus-token - legacy):**
```bash
truffle compile      # Compile Solidity
truffle test         # Run Truffle tests
```

## Platform Requirements

**Development:**
- Node.js >= 18.0.0
- Yarn Berry (4.x) with PnP
- Solidity compiler solc 0.8.0 - 0.8.19
- Foundry toolchain (forge, cast) for fuzz testing and gas reporting
- Rust toolchain (for ZoKrates submodule, not active in current development)

**Production:**
- Multi-chain deployment targets (via `hardhat-multichain`):
  - Ethereum Mainnet (chainId 1)
  - Polygon Mainnet (chainId 137)
  - Polygon Amoy Testnet (chainId 80002)
  - Sepolia Testnet (chainId 11155111/11155112)
  - Arbitrum Mainnet (chainId 42161)
  - Arbitrum Sepolia (chainId 421614)
  - Base Mainnet (chainId 8453)
  - Base Sepolia (chainId 84532)
  - BSC Mainnet (chainId 56)
  - BSC Testnet (chainId 97)
- Diamond deployment configurations in `gnus-ai/diamonds/GeniusDiamond/deployments/` and `erc20-gnus-proxy/diamonds/`
- RPC providers: dRPC, Chainstack, Infura, P2Pify
- Block explorers: Etherscan, Polygonscan, BscScan, Basescan, Arbiscan

---

*Stack analysis: 2026-06-06*
