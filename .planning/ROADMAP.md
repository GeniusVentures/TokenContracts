# Roadmap: v1.1 Proxy Completion & Production Readiness

**Created:** 2026-08-28
**Parent-level milestone** — phases execute inside submodule `.planning/` roots per `PROJECT.md` Execution Routing. Phase numbers continue from v1.0.

## Phase Summary

| #   | Phase                            | Goal                                                                  | Requirements       | Executes in         |
| --- | -------------------------------- | --------------------------------------------------------------------- | ------------------ | ------------------- |
| 16  | ERC-20 Proxy Hardening           | Real allowance semantics + immutable init on the proxy diamond        | PROXY-01, 02, 04   | `erc20-gnus-proxy/` |
| 17  | Test-Suite Determinism           | Full-suite green, no flakes, no known-stale failures                  | TEST-04, 05, 06    | `gnus-ai/`          |
| 18  | Scanner Triage Upgrades          | slither + semgrep gates expressed as real severity triage             | SEC-09, 10         | `gnus-ai/`          |
| 19  | Dependency & Secrets Hygiene     | OSV remainder refreshed; every git-secrets hit dispositioned          | DEP-02, SEC-11     | `gnus-ai/`          |
| 20  | BridgeIn Activation Readiness    | #363 gate checked; bridgeIn activated or readiness-shipped            | BRIDGE-17          | `gnus-ai/`          |
| 21  | Child-NFT Economics Research     | Treasury/swap/routing feasibility proven or refuted with evidence     | NFT-01, 02, 03     | cross-repo          |
| 22  | Child-NFT Economics Build        | Implement what Phase 21 validated (scope confirmed at 21 exit)        | NFT-04, 05, 06     | `gnus-ai/`          |

Dependencies: Phase 22 depends on Phase 21 (research-exit scope confirmation). Phases 16–20 are independent of each other and can run in any order or parallel; recommended order below puts cheap gnus-ai debt first to stabilize baselines.

## Phase Details

### Phase 16: ERC-20 Proxy Hardening

**Goal**: Make the erc20-gnus-proxy diamond DEX-safe — real amount-specific ERC-20 allowances and immutable one-shot configuration — with the nested gnus-ai-contracts pin current.
**Depends on**: nothing (independent). Executes as `erc20-gnus-proxy` Phase 1 in its own `.planning/`.
**Success criteria:**
1. `approve(spender, amount)`/`allowance()`/`transferFrom()` exhibit real ERC-20 allowance semantics (DEX-flow test passes)
2. `initializeERC20Proxy` is one-shot; all four config fields immutable after init (revert proven in tests)
3. Nested gnus-ai-contracts gitlink ≥ d731384, lockfile/install green
4. Sibling-repo suite green; no gnus-ai regression (proxy is standalone)

### Phase 17: Test-Suite Determinism

**Goal**: Eliminate every known non-deterministic or known-stale failure in the gnus-ai suites at the root cause.
**Depends on**: nothing. Baselines: Hardhat 666/2/0 with 1 known-stale failure; Foundry 215/2/3 with setUp reverts + flaky invariant.
**Success criteria:**
1. GNUSControlStorage "should return initial protocol info" passes in the FULL suite (root fix, no test-side guard)
2. AccessControlInvariant passes across N consecutive runs without seed-luck (config seeded or invariant aligned to handler)
3. SafeSingleShotUpgrade + SafeDiamondCut setUp green
4. New baselines recorded with zero known-stale/failing entries

### Phase 18: Scanner Triage Upgrades

**Goal**: Express scanner severity gates as real triage instead of version-specific exit-code workarounds.
**Depends on**: nothing (17's clean baselines help but are not required).
**Success criteria:**
1. slither on a triage-capable line; known Phase-9 FPs triaged in config, gate exits 0 with triage visible
2. semgrep `unsafe-external-call` pattern parses and executes
3. CI semgrep step promoted to hard gate (continue-on-error dropped) on a stable recorded baseline

### Phase 19: Dependency & Secrets Hygiene

**Goal**: Close the OSV advisory remainder and give every git-secrets hit an explicit provenance disposition.
**Depends on**: nothing. Owner participation likely for git-secrets rulings and any OSV residuals.
**Success criteria:**
1. `yarn osv:scan` exit 0, or every residual advisory carries an owner-ruling disposition
2. All 37 git-secrets hits dispositioned (fixture keys proven test-only, remediated, or `.gitallowed` by owner ruling)
3. `yarn install --immutable` + audit gates still green after resolutions

### Phase 20: BridgeIn Activation Readiness

**Goal**: BRIDGE-17 resolved either way — activation if the external gate closed, packaged readiness if not.
**Depends on**: nothing (external gate: SuperGenius #363). Verify state at phase start.
**Success criteria:**
1. SuperGenius #363 state verified and recorded in the phase record
2. If closed: bridgeIn activated on Sepolia (attestor set bootstrapped, first certificate processed, epoch advanced)
3. If open: activation runbook + config shipped; BRIDGE-17 remains the only blocker
4. Exporter ABI doc §5 gate record updated to current state

### Phase 21: Child-NFT Economics Research

**Goal**: Produce evidence-backed feasibility findings for child-NFT treasuries, NFT→GNUS swap, and external swap routing against the Phase 9 conversion-native model.
**Depends on**: nothing. Research phase — no implementation.
**Success criteria:**
1. NFT-01 finding: can 2nd+ generation NFTs hold GNUS treasuries — proven feasible with mechanism sketch, or refuted with evidence
2. NFT-02 finding: swap mechanism compatible with `GNUSTreasury.convert()` conservation — design or refutation
3. NFT-03 finding: external swap/liquidity routing — validated pattern or refutation
4. Phase 22 scope confirmed from findings (each NFT-04/05/06 go/no-go recorded)

### Phase 22: Child-NFT Economics Build

**Goal**: Implement what Phase 21 validated, under the conversion-native conservation model.
**Depends on**: Phase 21.
**Success criteria:**
1. Every go-item from Phase 21 implemented with tests on the gnus-ai diamond
2. Conservation invariants extended and green over any new treasury/swap surface
3. No-go items moved to Out of Scope with the refuting evidence referenced
4. Full-suite + security gates green
