# Azure Virtual WAN — Config-Driven Deployment with AVM & Bicep

Deploy a production-ready Azure Virtual WAN topology using [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/), Bicep parameter files, and a GitHub Actions CI/CD pipeline — all without writing raw ARM templates.

## Problem

Setting up Azure Virtual WAN is complex: you need a vWAN resource, virtual hubs, gateways (ExpressRoute / VPN), routing intent, NVA integration, and router scaling — often across multiple environments. Most teams end up with brittle, copy-pasted ARM or portal click-ops that are hard to review and reproduce.

## What This Repo Does

| Concern | How it's handled |
|---|---|
| **vWAN + Virtual Hub + Gateways** | AVM pattern module [`avm/ptn/network/virtual-wan`](https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/network/virtual-wan) — battle-tested, Microsoft-maintained |
| **Post-deploy hub config** | Bootstrap module for router scale units, routing intent, and NVA next-hop — deployed only when configured |
| **Multi-profile support** | Separate `.bicepparam` files per environment (`hybrid` / `cloud`) — switch profiles with a single dropdown |
| **Safe deployments** | GitHub Actions workflow with **WhatIf** preview before any real change |
| **Identity** | Workload identity federation (OIDC) — no secrets stored in the repo |

## Repository Structure

```
config/
  cloud.vwan.bicepparam      # Cloud-only profile (no on-prem connectivity)
  hybrid.vwan.bicepparam     # Hybrid profile (ExpressRoute + optional NVA routing)
modules/
  vwan.bicep                 # Main orchestrator — deploys RG, vWAN, hubs, gateways
  vwan-bootstrap.bicep       # Day-2 hub config — routing intent, router scale, NVA
.github/workflows/
  deploy-vwan.yml            # CI/CD — WhatIf or Deploy, profile selector
```

## Quick Start

### 1. Fork & configure GitHub environment

Create a GitHub environment (`Prod` or `Lab`) with these **variables**:

| Variable | Description |
|---|---|
| `AZURE_TENANT_ID` | Your Entra ID tenant |
| `VWAN_SPN_CLIENT_ID` | App registration client ID (federated credential for OIDC) |
| `HYBRID_AZURE_SUBSCRIPTION_ID` | Target subscription for Hybrid profile |
| `CLOUD_AZURE_SUBSCRIPTION_ID` | Target subscription for Cloud profile |

The service principal needs **Contributor** (or scoped Network Contributor + RG Contributor) on the target subscription.

### 2. Customise a parameter file

Edit `config/hybrid.vwan.bicepparam` (or `cloud.vwan.bicepparam`):

- Set the **vWAN name**, **hub name**, **address prefix**, and **location**.
- Uncomment the ExpressRoute connection block and supply your circuit peering resource ID + authorization key.
- To enable NVA routing intent, set `nextHopResourceId` and flip the traffic flags to `true`.

### 3. Run the workflow

1. Go to **Actions → Deploy - vWAN Network**
2. Pick a **Profile** (`Hybrid` or `Cloud`) and a **Mode** (`WhatIf` or `Deploy`)
3. Review the WhatIf output, then re-run with `Deploy` when ready

## Key Design Decisions

- **AVM modules over custom code** — Leverages Microsoft's verified, versioned registry modules so you inherit ongoing fixes and best practices without maintaining low-level resources.
- **Shared hub variable block** — Hub properties (`name`, `location`, `addressPrefix`) are defined once via a `var` in the parameter file and referenced in both the AVM hub array and the bootstrap config, eliminating drift.
- **Bootstrap is conditional** — The `vwan-bootstrap.bicep` module only runs when `hubBootstrapConfigs` is non-empty, so a minimal cloud-only deployment skips it entirely.
- **Routing intent is opt-in** — Routing policies deploy only when `nextHopResourceId` is set and at least one traffic flag is `true`, keeping the default topology clean.

## Contributing

Issues and PRs are welcome. Please run a `WhatIf` against a test subscription before submitting changes.

## License

MIT
