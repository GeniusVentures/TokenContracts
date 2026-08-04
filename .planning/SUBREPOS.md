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

---

*Generated: 2026-07-06*
