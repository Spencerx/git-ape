![Git-Ape APE logo](APE.png)

# Git-Ape

> **EXPERIMENTAL.** Git-Ape is in active development and is not production-ready.
> Use it for local development, demos, sandbox subscriptions, and learning only.

Git-Ape is a **platform-engineering framework on GitHub Copilot** that plans,
validates, and deploys anything cloud — with security gates, cost analysis,
and CI/CD pipeline integration built in. Nothing is deployed without your
explicit confirmation.

- **Documentation:** <https://azure.github.io/git-ape/>
- **Repository:** <https://github.com/Azure/git-ape>
- **License:** MIT

## What you get

Git-Ape walks every deployment through the same four steps:

1. **Gather** requirements through a guided interview.
2. **Generate** an ARM template, architecture diagram, cost estimate, and security report.
3. **Confirm** with you (interactive) or via PR review (headless) before anything is created.
4. **Deploy** to Azure and run post-deployment validation.

It is built for:

- Azure application stacks: Function Apps, Web Apps, Storage, SQL, Cosmos DB, Container Apps.
- Repository onboarding: OIDC, RBAC, GitHub environments, and secrets.
- Auditable deployments — every run is saved under `.azure/deployments/`.

## Install

[![Install from VS Code Marketplace](https://img.shields.io/visual-studio-marketplace/v/Git-ApeTeam.git-ape?label=VS%20Code%20Marketplace&logo=visualstudiocode&logoColor=white&color=007ACC)](https://marketplace.visualstudio.com/items?itemName=Git-ApeTeam.git-ape) [![Install in VS Code](https://img.shields.io/badge/Install-VS_Code-007ACC?logo=visualstudiocode&logoColor=white)](vscode:extension/Git-ApeTeam.git-ape) [![Install in VS Code Insiders](https://img.shields.io/badge/Install-VS_Code_Insiders-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders:extension/Git-ApeTeam.git-ape)

Git-Ape ships as a [VS Code agent plugin](https://code.visualstudio.com/docs/copilot/customization/agent-plugins).
Pick the install path that fits your workflow.

### Option A: One-click from this listing (recommended)

Click **Install** at the top of this Marketplace page, or use one of the badges
above. VS Code opens and installs the plugin — agents and skills become
available in Copilot Chat immediately.

This path installs Git-Ape as a regular VS Code extension and does **not**
require the `chat.plugins.enabled` setting.

### Option B: Marketplaces setting (for advanced users)

Use this path if you also want the [`ape-context`](https://github.com/suuus/ape-context) companion plugin, or if you prefer to pull the latest from GitHub on every update.

This path requires `chat.plugins.enabled` to be `true` for your organization
(managed at the org level).

1. Open your VS Code `settings.json` and add:

   ```jsonc
   "chat.plugins.marketplaces": [
       "Azure/git-ape"
   ]
   ```

2. Open the Extensions view (`⇧⌘X` on macOS, `Ctrl+Shift+X` on Windows/Linux),
   type `@agentPlugins`, find **git-ape**, and select **Install**.

   Alternatively, run **Chat: Install Plugin From Source** from the Command
   Palette and enter `https://github.com/Azure/git-ape`.
### Configure Azure access

Sign in with `az login` and configure the Azure MCP server in VS Code — see the
[Azure Setup guide](https://azure.github.io/git-ape/docs/getting-started/azure-setup).

### Try it

In Copilot Chat:

- `@git-ape deploy a Python function app`
- `@git-ape deploy a web app with SQL database`
- `@Git-Ape Onboarding set up this repo for Azure deployments`

For the GitHub Copilot CLI install path, see the
[CLI plugin reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference).

## Included agents

| Agent | Description |
|-------|-------------|
| **Git-Ape** | Main orchestrator. Drives the four-stage deployment pipeline, enforces gates, and coordinates the subagents below. |
| **Azure Requirements Gatherer** | Interviews the user, validates subscription access, applies CAF naming, and checks resource conflicts before generation. |
| **Azure Template Generator** | Produces ARM templates, architecture diagrams, cost estimates, and security reports for review. |
| **Azure Resource Deployer** | Executes ARM template deployments to Azure, monitors progress, and handles failures with rollback options. |
| **Azure Principal Architect** | Reviews deployments against the Well-Architected Framework (Security, Reliability, Performance, Cost, Operational Excellence). |
| **Azure Policy Advisor** | Assesses Azure Policy compliance for ARM resources and recommends template improvements plus subscription-level assignments. |
| **Azure IaC Exporter** | Reverse-engineers live Azure resources into ARM templates compatible with Git-Ape's deployment workflow. |
| **Git-Ape Onboarding** | Configures OIDC, federated credentials, RBAC, GitHub environments, and secrets for CI/CD-driven deployments. |

## Included skills

Skills are focused, single-purpose helpers invoked by agents at specific stages.

| Skill | Purpose |
|-------|---------|
| `/prereq-check` | Verifies that required CLI tools (`az`, `gh`, `jq`, `git`) are installed and authenticated. |
| `/azure-naming-research` | Looks up CAF abbreviations and naming constraints (length, scope, valid characters) for any Azure resource type. |
| `/azure-resource-availability` | Validates VM SKU restrictions, runtime versions, API compatibility, and subscription quota against live Azure APIs. |
| `/azure-rest-api-reference` | Returns exact ARM template schemas, required properties, and latest stable API versions for any resource type. |
| `/azure-security-analyzer` | Per-resource security assessment with a blocking deployment gate. |
| `/azure-policy-advisor` | Cross-references templates with subscription policy assignments and Microsoft Learn recommendations. |
| `/azure-role-selector` | Recommends least-privilege built-in Azure RBAC roles or generates custom role definitions. |
| `/azure-cost-estimator` | Real-time monthly cost estimation via the Azure Retail Prices API. |
| `/azure-deployment-preflight` | Runs what-if analysis and permission checks; outputs a structured create/modify/delete report. |
| `/azure-integration-tester` | Post-deployment health checks for Function Apps, Web Apps, Storage, databases, and Container Apps. |
| `/azure-resource-visualizer` | Generates Mermaid architecture diagrams from deployed resource groups. |
| `/azure-drift-detector` | Detects configuration drift between live Azure state and stored deployment artifacts. |
| `/git-ape-onboarding` | Guided playbook for first-time setup of OIDC, RBAC, GitHub environments, and secrets. |

## How it works

```
User prompt → Requirements Gatherer → Template Generator
                                            │
                                            ▼
                                  ┌──────────────────────┐
                                  │  Security Gate       │ (blocking)
                                  └──────────┬───────────┘
                                             ▼
                                       WAF Review
                                             ▼
                                   User confirmation
                                             ▼
                                  Resource Deployer (az deployment)
                                             ▼
                                   Integration tests + diagram
```

Two execution modes use the same agents and skills:

- **Interactive** — talk to `@git-ape` in VS Code Copilot Chat, authenticate with `az login`, approve each step in real time.
- **Headless** — the Copilot Coding Agent picks up an issue, generates a template on a branch, opens a PR, and CI/CD workflows (`git-ape-plan`, `git-ape-deploy`, `git-ape-destroy`) handle deployment via OIDC.

See the full architecture and CI/CD workflow reference at
<https://azure.github.io/git-ape/>.

## Learn more

- [Getting started](https://azure.github.io/git-ape/docs/getting-started/installation)
- [Azure setup](https://azure.github.io/git-ape/docs/getting-started/azure-setup)
- [Onboarding](https://azure.github.io/git-ape/docs/getting-started/onboarding)
- [Deployment examples](https://azure.github.io/git-ape/docs/deployment/examples)
- [Agents reference](https://azure.github.io/git-ape/docs/agents/overview)
- [Skills reference](https://azure.github.io/git-ape/docs/skills/overview)

## Contributing & support

- **Issues / feature requests:** <https://github.com/Azure/git-ape/issues>
- **Contributing guide:** <https://github.com/Azure/git-ape/blob/main/CONTRIBUTING.md>
- **Security:** <https://github.com/Azure/git-ape/blob/main/SECURITY.md>

## License

Git-Ape is released under the [MIT License](https://github.com/Azure/git-ape/blob/main/LICENSE).
