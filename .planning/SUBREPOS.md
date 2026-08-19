# TokenContracts Submodule Map

Maps nested submodules inside `TokenContracts/`. Planning artifacts live in submodules `.planning/` directory.

---

## Nested Submodules

| Submodule Path | Remote | Notes |
|---|---|---|
| `ZoKrates/` | ZoKrates/ZoKrates | ZK proof DSL toolkit (Rust) |
| `erc20-gnus-proxy/` | GeniusVentures/erc20-gnus-proxy | ERC-20 proxy contract |
| `erc20-gnus-proxy/contracts/gnus-ai/` | GeniusVentures/gnus-ai-contracts | AI escrow contracts (diamond pattern) |
| `erc20-gnus-proxy/diamonds/GeniusDiamond/` | GeniusVentures/GeniusDiamond | Diamond proxy implementation |
| `gnus-ai/` | GeniusVentures/gnus-ai | AI escrow + diamond contracts (Hardhat) |
| `gnus-ai/.devcontainer/` | diamondslab/diamonds-devcontainer | Dev container config |
| `gnus-ai/contracts/gnus-ai/` | GeniusVentures/gnus-ai-contracts | AI escrow contracts |
| `gnus-ai/diamonds/GeniusDiamond/` | GeniusVentures/GeniusDiamond | Diamond proxy implementation |
| `sushi-assets/` | GeniusVentures/sushi-assets | SushiSwap integration assets |

## Planning Directory Ownership

All nested submodules use submodule `.planning/` for workstream tracking. If a nested submodule needs independent workstreams, initialize its own `.planning/` with `/gsd:new-project`.

## Workstreams

| Workstream | Submodule | Planning Root | Created |
|---|---|---|---|
| `gnus-ai` | `gnus-ai/` | `gnus-ai/.planning/` | 2026-07-21 |
| `erc20-gnus-proxy` | `erc20-gnus-proxy/` | `erc20-gnus-proxy/.planning/` | 2026-08-19 (Phase 11 scope split — see `gnus-ai/.planning/phases/11-erc-20-proxy-hardening/11-CONTEXT.md`) |

---

*Generated: 2026-07-06*
*Updated: 2026-08-19 — added erc20-gnus-proxy workstream*
