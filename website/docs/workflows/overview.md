---
title: "CI/CD Workflows Overview"
sidebar_label: "Overview"
sidebar_position: 1
description: "Overview of Git-Ape GitHub Actions workflows"
---

<!-- AUTO-GENERATED — DO NOT EDIT. Source: .github/workflows/ -->


# CI/CD Workflows Overview

Git-Ape provides GitHub Actions workflows for automated deployment lifecycle management.

:::info[Activation required]
Workflows ship as **`*.exampleyml`** files in `.github/workflows/` so they are inert when the plugin is first installed. The [`/git-ape-onboarding`](/docs/skills/git-ape-onboarding) flow renames each `.exampleyml` to `.yml` after you complete the experimental-status acknowledgments. Files still ending in `.exampleyml` in the inventory below are not yet active.
:::

## Workflow Inventory

| Workflow | File | Triggers | Jobs |
|----------|------|----------|------|
| [Daily Repo Status](./daily-repo-status-lock) | `daily-repo-status.lock.yml` | schedule, workflow_dispatch | activation, agent, conclusion, detection, safe_outputs |
| [Git-Ape: Workflow Lint](./git-ape-actionlint) | `git-ape-actionlint.yml` | pull_request | actionlint |
| [Git-Ape: Extension Build](./git-ape-build) | `git-ape-build.yml` | pull_request | build |
| [Git-Ape: Deploy](./git-ape-deploy) | `git-ape-deploy.exampleyml` | push, issue_comment | check-comment-trigger, detect-deployments, deploy |
| [Git-Ape: Destroy](./git-ape-destroy) | `git-ape-destroy.exampleyml` | push, workflow_dispatch | detect-destroys, destroy |
| [Git-Ape: Docs Check](./git-ape-docs-check) | `git-ape-docs-check.yml` | pull_request | check-docs |
| [Git-Ape: Docs Deploy](./git-ape-docs) | `git-ape-docs.yml` | push | build, deploy |
| [Git-Ape: Plan](./git-ape-plan) | `git-ape-plan.exampleyml` | pull_request | detect-deployments, plan-local, plan-azure, plan-comment |
| [Git-Ape: Plugin Version Check](./git-ape-plugin-version-check) | `git-ape-plugin-version-check.yml` | pull_request | check-version-drift |
| [Git-Ape: Plugin Release](./git-ape-release) | `git-ape-release.yml` | push, workflow_dispatch | release |
| [Git-Ape: Verify Setup](./git-ape-verify) | `git-ape-verify.exampleyml` | workflow_dispatch | verify |
| [Issue Triage Agent](./issue-triage-agent-lock) | `issue-triage-agent.lock.yml` | schedule, workflow_dispatch | activation, agent, conclusion, detection, safe_outputs |
| [PR Validation](./pr-validation) | `pr-validation.yml` | pull_request | structure-check, markdownlint |

## Pipeline Architecture

```mermaid
graph LR
    PR["PR Opened"] --> Plan["git-ape-plan.yml<br/>Validate + What-If"]
    Plan --> Review["Human Review"]
    Review --> Merge["Merge to main"]
    Merge --> Deploy["git-ape-deploy.yml<br/>ARM Deployment"]
    Deploy --> Test["Integration Tests"]

    Comment["/deploy Comment"] --> Deploy

    Destroy["PR: status → destroy-requested"] --> DestroyMerge["Merge"]
    DestroyMerge --> DestroyWF["git-ape-destroy.yml<br/>Delete Resources"]

    Manual["Manual Dispatch"] --> Verify["git-ape-verify.yml<br/>Verify Setup"]

    classDef plan fill:#dbeafe,stroke:#1f6feb,stroke-width:1px,color:#0b3d91
    classDef review fill:#fde68a,stroke:#b45309,stroke-width:1px,color:#7c2d12
    classDef deploy fill:#dcfce7,stroke:#15803d,stroke-width:1px,color:#14532d
    classDef destroy fill:#fecaca,stroke:#b91c1c,stroke-width:1px,color:#7f1d1d
    classDef verify fill:#ede9fe,stroke:#7c3aed,stroke-width:1px,color:#4c1d95
    class PR,Plan plan
    class Review,Merge,Comment review
    class Deploy,Test deploy
    class Destroy,DestroyMerge,DestroyWF destroy
    class Manual,Verify verify
```
