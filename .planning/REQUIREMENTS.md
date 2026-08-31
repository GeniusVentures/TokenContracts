# Requirements: v1.1 Proxy Completion & Production Readiness

**Created:** 2026-08-28
**Status:** Active (parent-level; execution routed per `PROJECT.md`)

## v1.1 Requirements

### ERC-20 Proxy (executes in `erc20-gnus-proxy/`)

- [x] **PROXY-01**: Real amount-specific ERC-20 allowances on the erc20-gnus-proxy contract — `_allowances` mapping; `approve(spender, amount)` sets a real allowance (NOT `setApprovalForAll`); `transferFrom()` spends via `_spendAllowance()`. Carried from gnus-ai v1.0 (deferred); already Active in `erc20-gnus-proxy/.planning/PROJECT.md`.
- [x] **PROXY-02**: Immutable proxy configuration — one-shot initialization of `childTokenId`, `erc1155Contract`, `name`, `symbol` on the erc20-gnus-proxy contract. Carried from gnus-ai v1.0 (deferred); already Active in the sibling.
- [x] **PROXY-04**: Nested gnus-ai-contracts submodule pin bumped to ≥ d731384 in erc20-gnus-proxy (redeem-adapter parity with the Phase 11 `GNUSRedeemAdapter`, issue #9).

### Bridge Activation (executes in `gnus-ai/`)

- [ ] **BRIDGE-17**: Gate-checked bridgeIn activation — verify SuperGenius #363 state; if closed, activate bridgeIn (Sepolia); if open, ship EVM-side readiness (activation runbook + config) and block only on activation. Carried from v1.0 (external gate). Gate record: `gnus-ai/docs/Secure-BridgeIn-Exporter-ABI.md` §5.

### Test-Suite Cleanup (executes in `gnus-ai/`)

- [ ] **TEST-04**: GNUSControlStorage "should return initial protocol info" passes in the FULL suite — root fix (idempotent shared provenance initializer; cross-suite pollution), no test-side workaround.
- [ ] **TEST-05**: AccessControlInvariant deterministic across runs — seed the invariant config or align the invariant with the handler's grant surface (gnus-ai 07-04 recorded root cause).
- [ ] **TEST-06**: Phase 08.1 Safe setUp reverts resolved — SafeSingleShotUpgrade + SafeDiamondCut tests green.

### Scanner Upgrades (executes in `gnus-ai/`)

- [ ] **SEC-09**: slither upgraded to a triage-capable line; the severity gate expressed via triage config (replaces the `--fail-none`-only workaround settled on slither 0.11.5).
- [ ] **SEC-10**: semgrep `unsafe-external-call` pattern parses and runs (fixed pattern); CI semgrep step promoted from continue-on-error advisory to hard gate on a stable baseline.

### Dependency & Secrets Hygiene (executes in `gnus-ai/`)

- [ ] **DEP-02**: OSV 115-advisory remainder, round 2 — range-qualified resolutions for the axios/undici/handlebars/fast-xml-parser paths; `yarn osv:scan` exits 0 or every residual is dispositioned by owner ruling.
- [ ] **SEC-11**: git-secrets 37 prohibited-pattern hits dispositioned — each proven legitimate (test fixtures, documented keys) or remediated; `.gitallowed` additions only by owner ruling, never silent suppression.

### Child-NFT Economics (research → implement)

- [ ] **NFT-01**: Research — can child NFTs (2nd+ generation) hold GNUS token treasuries for token swap operations? Feasibility + security analysis against the Phase 9 conversion-native model.
- [ ] **NFT-02**: Research — childToken/grandchild NFT→GNUS swap mechanism against `GNUSTreasury.convert()`: allow child NFT holders to swap their tokens for GNUS from the treasury.
- [ ] **NFT-03**: Research — GNUS treasury transfer to external swap/liquidity contracts: pipe treasury GNUS to a designated swap contract.
- [ ] **NFT-04**: Implement child-NFT GNUS treasuries per NFT-01 findings. Scope confirmed at the research phase's exit; infeasible/insecure findings move this to Out of Scope with reason.
- [ ] **NFT-05**: Implement NFT→GNUS swap per NFT-02 findings. Same research-exit condition.
- [ ] **NFT-06**: Implement external swap routing per NFT-03 findings (only if findings validate the pattern). Same research-exit condition.

## Future Requirements

- Multisig/timelock for super admin — governance phase.
- GNUSNFTCollectionName facet consolidation — low-priority cleanup pass (gnus-ai).

## Out of Scope

| Feature | Reason |
| --- | --- |
| Mainnet deployment | Gated on external audit completion — unchanged from v1.0 |
| Escrow release/closing/dispute | Moved to SuperGenius chain, different contracts |
| Proxy work beyond Phase 1 in erc20-gnus-proxy | Sibling repo's own roadmap beyond this milestone's workstream |
| Real-time chat / video NFTs | Not part of the GNUS token ecosystem |

## Traceability

| Requirement | Phase | Status |
| ----------- | ----- | ------ |
| PROXY-01    | 16    | Satisfied (2026-08-30, PR #12) |
| PROXY-02    | 16    | Satisfied (2026-08-30, PR #12) |
| PROXY-04    | 16    | Satisfied (2026-08-30, PR #12) |
| BRIDGE-17   | 20    | Pending |
| TEST-04     | 17    | Pending |
| TEST-05     | 17    | Pending |
| TEST-06     | 17    | Pending |
| SEC-09      | 18    | Pending |
| SEC-10      | 18    | Pending |
| DEP-02      | 19    | Pending |
| SEC-11      | 19    | Pending |
| NFT-01      | 21    | Pending |
| NFT-02      | 21    | Pending |
| NFT-03      | 21    | Pending |
| NFT-04      | 22    | Pending |
| NFT-05      | 22    | Pending |
| NFT-06      | 22    | Pending |
