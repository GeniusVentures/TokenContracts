# Codebase Concerns

**Analysis Date:** 2026-06-06

---

## Critical Architecture Issues

These issues were identified in the architecture analysis at `.planning/Update-Smart-Contracts-Architecture.md` and confirmed by direct code inspection.

### 1. Asymmetric Burn/Mint Backing Invariant (CRITICAL)

**Issue:** `beforeMint()` in `GNUSNFTFactory.sol` only burns GNUS for direct children of GNUS (where `(id >> 128) == GNUS_TOKEN_ID`), but `withdraw()` in `GNUSBridge.sol` allows any created non-GNUS token to be redeemed for GNUS.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` lines 96-107 (`beforeMint`)
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` lines 149-169 (`withdraw`)

**Code evidence -- the burn guard (beforeMint):**
```solidity
// Line 102: Only burns GNUS for direct children
if ((id >> 128) == GNUS_TOKEN_ID) {
    uint256 convAmount = amount * nft.exchangeRate;
    require(balanceOf(sender, GNUS_TOKEN_ID) >= convAmount, "Not enough GNUS_TOKEN to burn");
    _burn(sender, GNUS_TOKEN_ID, convAmount);
}
```

**Code evidence -- the withdraw guard:**
```solidity
// Lines 151-152: withdraw() only checks existence and non-GNUS, not backing
require(GNUSNFTFactoryStorage.layout().NFTs[id].nftCreated, "Token not created.");
require(id != GNUS_TOKEN_ID, "Cannot withdraw GNUS tokens.");
```

**Impact:** A descendant token (e.g., child-of-child where `parentID != GNUS_TOKEN_ID`) can be minted without burning any GNUS, but then withdrawn for GNUS via the bridge. This is an unbacked GNUS mint path. Any creator with `CREATOR_ROLE` or child token creator permission can exploit this.

**Fix approach:**
- Restrict `withdraw()` to only token IDs where `(id >> 128) == GNUS_TOKEN_ID` (direct children) or
- Add an explicit `redeemable` boolean flag to the NFT struct and check it in `withdraw()`, with separate logic to fund redeemability with actual GNUS reserves

**Test coverage gap:** No test verifies that descendant tokens (depth > 1) cannot be withdrawn for GNUS.

---

### 2. Exchange Rate Math Inconsistency (CRITICAL)

**Issue:** The exchange rate semantic is ambiguous and mathematically inconsistent between mint and withdraw paths.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` line 103: `convAmount = amount * nft.exchangeRate` (multiplication)
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` line 160: `convAmount = amount / exchangeRate` (division)

**Code evidence:**
```solidity
// beforeMint (line 103): amount * exchangeRate
uint256 convAmount = amount * nft.exchangeRate;

// withdraw (line 160): amount / exchangeRate
uint256 convAmount = amount / exchangeRate;
```

**Impact:** These two formulas cannot both be correct simultaneously for any `exchangeRate > 1`. The comment on line 159 says "Exchange rate = NFTs per GNUS, so divide to get GNUS amount" while the mint path multiplies. This creates an economic spread: if the rate is "NFTs per GNUS", mint requires burning more GNUS than redeem returns; if the rate is "GNUS per NFT", withdraw returns too few GNUS.

**Additional issue:** Integer division on line 160 means any `amount < exchangeRate` silently withdraws 0 GNUS (protected only by the `require(amount >= exchangeRate)` on line 157, which prevents dust but doesn't guarantee fair rounding).

**Fix approach:**
- Define `exchangeRate` unambiguously (e.g., "GNUS per child token unit, scaled by 1e18")
- Use the same formula in both directions: `amount * exchangeRate / 1e18` for both burn and redeem
- Add remainder/rounding handling

---

### 3. No Per-Child GNUS Treasury/Reserve Tracking (HIGH)

**Issue:** There is no on-chain accounting of how much GNUS backing exists for any child token. The backing is purely implicit (historical burns). The NFT struct has no reserve field.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactoryStorage.sol` lines 10-19 (NFT struct)
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` lines 149-169 (withdraw)

**Code evidence -- NFT struct has no reserve field:**
```solidity
struct NFT {
    string name;
    string symbol;
    string uri;
    uint256 exchangeRate;
    uint256 maxSupply;
    address creator;
    uint128 childCurIndex;
    bool nftCreated;
    // MISSING: uint256 gnusReserve or similar backing field
}
```

**Impact:**
- Impossible to verify on-chain that a child token has sufficient GNUS backing
- No solvency checks before withdraw
- No way to detect if total redeemable child supply exceeds historical GNUS burns
- Cannot audit per-token economic health

**Fix approach:** Add reserve tracking fields (e.g., `gnusReserve`, `redeemableSupply`) to the NFT struct or to a separate redemption configuration mapping. Move from burn-on-mint to lock-in-reserve model as recommended in the architecture analysis.

---

### 4. Hierarchical ID Collision Risk (HIGH)

**Issue:** Child token IDs are computed as `(parentID << 128) | nft.childCurIndex++` without checking if the computed ID is already in use. For deeper hierarchies, a left-shift by 128 on an already-composed hierarchical ID discards the upper 128 bits.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` line 181: `uint256 newTokenID = (parentID << 128) | nft.childCurIndex++;`
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` lines 153-194 (`createNFTs`)

**Impact:** A token created as child-of-child `A` (where `A` was created under GNUS with `childCurIndex=5`) would have `(A << 128) | childCurIndex`. But `A = (GNUS_TOKEN_ID << 128) | 5 = 5`, so `(5 << 128) | childCurIndex` shares its parent bits with any token whose parent ID has the same upper 128 bits. Meanwhile, `GNUS_TOKEN_ID = 0` means direct children of GNUS always get IDs `0 | index = childCurIndex`. A depth-2 descendant with `childCurIndex` matching a depth-1 token's index could collide.

**Note:** The NFT struct at the new ID is overwritten without a `require(!NFTs[newTokenID].nftCreated)` check on line 182.

**Fix approach:**
- Add `require(!GNUSNFTFactoryStorage.layout().NFTs[newTokenID].nftCreated, "ID collision")` before assignment
- Reconsider the left-shift hierarchy encoding -- consider using a deterministic hash or separate parent/child tracking
- Add max depth enforcement

---

### 5. ERC-20 Proxy Approval Model Is All-or-Nothing (HIGH)

**Issue:** The ERC-20 proxy maps `approve()` to ERC-1155 `setApprovalForAll()`, making allowances binary (0 or uint256.max) rather than amount-specific. This is not standard ERC-20 behavior.

**Files:**
- `erc20-gnus-proxy/contracts/erc20-gnus-proxy/ERC20ProxyFacet.sol` lines 101-103 (`allowance`), lines 111-115 (`approve`), lines 124-130 (`transferFrom`)

**Code evidence:**
```solidity
// allowance() returns max uint256 or 0 (line 102)
function allowance(address owner, address spender) public view override returns (uint256) {
    return ERC20ProxyStorage.layout().erc1155Contract.isApprovedForAll(owner, spender) ? type(uint256).max : 0;
}

// approve() maps to setApprovalForAll (line 112)
function approve(address spender, uint256 amount) public override returns (bool) {
    ERC20ProxyStorage.layout().erc1155Contract.setApprovalForAll(spender, amount > 0);
    emit Approval(msg.sender, spender, amount);
    return true;
}

// transferFrom requires ERC-1155 operator approval (line 126)
require(l.erc1155Contract.isApprovedForAll(sender, msg.sender), "ERC20Proxy: transfer caller is not approved");
```

**Additional concern:** `approve()` emits Approval with the `amount` parameter, but the actual permission change is `setApprovalForAll(spender, amount > 0)`. If a user calls `approve(spender, 100)`, Approval emits with 100, but the spender actually gets unlimited allowance. This is misleading to integrators.

**Additional concern:** `setApprovalForAll` sets operator approval for ALL ERC-1155 token IDs, not just the proxied child token ID. Granting approval to a DEX router exposes the user's entire ERC-1155 balance, not just the proxied child token.

**Fix approach:**
- Implement real ERC-20 allowance tracking in the proxy's own storage (similar to how `GNUSBridge` tracks allowances in `ERC20Storage`)
- Do NOT map `approve()` to `setApprovalForAll()`
- Keep the proxy's allowance independent of the underlying ERC-1155

---

### 6. Bridge Uses Burn/Mint Model Instead of Lock/Release (HIGH)

**Issue:** `bridgeOut()` burns tokens on the source chain and emits an event, while `withdraw()` mints new GNUS on redemption. There is no escrow vault, no bridge state machine, and no replay protection.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` lines 177-191 (`bridgeOut`)
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` lines 149-169 (`withdraw`)

**Code evidence:**
```solidity
// bridgeOut burns tokens (line 183)
function bridgeOut(uint256 amount, uint256 id, uint256 destChainID) external {
    ...
    _burn(sender, id, amount);
    emit BridgeSourceBurned(sender, id, amount, chainID, destChainID);
}
```

**Impact:**
- The destination chain must re-mint tokens, which is a privileged operation requiring MINTER_ROLE
- No on-chain inventory tracking for vault balances
- No state machine for bridge transfers (pending, confirmed, released, cancelled)
- No `processedMessages` mapping for replay protection
- No chain allowlisting or per-chain vault caps
- The event emission alone (`BridgeSourceBurned`) is insufficient for trustless bridging -- a trusted relayer must observe and act on it

**Fix approach:**
- Implement lock/release vaults: `bridgeOut` locks tokens in a source-chain vault, `bridgeIn` releases pre-funded tokens from a destination-chain vault
- Add `TransferStatus` state machine (NONE -> LOCKED -> CONFIRMED -> RELEASED)
- Add `mapping(bytes32 => bool) public processedMessages` for replay protection
- Add per-chain and per-token vault caps

---

## Medium Severity Issues

### 7. Exchange Rate Must Be > 0 Only Enforced for Direct GNUS Children

**Issue:** The exchange rate minimum check is only enforced when creating children of GNUS, not for deeper descendants or child tokens made redeemable later.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` lines 178-180

**Code evidence:**
```solidity
if (parentID == GNUS_TOKEN_ID) {
    require(exchRates[i] > 0, "Exchange Rate has to be > 0 for creating a new Child NFT of GNUS");
}
```

**Impact:** A descendant token can be created with `exchangeRate = 0`. If it is later made withdrawable, `require(exchangeRate > 0)` on line 156 of `GNUSBridge.sol` would catch it, but only at withdrawal time. A stronger invariant would be to enforce `exchangeRate > 0` for all tokens at creation if the system supports redeemability.

---

### 8. GNUS Token Balance Check in beforeMint Uses ERC-1155 Balance, Not ERC-20 Allowance

**Issue:** `beforeMint()` checks `balanceOf(sender, GNUS_TOKEN_ID)` but burns GNUS directly via `_burn(sender, GNUS_TOKEN_ID, convAmount)`. There is no allowance check for the NFT factory to spend the sender's GNUS tokens. The `mint()` function on `GNUSNFTFactory` burns GNUS from the sender without an explicit approval step.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` lines 102-105

**Code evidence:**
```solidity
uint256 convAmount = amount * nft.exchangeRate;
require(balanceOf(sender, GNUS_TOKEN_ID) >= convAmount, "Not enough GNUS_TOKEN to burn");
_burn(sender, GNUS_TOKEN_ID, convAmount);
```

**Impact:** The `mint()` function on `GNUSNFTFactory` (not on `GNUSBridge`) directly burns GNUS from `_msgSender()` without requiring the sender to first `approve()` the factory contract. This means any external contract calling `mint()` could have its GNUS burned unexpectedly. In the current Diamond architecture, the factory and bridge share the same storage, so internal calls work -- but this is fragile.

---

### 9. Withdraw Limiter Only Applied on ERC-1155 GNUS Transfers (Not ERC-20 Interface)

**Issue:** The withdraw limiter is applied in `_beforeTokenTransfer` for ERC-1155 transfer paths but uses `GNUS_TOKEN_ID` filtering. The ERC-20 `transfer()` function on `GNUSBridge` calls `_safeTransferFrom(from, to, GNUS_TOKEN_ID, ...)` which goes through `_beforeTokenTransfer`, so it is covered. However, `withdraw()` calls `_mintWithBridgeFee` which calls `_mint`, and `_mint` calls `_beforeTokenTransfer` with `from == address(0)`, which means the limiter code block at lines 45-61 of `GNUSERC1155MaxSupply.sol` skips the check because `from != address(0)` is false for mints.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSERC1155MaxSupply.sol` lines 45-61
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` lines 149-169

**Mitigation:** `withdraw()` has its own limiter call on line 164: `GNUSWithdrawLimiterStorage.checkAndRecordWithdraw(sender, convAmount);` -- so the withdraw path is covered. But the architecture relies on two separate limiter insertion points, which is fragile.

---

### 10. `mint()` on GNUSNFTFactory vs `mint()` on GNUSBridge -- Two Different Semantics

**Issue:** `GNUSNFTFactory.mint()` burns GNUS from the sender and mints child tokens. `GNUSBridge.mint()` mints tokens directly (requires MINTER_ROLE). Both are named `mint()` but have completely different security models.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` lines 115-118
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` lines 84-86, 95-97

**Impact:** In the Diamond pattern, function selectors determine dispatch. If both facets define `mint(address,uint256)`, only one will be registered depending on facet cut order. This could cause silent behavioral changes. The code has overloading (`mint(address,uint256)` vs `mint(address,uint256,uint256)`) plus `mint(address,uint256,uint256,bytes)` but the selectors don't conflict, so this is a naming clarity issue rather than a selector conflict.

---

### 11. `createNFTs` Array Length Validation Does Not Prevent Empty Arrays

**Issue:** The length check requires all arrays to be equal length, but does not require `names.length > 0`. Passing empty arrays would succeed with no effect.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` lines 165-176

**Impact:** Minor -- wastes gas but has no security implication. Would be cleaner to `require(names.length > 0)`.

---

## Technical Debt

### 12. Zero-Address Checks Inconsistent

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` line 130: `require(to != address(0), "ERC1155: mint to the zero address")`
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` line 99: `require(to != address(0), "ERC1155: mint to the zero address")`

**Issue:** `mint()` on `GNUSBridge` has zero-address protection in `_mint`, but `mint(address user, uint256 amount)` at line 84 does not independently check. The internal `_mint` catches it, but better practice would be to check at the public entry point.

---

### 13. No Events for `withdraw()` Transaction

**Issue:** `withdraw()` in `GNUSBridge.sol` burns child tokens and mints GNUS but does not emit a dedicated event. It only emits the standard `TransferSingle` from `_burn` and `Transfer` from `_mintWithBridgeFee`. There is no `ChildTokenRedeemed` event.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` lines 149-169

**Impact:** Off-chain indexers and monitoring tools cannot easily distinguish withdraw events from normal transfers. The `BridgeSourceBurned` event is only emitted by `bridgeOut()`.

---

### 14. `GNUSContractAssets.withdrawToken()` Checks `token == address(this)` Not the Actual GNUS Address

**Issue:** The GNUS token in the Diamond pattern is the diamond contract itself (not a separate ERC-20 token address). The check `if (token == address(this))` prevents withdrawing the diamond's native assets. However, `GNUSContractAssets` is a facet of the diamond, so `address(this)` is the diamond. The check prevents withdrawing any ERC-20 token that happens to have the same address as the diamond, not specifically the GNUS token. This is correct in the Diamond context but the error message "CannotWithdrawGNUS" is misleading because it would also prevent withdrawing any other token at that address.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSContractAssets.sol` lines 42-44

---

### 15. `ProtocolVersion` Incremented to 230 as a Magic Number

**Issue:** `GNUSControl_Initialize230()` checks `protocolVersion < 230` and sets it to `230`. Version 230 is a magic number -- there is no obvious mapping between contract versions and protocol version numbers.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSControl.sol` lines 48-56

**Impact:** Confusing for auditors and future developers. Consider using semantic versioning encoded as a uint256 or documented version mapping.

---

## Security Considerations

### 16. `ERC1155ProxyOperator.isApprovedForAll()` Auto-Approves Proxy Operators

**Issue:** Any address with `NFT_PROXY_OPERATOR_ROLE` is automatically approved for all token holders. This is a deliberate feature for gas-free listings, but it is a powerful privilege.

**Files:**
- `gnus-ai/contracts/gnus-ai/ERC1155ProxyOperator.sol` lines 28-39

**Code evidence:**
```solidity
function isApprovedForAll(address account, address operator) public view returns (bool isApproved) {
    if (hasRole(NFT_PROXY_OPERATOR_ROLE, operator)) {
        return true;  // Auto-approve ALL proxy operators for ALL accounts
    }
    return ERC1155Storage.layout()._operatorApprovals[account][operator];
}
```

**Impact:** Any address granted `NFT_PROXY_OPERATOR_ROLE` can transfer any ERC-1155 tokens from any holder. This role must be extremely tightly controlled.

---

### 17. `DIAMOND_INIT_FACET.diamondInitialize250()` Lacks Access Control

**Issue:** `diamondInitialize250()` is public and has no access control modifier. It grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `UPGRADER_ROLE` to `_msgSender()`.

**Files:**
- `gnus-ai/contracts/gnus-ai/DiamondInitFacet.sol` lines 39-53

**Code evidence:**
```solidity
function diamondInitialize250() public {  // No access control!
    address sender = _msgSender();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(UPGRADER_ROLE, _msgSender());
    ...
}
```

**Impact:** This function appears to be called only during diamond initialization (which has its own protections), but if it can be called post-initialization, it would grant full roles to the caller. In a Diamond pattern, this function is typically called as an `init` function during the diamond cut, which provides its own access control, but the function itself has no guard.

**Mitigation:** Consider adding `onlySuperAdminRole` or `initializer` modifier, or documenting that this function MUST only be called during diamond deployment.

---

### 18. Delegatecall in GNUSControlStorage Without Reentrancy Guard

**Issue:** `GNUSControlStorage.callFacetDelegate()` performs a low-level `delegatecall` to a facet address. This is the standard Diamond dispatch mechanism, but there is no reentrancy guard visible in this utility.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSControlStorage.sol` lines 61-67

**Impact:** Standard Diamond concern -- delegatecall allows the callee to execute in the caller's context with full storage access. This is inherent to the Diamond pattern but worth noting.

---

## Performance and Gas Considerations

### 19. `_mintWithBridgeFee` Modifies Amount In-Place (Side Effect)

**Issue:** The `amount` parameter is modified in-place:
```solidity
function _mintWithBridgeFee(address user, uint256 tokenID, uint256 amount) internal {
    uint256 bridgeFee = GNUSControlStorage.layout().bridgeFee;
    if (bridgeFee != 0) {
        amount = (amount * (FEE_DOMINATOR - bridgeFee)) / FEE_DOMINATOR;
    }
    _mint(user, tokenID, amount, "");
    emit Transfer(address(0), user, amount);
}
```

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` lines 69-76

**Impact:** The emitted `Transfer` event uses the reduced amount, but callers may expect the original amount. In `withdraw()` (line 168), the `convAmount` is pre-computed and passed through the fee reduction, so the caller of `withdraw()` gets fewer tokens than expected if a bridge fee is active. This is intentional but poorly documented.

---

### 20. Withdraw Limiter Bin Array Grows Without Bound for New Accounts

**Issue:** On first withdrawal, `checkAndRecordWithdraw` pushes `binCount` entries into the `bins` array. For the default config, this is 24 entries. This is reasonable, but the array never shrinks.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSWithdrawLimiterStorage.sol` lines 196-202

**Impact:** Gas cost for first withdrawal is higher than subsequent ones. Not a major issue but worth noting for gas-sensitive deployments.

---

## Test Coverage Gaps

### 21. No Descendant Token Withdrawal Tests

**Files:**
- `gnus-ai/test/foundry/fuzz/BridgeFuzz.t.sol` -- only tests GNUS_TOKEN_ID bridge operations
- `gnus-ai/test/foundry/invariant/BridgeInvariant.t.sol` -- only checks totalSupply consistency, not child token flows
- `gnus-ai/test/foundry/invariant/EconomicInvariant.t.sol` -- only checks totalSupply and tracked balances

**What's not tested:** There are no tests verifying that:
- A depth-2 child token (child of child) cannot be withdrawn for GNUS
- The asymmetric burn/mint invariant (GNUS burned on child mint >= GNUS minted on child withdraw)
- `exchangeRate` consistency between mint and withdraw paths
- ID collision scenarios for nested hierarchies

**Priority:** HIGH

---

### 22. Bridge Invariant Tests Are Minimal

**Files:**
- `gnus-ai/test/foundry/invariant/BridgeInvariant.t.sol` -- only 2 view tests that check `totalSupply >= 0`
- `gnus-ai/test/foundry/fuzz/BridgeFuzz.t.sol` -- only tests basic bridgeOut with GNUS token ID

**What's not tested:**
- Chain ID validation (`destChainID != chainID`)
- Replay of bridgeOut events
- Bridge fee calculation correctness
- Multiple bridge operations and supply tracking
- Cross-contract state (no actual cross-chain tests possible in Foundry, but state transitions should be validated)

**Priority:** MEDIUM

---

### 23. ERC-20 Proxy Tests Are Inaccessible

**Issue:** The ERC-20 proxy contract lives in a separate directory (`erc20-gnus-proxy/`) and appears to have its own test infrastructure that was not explored. Tests for the approval model incompatibility (issue #5) are important.

**Directory:** `erc20-gnus-proxy/`

---

## Fragile Areas

### 24. Diamond Facet Selector Overlap Risk

**Issue:** Multiple facets expose common functions (`supportsInterface`, `totalSupply`, `balanceOf`, `mint`). In the Diamond pattern, function selectors must be unique across all facets. If two facets define the same function signature, the diamond cut order determines which one is used.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` -- `mint(address,uint256)`, `mint(address,uint256,uint256)`, `totalSupply()`, `balanceOf(address)`
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactory.sol` -- `mint(address,uint256,uint256,bytes)`, `totalSupply(uint256)`, `balanceOf(address,uint256)`
- `gnus-ai/contracts/gnus-ai/ERC1155ProxyOperator.sol` -- `totalSupply(uint256)`, `isApprovedForAll(address,address)`

**Mitigation:** The overloaded signatures have different parameter types so selectors don't collide, but audit diligence is needed for each diamond cut to ensure no selector overlap.

---

### 25. `exchangeRate` Is a uint256 Without Fixed-Point Convention

**Issue:** The `exchangeRate` field is a plain `uint256`. The comment says "Exchange rate for withdrawing to GNUS" but does not define the scale. If the rate is "NFTs per GNUS", values must be > 1 and integer division in withdraw can lose precision. If the rate is "GNUS per NFT" at 1e18 scale, the mint multiplication `amount * exchangeRate / 1e18` is not present.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSNFTFactoryStorage.sol` line 14

**Impact:** Without a clear fixed-point convention, `exchangeRate` cannot be used correctly by external integrators. The math in `beforeMint` and `withdraw` is incompatible (see issue #2).

---

## Dependencies at Risk

### 26. OpenZeppelin Diamond Upgradeable Contracts via @gnus.ai Package

**Issue:** The contracts import from `@gnus.ai/contracts-upgradeable-diamond/` which appears to be a custom fork of OpenZeppelin contracts adapted for the Diamond pattern. The `gnus-ai/artifacts/` directory contains copies.

**Impact:** If these are unmaintained or diverge from upstream OpenZeppelin, security patches may not be applied. This is not necessarily a problem if the @gnus.ai contracts are actively maintained, but the dependency should be tracked.

---

### 27. Foundry Test Setup Uses Deployed Diamond Address from JSON

**Issue:** The test base reads diamond deployer and address from a JSON file via `DiamondDeployment.getDiamondAddress()`. If the deployment JSON is stale or missing, tests cannot run.

**Files:**
- `gnus-ai/test/foundry/base/GeniusDiamondTestBase.sol` lines 45-47
- `gnus-ai/diamonds/GeniusDiamond/deployments/deployments.json`

---

## Missing Critical Features

### 28. No Bridge State Machine

The bridge has a simple burn-and-emit model with no on-chain tracking of bridge transfer lifecycle. A proper bridge needs:

- Transfer status tracking (NONE -> LOCKED -> CONFIRMED -> RELEASED -> FINALIZED)
- Processed message repository for replay protection
- Per-chain vault accounting
- Release authorization verification (multisig or threshold signatures)

**Files:** `gnus-ai/contracts/gnus-ai/GNUSBridge.sol`

---

### 29. No Pause or Emergency Stop for Bridge Operations

Neither `bridgeOut()` nor `withdraw()` are pausable. There is no mechanism to halt bridge operations in an emergency. The parent `GNUSERC1155MaxSupply` has pausable transfers via `_beforeTokenTransfer`'s `whenNotPaused` modifier, but the withdraw path (mint) is not covered because `whenNotPaused` is inherited from ERC1155Upgradeable.

**Files:**
- `gnus-ai/contracts/gnus-ai/GNUSBridge.sol` -- no pausable modifier on `withdraw()` or `bridgeOut()`
- `gnus-ai/contracts/gnus-ai/GNUSERC1155MaxSupply.sol` line 40 -- `whenNotPaused` on `_beforeTokenTransfer`

**Verification needed:** Check whether `withdraw()` -> `_mint()` -> `_beforeTokenTransfer()` path actually requires `whenNotPaused`.

---

### 30. No On-Chain Solvency View Functions

There are no functions to query:
- Total GNUS backing for a child token
- Solvency ratio (backing / redeemable supply)
- Global GNUS reserve across all redeemable children
- Bridge vault balances per chain

**Files:** All contract files lack these view functions.

---

*Concerns audit: 2026-06-06*
