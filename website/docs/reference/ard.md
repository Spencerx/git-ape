---
sidebar_position: 4
---

# Agentic Resource Discovery (ARD)

Git-Ape publishes an [ARD](https://agenticresourcediscovery.org) `ai-catalog.json` so that AI agents and tools that support Agentic Resource Discovery can automatically find and invoke Git-Ape skills.

## What is ARD?

Agentic Resource Discovery is an open protocol that lets AI agents discover skills and tools published by any team or organisation — similar to how DNS lets browsers discover websites. An AI agent can query an ARD catalog endpoint to find available skills, read their descriptions, and invoke them automatically.

## Catalog Endpoint

Git-Ape's catalog is published at:

```
https://azure.github.io/git-ape/.well-known/ai-catalog.json
```

The catalog lists all 15 Git-Ape skills and federates two additional skill catalogs via `collections`:

| Collection | URL | Skills |
|---|---|---|
| Azure SaaS Skills | `https://dawright22.github.io/azure-saas-skills/.well-known/ai-catalog.json` | 12 |
| AWS Skills | `https://dawright22.github.io/aws_skills/.well-known/ai-catalog.json` | 21 |

## Git-Ape Skills in the Catalog

| Skill | Description |
|---|---|
| **Azure Cost Estimator** | Estimate monthly costs by querying the Azure Retail Prices API against ARM templates |
| **Azure Deployment Preflight** | What-if analysis, permission checks, and resource change preview before any deployment |
| **Azure Drift Detector** | Detect and reconcile configuration drift between deployed Azure resources and stored state |
| **Azure Integration Tester** | Post-deployment health checks for Function Apps, Storage, Databases, and App Services |
| **Azure Naming Research** | Look up CAF abbreviations, naming rules, and regex patterns for Azure resource types |
| **Azure Policy Advisor** | Assess ARM templates for CIS/NIST/FedRAMP policy gaps and subscription-level assignments |
| **Azure Resource Availability** | Validate VM SKUs, Kubernetes versions, API versions, and quota before deploying |
| **Azure Resource Visualizer** | Generate Mermaid architecture diagrams from live Azure resource groups |
| **Azure REST API Reference** | Look up exact property schemas, required fields, and stable API versions for any resource type |
| **Azure Role Selector** | Recommend least-privilege RBAC roles for managed identities and service principals |
| **Azure Security Analyzer** | Per-resource security assessment with severity ratings before deployment confirmation |
| **Azure Stack Deploy** | Run a subscription-scoped Azure Deployment Stack and write `state.json` |
| **Azure Stack Destroy** | Tear down a Git-Ape deployment and purge soft-deleted resources |
| **Git-Ape Onboarding** | Bootstrap Entra OIDC, RBAC, GitHub environments, and CI/CD workflow scaffolding |
| **Prerequisites Check** | Validate `az`, `gh`, `jq`, `git` installation and auth sessions |

## Catalog Format

The catalog follows the [ARD `ai-catalog.json` spec v1.0](https://agenticresourcediscovery.org):

```json
{
  "specVersion": "1.0",
  "host": { "displayName": "Azure Git-Ape", "identifier": "azure.github.io" },
  "entries": [ ... ],
  "collections": [
    { "url": "https://dawright22.github.io/azure-saas-skills/.well-known/ai-catalog.json" },
    { "url": "https://dawright22.github.io/aws_skills/.well-known/ai-catalog.json" }
  ]
}
```

Each `entries[]` item includes `identifier`, `displayName`, `type: "application/ai-skill"`, `url` (SKILL.md), and `description` sourced directly from the skill's SKILL.md frontmatter.

The `collections[]` array is the federation mechanism — an ARD crawler follows these URLs to discover the SaaS and AWS skill catalogs without duplicating their entries inline.

## Adding Git-Ape to an ARD-Enabled Agent

If your AI agent or tool supports ARD discovery, register the catalog URL:

```
https://azure.github.io/git-ape/.well-known/ai-catalog.json
```

The agent will discover all 48 skills (15 Git-Ape + 12 SaaS + 21 AWS) and their descriptions, and can invoke them via the GitHub Copilot skill invocation protocol.