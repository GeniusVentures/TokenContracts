# Testing Patterns

**Analysis Date:** 2026-06-06

## Test Frameworks

### Primary: Foundry (Forge)
The main test framework for all gnus-ai contracts. Used for unit, fuzz, invariant, and security tests.

- **Config:** `gnus-ai/foundry.toml`
- **Solc version:** `0.8.19`
- **EVM version:** `paris`
- **Optimizer:** enabled, 200 runs

### Secondary: Hardhat
Used for multi-chain integration tests, deployment scripts, diamond ABI generation, and Typechain type generation.

- **Config:** `gnus-ai/hardhat.config.ts`, `erc20-gnus-proxy/hardhat.config.ts`
- **Plugins:** `@diamondslab/diamonds-hardhat-foundry`, `@diamondslab/hardhat-diamonds`, `@nomicfoundation/hardhat-toolbox`, `hardhat-multichain`, `solidity-coverage`, `hardhat-gas-reporter`, `hardhat-abi-exporter`, `@typechain/hardhat`

### Test Commands

```bash
# Foundry (primary)
cd gnus-ai
yarn forge:test                 # Run all Foundry tests (requires Hardhat diamond helper generation first)
yarn forge:test:verbose         # Verbose output (forge test -vvv)
yarn forge:test:gas             # With gas reporting (forge test --gas-report)
yarn forge:coverage             # Coverage report (forge coverage)
yarn forge:snapshot             # Gas snapshot (forge snapshot)
yarn forge:fmt                  # Format contracts (forge fmt)
yarn forge:fmt:check            # Check formatting (forge fmt --check)

# Hardhat (secondary)
yarn test                       # Hardhat unit tests (npx hardhat test)
yarn test-multichain            # Multi-chain tests (npx hardhat test-multichain)
yarn coverage                   # Solidity coverage via Hardhat (npx hardhat coverage)
yarn test:all                   # Both Hardhat and Foundry tests

# Full pipeline (build + test)
yarn build                      # Clean install + compile + diamond ABI/typechain generation
yarn forge:build                # Foundry build only (forge build)
```

## Test File Organization

### Directory Structure
All Foundry tests live under `gnus-ai/test/foundry/`:

```
test/foundry/
├── base/
│   └── GeniusDiamondTestBase.sol      # Base class for all Diamond tests
├── fuzz/
│   ├── AccessControlFuzz.t.sol         # Role-based access control fuzz tests
│   ├── BridgeFuzz.t.sol                # Bridge mint/burn fuzz tests
│   ├── DiamondAccessControl.t.sol      # Diamond-level access control fuzz
│   ├── DiamondCoreFuzz.t.sol           # Core diamond proxy fuzz
│   ├── DiamondInvariants.t.sol         # Diamond structural invariants (fuzz)
│   ├── DiamondOwnership.t.sol          # Ownership transfer fuzz
│   ├── DiamondRouting.t.sol            # Function routing fuzz
│   ├── ERC1155Fuzz.t.sol               # ERC1155 token fuzz tests
│   ├── ERC20Fuzz.t.sol                 # ERC20-compatible GNUS fuzz tests
│   ├── ExampleFuzz.t.sol               # Example/template fuzz test
│   ├── GNUSWithdrawLimiterFuzz.t.sol   # Withdrawal limiter fuzz tests
│   ├── NFTFactoryFuzz.t.sol            # NFT factory fuzz tests
│   └── SecurityFuzz.t.sol              # Security-focused fuzz tests
├── handlers/
│   └── GeniusDiamondHandler.sol        # Stateful handler for invariant fuzzing
├── helpers/
│   └── DiamondDeployment.sol           # Loads Diamond address/ABI from deployment
├── integration/
│   ├── BasicDiamondIntegration.t.sol   # Diamond deployment + facet integration
│   ├── BasicDiamondIntegrationDeployed.t.sol  # Tests against deployed diamond
│   ├── ExampleIntegration.t.sol        # Template integration test
│   ├── SnapshotExample.t.sol           # Snapshot-based integration test
│   └── diamonds-hardhat-foundry/
│       ├── deployment.t.sol            # Deployment validation
│       ├── end-to-end.t.sol            # Full end-to-end flow
│       └── helper-generation.t.sol     # ABI/type generation validation
├── invariant/
│   ├── AccessControlInvariant.t.sol    # Access control invariants
│   ├── BridgeInvariant.t.sol           # Bridge state invariants
│   ├── DiamondCoreInvariant.t.sol      # Diamond core invariants
│   ├── DiamondProxyInvariant.t.sol     # Proxy integrity invariants
│   ├── ERC1155Invariant.t.sol          # ERC1155 state invariants
│   ├── ERC20Invariant.t.sol            # ERC20 balance invariants
│   ├── EconomicInvariant.t.sol         # Economic/tokenomics invariants
│   └── NFTFactoryInvariant.t.sol       # NFT factory invariants
├── poc/
│   ├── DiamondABIDebugTest.t.sol       # ABI debugging proof-of-concept
│   ├── DiamondABILoadingPOC.t.sol      # ABI loading proof-of-concept
│   └── JSONParseTest.t.sol             # JSON parsing test
├── security/
│   └── GNUSWithdrawLimiterSybilAttack.t.sol  # Sybil attack resistance tests
└── unit/
    ├── GNUSConstantsFacet.t.sol        # Constants validation
    └── GNUSUnit.t.sol                  # Example unit test template
```

### File Naming
| Type | Pattern | Example |
|------|---------|---------|
| Fuzz tests | `{Name}Fuzz.t.sol` | `ERC20Fuzz.t.sol` |
| Invariant tests | `{Name}Invariant.t.sol` | `DiamondCoreInvariant.t.sol` |
| Integration tests | `{Name}Integration.t.sol` | `BasicDiamondIntegration.t.sol` |
| Unit tests | `{Name}Unit.t.sol` or `{Name}.t.sol` | `GNUSUnit.t.sol` |
| Security tests | `{Name}SybilAttack.t.sol` or `{Name}Security.t.sol` | `GNUSWithdrawLimiterSybilAttack.t.sol` |
| Handlers | `{Name}Handler.sol` | `GeniusDiamondHandler.sol` |
| Base classes | `{Name}TestBase.sol` | `GeniusDiamondTestBase.sol` |
| Helpers | `{Name}.sol` | `DiamondDeployment.sol` |

### Test File Location
- Tests co-located with the project they test (not next to source files)
- `/gnus-ai/test/foundry/` is the root for all gnus-ai Foundry tests
- `/test/` at the repo root contains only the legacy `testcalc.js` token calculation test

## Test Base Class

### `GeniusDiamondTestBase`
Located at `gnus-ai/test/foundry/base/GeniusDiamondTestBase.sol`. All gnus-ai tests inherit from this class (which extends `DiamondFuzzBase`).

Key features:
- **Role constants** pre-defined: `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, `PAUSER_ROLE`, `UPGRADER_ROLE`
- **Test actors** pre-created: `deployer`, `owner`, `user1`, `user2`, `user3`, `attacker`
- **Token helpers:** `_mintGNUS()`, `_transferGNUS()`, `_getGNUSBalance()`, `_getTotalGNUSSupply()`
- **Role helpers:** `_grantMinterRole()`, `_grantPauserRole()`, `_grantUpgraderRole()`, `_hasMinterRole()`
- **Diamond helpers:** `_getFacets()`, `_getFacetAddress()`, `_getFacetFunctionSelectors()`
- **Assertion helpers:** `assertHasRole()`, `assertDoesNotHaveRole()`, `assertGNUSBalance()`, `assertAllSelectorsValid()`
- **Bounding utilities:** `_boundUint256()`, `_boundAddress()`
- **Revert decoding:** `_getRevertMsg()`
- **ERC1155Receiver** implementation for receiving ERC1155 tokens in tests

Inheritance chain:
```
Test (forge-std)
  -> DiamondFuzzBase (@diamondslab)
    -> GeniusDiamondTestBase (project)
      -> Individual test contracts
```

## Test Structure

### Unit Tests
Test files extend `Test` (forge-std) directly, using `DiamondDeployment` to load the deployed diamond.

```solidity
// From gnus-ai/test/foundry/unit/GNUSUnit.t.sol
contract GNUSUnitTest is Test {
    using DiamondForgeHelpers for address;

    address diamond;
    address deployer;

    function setUp() public {
        diamond = DiamondDeployment.getDiamondAddress();
        deployer = DiamondDeployment.getDeployerAddress();
        DiamondForgeHelpers.assertValidDiamond(diamond);
    }

    function test_DiamondDeployed() public view {
        assertNotEq(diamond, address(0), "Diamond address should not be zero");
        address diamondAddr = diamond;
        uint256 codeSize;
        assembly { codeSize := extcodesize(diamondAddr) }
        assertGt(codeSize, 0, "Diamond should have code deployed");
    }
}
```

### Fuzz Tests
Extend `GeniusDiamondTestBase`. Use `testFuzz_` prefix. Use `vm.assume()` for input constraints and `_boundUint256()`/`_boundAddress()` for input sanitization.

```solidity
// From gnus-ai/test/foundry/fuzz/ERC20Fuzz.t.sol
contract ERC20Fuzz is GeniusDiamondTestBase {
    function testFuzz_transfer(address to, uint256 amount) public {
        to = _boundAddress(to);
        vm.assume(to != address(this));
        vm.assume(to.code.length == 0);

        uint256 balance = _getGNUSBalance(address(this));
        amount = _boundUint256(amount, 0, balance);

        uint256 toBalanceBefore = _getGNUSBalance(to);
        _transferGNUS(address(this), to, amount);

        assertEq(_getGNUSBalance(address(this)), balance - amount, "Sender balance incorrect");
        assertEq(_getGNUSBalance(to), toBalanceBefore + amount, "Recipient balance incorrect");
    }
}
```

**Fuzz Config (foundry.toml):**
```toml
# Development
fuzz = { runs = 256, max_test_rejects = 65536, seed = "0x1234" }

# CI profile
[profile.ci]
fuzz = { runs = 10000 }

# Intensive profile
[profile.intense]
fuzz = { runs = 50000 }
```

### Invariant Tests
Use `invariant_` prefix on test functions. Two approaches observed:

**Approach 1 -- Direct Diamond Invariants** (extends `GeniusDiamondTestBase`):
```solidity
// From gnus-ai/test/foundry/invariant/DiamondCoreInvariant.t.sol
contract DiamondCoreInvariant is GeniusDiamondTestBase {
    function invariant_ownerNeverZero() public view {
        address currentOwner = _getDiamondOwner();
        assertTrue(currentOwner != address(0), "Diamond owner is address(0)");
    }

    function invariant_noSelectorOverlap() public view {
        bytes4[] memory selectors = _getDiamondSelectors();
        // Check for duplicate selectors across facets
        for (uint256 i = 0; i < selectors.length; i++) { ... }
    }
}
```

**Approach 2 -- Handler-Based Invariants** (uses `targetContract`):
```solidity
// From gnus-ai/test/foundry/invariant/DiamondCoreInvariant.t.sol
contract DiamondCoreInvariant is GeniusDiamondTestBase {
    GeniusDiamondHandler public handler;

    function setUp() public override {
        super.setUp();
        handler = new GeniusDiamondHandler();
        handler.setUp();
        targetContract(address(handler));  // Fuzzer targets the handler
    }

    function invariant_ownerNeverZero() public view { ... }
}
```

The handler (`GeniusDiamondHandler.sol`) provides bounded action functions with `handler_` prefix:
```solidity
function handler_transfer(uint256 actorSeed, uint256 recipientSeed, uint256 amount) public { ... }
function handler_approve(uint256 actorSeed, uint256 spenderSeed, uint256 amount) public { ... }
```

**Invariant Config (foundry.toml):**
```toml
invariant = { runs = 5, depth = 10, fail_on_revert = false }
```

### Security Tests
Dedicated security test files for specific attack vectors:

```solidity
// From gnus-ai/test/foundry/security/GNUSWithdrawLimiterSybilAttack.t.sol
contract GNUSWithdrawLimiterSybilAttack is GeniusDiamondTestBase {
    address[] public sybilAccounts;

    function setUp() public override {
        super.setUp();
        for (uint256 i = 0; i < 10; i++) {
            sybilAccounts.push(makeAddr(string(abi.encodePacked("sybil", i))));
        }
    }

    function testFuzz_cannotBypassLimitByDistributing(uint8 recipientCount) public {
        // Test that splitting withdrawals across multiple recipients still respects aggregate limit
        ...
        assertFalse(success, "Batch transfer should fail when total exceeds limit");
    }
}
```

### Integration Tests
Test full diamond deployment and facet wiring:

```solidity
// From gnus-ai/test/foundry/integration/BasicDiamondIntegration.t.sol
contract BasicDiamondIntegrationTest is Test {
    function setUp() public {
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new GeniusOwnershipFacet();

        // Deploy diamond
        diamond = new Diamond(owner, address(diamondCutFacet));

        // Add facets via diamondCut
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](2);
        // ... configure cuts ...
        DiamondCutFacet(address(diamond)).diamondCut(cuts, address(0), "");
    }

    function test_DiamondInitialization() public view { ... }
    function test_FacetIntrospection() public view { ... }
}
```

## Diamond Interaction Pattern

Tests interact with the diamond proxy through low-level `call()` / `staticcall()` with ABI-encoded function selectors. This is required because the diamond ABI is not known at test compile time.

```solidity
// Call a diamond function
bytes memory callData = abi.encodeWithSignature(
    "mint(address,uint256,uint256)",
    to,
    GNUS_TOKEN_ID,
    amount
);
(bool success, bytes memory returnData) = diamond.call(callData);

// Read from diamond
bytes memory callData = abi.encodeWithSignature(
    "balanceOf(address,uint256)",
    account,
    GNUS_TOKEN_ID
);
(bool success, bytes memory returnData) = diamond.staticcall(callData);
uint256 balance = abi.decode(returnData, (uint256));
```

Helper functions in `GeniusDiamondTestBase` wrap these patterns for common operations.

## Mocking

### Mock Contracts
Hand-written mock contracts in `gnus-ai/contracts/mocks/`:
| Mock | Purpose |
|------|---------|
| `MockERC20.sol` | Standard ERC20 token for testing token interactions |
| `MockBadERC20.sol` | Malicious ERC20 that returns false on transfer |
| `MockNonPayable.sol` | Contract that rejects ETH payments |
| `TransferHelperWrapper.sol` | Wraps TransferHelper for isolated unit testing |

No mocking framework (like `vm.mockCall`) is used. Mocks are deployed as real contracts.

### Foundry Cheatcodes Used
| Cheatcode | Purpose |
|-----------|---------|
| `vm.prank(address)` | Set `msg.sender` for next call |
| `vm.startPrank(address)` / `vm.stopPrank()` | Set `msg.sender` for multiple calls |
| `vm.assume(bool)` | Fuzz input constraint (skip if false) |
| `vm.expectRevert()` | Assert next call reverts |
| `vm.expectRevert(bytes)` | Assert next call reverts with specific data |
| `vm.label(address, string)` | Label address for trace readability |
| `makeAddr(string)` | Create deterministic address from label |
| `vm.warp(uint256)` | Set block timestamp |
| `vm.roll(uint256)` | Set block number |

## Fixtures and Test Data

### Test Token Amounts
```solidity
uint256 public constant INITIAL_GNUS_SUPPLY = 1000000 ether;  // 1M GNUS for testing
```

Test tokens are distributed via the base class `_setupInitialBalances()`:
- Owner mints `INITIAL_GNUS_SUPPLY` via bridge
- `user1`, `user2`, `user3` each receive `100000 ether`
- Test contract itself receives `100000 ether`

### Test Actors
Created via `makeAddr()` with descriptive labels:
```solidity
user1 = makeAddr("user1");
attacker = makeAddr("attacker");
sybilAccounts.push(makeAddr(string(abi.encodePacked("sybil", i))));
```

### Withdrawal Limiter Test Config
```solidity
uint256 constant DEFAULT_LIMIT = 100_000 ether;    // 100k GNUS
uint256 constant DEFAULT_WINDOW = 86400;           // 24 hours
uint256 constant DEFAULT_BIN_COUNT = 24;           // hourly bins
```

## Coverage

### Foundry Coverage
```bash
cd gnus-ai
yarn forge:coverage          # Runs `forge coverage`
```

### Hardhat Coverage
```bash
cd gnus-ai
yarn coverage                # Runs `npx hardhat coverage`
```
Uses the `solidity-coverage` Hardhat plugin.

### Coverage Targets
No explicit coverage threshold enforced in CI. The `foundry.toml` gas report is configured to report on all contracts (`gas_reports = ["*"]`).

## CI / Automated Testing

### No GitHub Actions Workflows
No `.github/workflows/` directory found at the repo root. CI configuration is located within the `gnus-ai/` subdirectory.

### Security Scanning Pipeline
Comprehensive script in `gnus-ai/package.json`:
```bash
yarn security-check
# Runs: audit + snyk:test + socket:scan + osv:scan + semgrep:scan + slither:scan + git-secrets:scan
```

Individual scans:
| Command | Tool | Purpose |
|---------|------|---------|
| `yarn audit` | Yarn | Dependency vulnerability audit |
| `yarn snyk:test` | Snyk | Dependency security scanning |
| `yarn socket:scan` | Socket.dev | Supply chain risk scanning |
| `yarn osv:scan` | OSV Scanner | Known vulnerability database check |
| `yarn semgrep:scan` | Semgrep | Static analysis with custom rules |
| `yarn slither:scan` | Slither | Solidity static analysis |
| `yarn git-secrets:scan` | git-secrets | Credential leak detection |

### Precommit Hooks
```bash
yarn precommit    # Runs: lint-staged + yarn audit + yarn test
```

## Test Types Summary

| Type | Location | Framework | Pattern |
|------|----------|-----------|---------|
| Unit | `test/foundry/unit/` | Foundry | `test_` prefix, extends `Test` |
| Fuzz | `test/foundry/fuzz/` | Foundry | `testFuzz_` prefix, extends `GeniusDiamondTestBase` |
| Invariant (direct) | `test/foundry/invariant/` | Foundry | `invariant_` prefix, extends `GeniusDiamondTestBase` |
| Invariant (handler) | `test/foundry/invariant/` | Foundry | `invariant_` + `targetContract(handler)` |
| Security | `test/foundry/security/` | Foundry | `testFuzz_` prefix, attack-specific scenarios |
| Integration | `test/foundry/integration/` | Foundry | `test_` prefix, deploys real diamonds + facets |
| POC | `test/foundry/poc/` | Foundry | `test_` prefix, experimental/debug tests |
| Multi-chain | Via Hardhat | Hardhat | `test-multichain` task |
| Legacy | `test/` (repo root) | Node.js | `testcalc.js` -- manual token calculation test |

---

*Testing analysis: 2026-06-06*
