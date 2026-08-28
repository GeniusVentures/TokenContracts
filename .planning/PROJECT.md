# TokenContracts — Multi-Repo Umbrella

## What This Is

The TokenContracts umbrella owns cross-repo milestone coordination for the GNUS.ai contract family. Sub-repos execute their own work inside their own `.planning/` roots (see `SUBREPOS.md`); this directory hosts the milestone-level PROJECT/REQUIREMENTS/ROADMAP that spans them — **docs only**, no gsd-sdk workflows operate here.

**Sub-repos:** `gnus-ai` (AI escrow + diamond contracts, Hardhat/Foundry — v1.0 shipped 2026-08-28), `erc20-gnus-proxy` (standalone ERC-20 proxy diamond), `gnus-token`, `GeniusDiamond`, `ZoKrates`, `sushi-assets`.

**Core Value:** Every GNUS.ai contract repo production-ready, cross-repo milestones coordinated from one place.

## Current Milestone: v1.1 Proxy Completion & Production Readiness

**Goal:** Close every v1.0 remainder — complete the ERC-20 proxy in its sibling repo, bring bridgeIn to activatable state, burn down the audit's tech-debt register, and research then implement child-NFT token economics.

**Target features:**
- erc20-gnus-proxy Phase 1 (executes in `erc20-gnus-proxy/.planning/`) — PROXY-01 real amount-specific allowances, PROXY-02 immutable one-shot init, nested gnus-ai-contracts pin bump ≥ d731384 (issue #9)
- BRIDGE-17, gate-checked (executes in `gnus-ai/.planning/`) — verify SuperGenius #363; if closed, activate bridgeIn; if open, ship EVM-side readiness and block only on activation
- Audit debt burn-down (gnus-ai) — test-suite cleanup (GNUSControlStorage chainID, AccessControlInvariant flake, Safe setUp reverts), scanner upgrades (slither triage-capable, semgrep pattern fix + promotion), OSV 115-advisory remainder round 2, git-secrets 37-hit provenance review
- Child-NFT economics — research (NFT-01/02/03: treasury feasibility, NFT→GNUS swap, external swap routing) then implement on the findings; implementation scope confirmed at the research phase's exit

**Phase numbering** continues from v1.0 (last phase 15) → v1.1 starts at Phase 16.

## Execution Routing

| Phase | Executes in | Planning root |
|---|---|---|
| 16 | `erc20-gnus-proxy/` | `erc20-gnus-proxy/.planning/` |
| 17–20 | `gnus-ai/` | `gnus-ai/.planning/` |
| 21–22 | cross-repo (research → gnus-ai diamond) | decided at Phase 21 exit |

`active-workstream` points at the submodule currently executing; flip it as phases move between repos.

## Evolution

This document evolves at milestone boundaries (full review of all sections; Core Value check; Out of Scope audit; Context refresh).

---
_Last updated: 2026-08-28 — v1.1 started (first milestone hosted at the parent)_
