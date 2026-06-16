---
title: "Git Ape Onboarding"
sidebar_label: "Git Ape Onboarding"
description: "Bootstrap a GitHub repository for Git-Ape CI/CD: Entra app registration, OIDC federated credentials, RBAC role assignments, GitHub environments (azure-deploy/azure-destroy), required secrets, and scaffold Actions workflow files. USE FOR: first-time Git-Ape setup, new subscription onboarding, multi-environment (dev/staging/prod) setup, configure OIDC, federated credentials, RBAC setup, GitHub environments, scaffold workflow files. DO NOT USE FOR: deploying resources (use git-ape), drift detection alone, secret rotation."
---

<!-- AUTO-GENERATED — DO NOT EDIT. Source: .github/skills/git-ape-onboarding/SKILL.md -->


# Git Ape Onboarding

> Bootstrap a GitHub repository for Git-Ape CI/CD: Entra app registration, OIDC federated credentials, RBAC role assignments, GitHub environments (azure-deploy/azure-destroy), required secrets, and scaffold Actions workflow files. USE FOR: first-time Git-Ape setup, new subscription onboarding, multi-environment (dev/staging/prod) setup, configure OIDC, federated credentials, RBAC setup, GitHub environments, scaffold workflow files. DO NOT USE FOR: deploying resources (use git-ape), drift detection alone, secret rotation.

## Details

| Property | Value |
|----------|-------|
| **Skill Directory** | `.github/skills/git-ape-onboarding/` |
| **Phase** | Operations |
| **User Invocable** | ✅ Yes |
| **Usage** | `/git-ape-onboarding` |


## Documentation

# Git-Ape Onboarding

Use this skill to bootstrap a repository for Git-Ape deployments by executing the onboarding workflow directly from Copilot Chat.

This skill is the source of truth for onboarding behavior. Do not depend on a standalone repository script for setup logic.

## When to Use

- First-time setup of a repository for Git-Ape
- New subscription onboarding (single environment)
- Multi-environment onboarding (dev/staging/prod across different subscriptions)
- New user handoff where OIDC, RBAC, and GitHub environments must be created

**DO NOT USE FOR:** re-deploying an already-onboarded repo (use `git-ape`), rotating or updating an existing secret or federated credential, drift detection setup alone (that is an optional sub-step covered by Step 10), or general Azure resource deployment.

## What It Configures

This skill configures:

1. Entra ID App Registration and service principal (or reuses existing)
2. OIDC federated credentials for GitHub Actions
3. RBAC role assignment(s) on subscription scope
4. GitHub environments (`azure-deploy*`, `azure-destroy`)
5. Required GitHub secrets (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`) and the `AZURE_SUBSCRIPTION_ID` variable
6. Scaffolded GitHub Actions workflow files (`git-ape-plan.yml`, `-deploy.yml`, `-destroy.yml`, `-verify.yml`, `-drift.{md,lock.yml}`) and deployment standards (`.github/copilot-instructions.md`) into the user's working copy
7. *(Optional)* The `COPILOT_GITHUB_TOKEN` repository secret that powers the agentic drift-detection workflow (`git-ape-drift.lock.yml`) — only when the user opts into scheduled drift detection

## Prerequisites

Before onboarding, run the **prereq-check** skill to verify all required tools are installed and auth sessions are active:

```text
/prereq-check
```

The prereq-check skill validates: `az` (≥ 2.50), `gh` (≥ 2.0), `jq` (≥ 1.6), `git`, and active Azure/GitHub auth sessions. If anything is missing, it shows platform-specific install commands.

Do NOT proceed with onboarding until prereq-check reports **✅ READY**.

Additionally, the Azure identity used must have **Owner** or **User Access Administrator** on the target subscription(s), and the GitHub identity must have **admin** access to the target repository.

## Invariants

These rules are non-negotiable. The agent MUST NOT improvise around them.

- **Default branch is always `main`.** Never use `master`, never auto-detect a non-`main` default, and never substitute any other name. All federated credential subjects, environment branch policies, and example commands use `refs/heads/main` / the literal string `main`. If a user's repository uses something other than `main`, prompt for it once and use the user-supplied value explicitly — never silently default to `master`.
- **Federated credential names use the `fc-main-branch` form,** not `fc-master-branch`. See Step 5 for the canonical subject strings.
- **Workflows ship `main`-targeted triggers.** The scaffold step copies workflow files that reference `branches: [main]`; do not rewrite them to `master`.

## Execution Modes

### Interactive (recommended for first-time use)

Invoke the skill from chat and let the agent gather missing parameters:

```text
/git-ape-onboarding
```

### Parameterized single environment

```text
/git-ape-onboarding onboard https://github.com/org/repo on subscription 00000000-0000-0000-0000-000000000000 with Contributor
```

### Parameterized multi-environment

```text
/git-ape-onboarding onboard https://github.com/org/repo with dev on 11111111-1111-1111-1111-111111111111 as Contributor, staging on 22222222-2222-2222-2222-222222222222 as Contributor, prod on 33333333-3333-3333-3333-333333333333 as Contributor+UserAccessAdministrator
```

## Command Playbook

When the agent executes this skill, it should run the equivalent Azure and GitHub CLI commands directly in this order:

1. Validate prerequisites and current auth context.
2. Resolve repo metadata:
```bash
gh repo view <org>/<repo>
gh api repos/<org>/<repo> --jq '{repo_id: .id, owner_id: .owner.id}'
gh api orgs/<org>/actions/oidc/customization/sub --jq '.use_default'
```
3. Create or reuse the Entra app registration and service principal:
```bash
CLIENT_ID=$(az ad app create --display-name "$SP_NAME" --query appId -o tsv)
az ad sp create --id "$CLIENT_ID"
TENANT_ID=$(az account show --query tenantId -o tsv)
OBJECT_ID=$(az ad app show --id "$CLIENT_ID" --query id -o tsv)
```
4. Build the OIDC subject prefix:
```bash
# default format
OIDC_PREFIX="repo:<org>/<repo>"

# if org customization returns false
OIDC_PREFIX="repository_owner_id:<OWNER_ID>:repository_id:<REPO_ID>"
```
5. Create federated credentials with these canonical subjects (always `refs/heads/main` — never `master`):
   - `fc-main-branch`     subject `"$OIDC_PREFIX:ref:refs/heads/main"`     description `"Main branch deployments"`
   - `fc-pull-request`    subject `"$OIDC_PREFIX:pull_request"`            description `"Pull request plan/validate"`
   - `fc-azure-deploy`    subject `"$OIDC_PREFIX:environment:azure-deploy"` (one per environment in multi-env mode)
   - `fc-azure-destroy`   subject `"$OIDC_PREFIX:environment:azure-destroy"`
6. Assign RBAC on each target subscription.
7. Set GitHub repo or environment secrets (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`) and the `AZURE_SUBSCRIPTION_ID` variable.
8. Create GitHub environments and branch policies when permissions allow.
9. Scaffold workflow files and deployment standards into the user's working copy (see below).
10. *(Optional)* Provision the drift detector engine credential (`COPILOT_GITHUB_TOKEN`) so the agentic drift workflow can run (see below).
11. Capture compliance and Azure Policy preferences (see below).
12. Verify federated credentials, role assignments, and secrets.

### Step 9: Scaffold workflow files and deployment standards

The GitHub Actions workflows that power Git-Ape (`git-ape-plan.yml`,
`-deploy.yml`, `-destroy.yml`, `-verify.yml`, `-drift.md`, `-drift.lock.yml`)
and the deployment standards file (`.github/copilot-instructions.md`) ship
as templates inside this skill at `./templates/`.

After identity, secrets, and environments are configured, run the scaffold
helper to copy these templates into the user's working copy. Two parity
implementations ship — pick the one that matches the user's shell:

```bash
# macOS / Linux / WSL
./scripts/scaffold-repo.sh
```

```powershell
# Windows (PowerShell 7+)
pwsh .github/skills/git-ape-onboarding/scripts/scaffold-repo.ps1
```

Both scripts produce byte-identical output and follow the same rules below.
The onboarding-template-check workflow enforces parity on every PR.

The helper:

- Resolves the target repo root via `git rev-parse --show-toplevel` (override
  by passing an explicit path as the first argument).
- Copies each template only if the destination does not already exist
  (**skip-with-notice on collision** — never overwrites a customized file).
- Prints `✓ Created` for new files, `⊝ Skipped` for collisions, and a final
  `Created N file(s), skipped M file(s).` summary.
- Leaves all files **unstaged**. It does not run `git add`, `git commit`,
  `git push`, or open a pull request — the user decides how to land them.
- For each skipped file, prints a `diff -u` command pointing at the
  canonical template so the user can reconcile manually.

If the user already had a custom `.github/copilot-instructions.md`, the
scaffold step skips it. Step 11 (below) handles that case explicitly.

### Step 10: (Optional) Onboard the drift detector workflow

**This step is optional.** It is only needed if the user wants the scheduled
**drift-detection** workflow (`git-ape-drift.lock.yml`) to run. The `plan`,
`deploy`, `destroy`, and `verify` workflows do **not** depend on anything from
this step — skip it entirely if the user is not enabling drift detection.

Unlike the other scaffolded workflows, `git-ape-drift` is a **GitHub Agentic
Workflow** (authored with [gh-aw](https://github.github.com/gh-aw/)) that runs
on the **GitHub Copilot engine**. Its compiled `.lock.yml` opens with a hard
preflight gate — *"Validate COPILOT_GITHUB_TOKEN secret"* — that fails the run
immediately when the credential is missing. There is **no fallback**: the Azure
OIDC secrets from Step 7 cover the workflow's deterministic pre-steps, but the
agent itself needs its own engine token.

To onboard it:

1. **Confirm intent.** Ask the user whether they want scheduled drift
   detection. If not, skip this step.

2. **Provision `COPILOT_GITHUB_TOKEN`** as a **repository** secret — not an
   environment secret, because the daily `schedule` runs from `main` with no
   environment attached:
   ```bash
   gh secret set COPILOT_GITHUB_TOKEN --repo <org>/<repo>
   # paste the token when prompted — never pass it on the command line
   ```
   Token requirements:
   - A GitHub **PAT** (fine-grained or classic) belonging to an identity with
     an **active GitHub Copilot seat**.
   - The built-in `GITHUB_TOKEN` **cannot** drive the Copilot engine, so the
     token must be supplied explicitly.
   - The other gh-aw tokens (`GH_AW_GITHUB_TOKEN`,
     `GH_AW_GITHUB_MCP_SERVER_TOKEN`) are **not** required — they fall back to
     the auto-provided `GITHUB_TOKEN`.

3. **(Only if recompiling.)** The scaffolded `.lock.yml` runs as-is. The
   `gh-aw` CLI is needed **only** when the user edits `git-ape-drift.md` and
   wants to regenerate the lock file:
   ```bash
   gh extension install github/gh-aw
   gh aw compile
   ```

4. **Smoke-test** the workflow end to end:
   ```bash
   gh workflow run git-ape-drift.lock.yml --repo <org>/<repo>
   gh run list --workflow git-ape-drift.lock.yml --repo <org>/<repo> --limit 1
   ```

Never print the token value in chat output (see Safe-Execution Rules).

### Step 11: Compliance & Azure Policy Preferences

After RBAC and environment setup, ask the user about compliance requirements and update the `## Compliance & Azure Policy` section in `.github/copilot-instructions.md`:

1. **Ask compliance framework:**
   ```
   Which compliance framework should Git-Ape use for policy recommendations?
   - General Azure best practices (recommended)
   - CIS Azure Foundations v3.0
   - NIST SP 800-53 Rev 5
   - None — skip policy recommendations
   ```

2. **Ask enforcement mode:**
   ```
   How should policies be enforced initially?
   - Audit only (recommended — evaluate compliance without blocking)
   - Enforce (Deny — block non-compliant deployments immediately)
   ```

3. **Update `copilot-instructions.md`** with the user's choices:
   - If the file does not exist (scaffold step was skipped or scaffolding
     was not run), print the captured preferences in chat and ask the user
     to add them manually. Do NOT create a new file from scratch — that is
     the scaffold step's responsibility.
   - If the file exists AND contains a `## Compliance & Azure Policy`
     section, edit the `### Compliance Frameworks` and
     `### Policy Enforcement Mode` subsections in place.
   - If the file exists but does NOT contain that section (user has a
     customized file), do NOT mutate it. Instead, print the captured
     preferences and a suggested patch in chat so the user can apply it.
   - In all cases, leave changes unstaged and let the user commit them.

## Safe-Execution Rules

1. Echo target repository and subscription(s) before execution.
2. Require explicit user confirmation before running onboarding.
3. Never print secret values in chat output.
4. Summarize what was created or updated (app registration, federated credentials, role assignments, GitHub environments, scaffolded files).
5. If onboarding fails, surface the failing step and command context, then stop.
6. Never overwrite an existing `.github/workflows/*` file or
   `.github/copilot-instructions.md`. The scaffold helper enforces
   skip-with-notice; do not bypass it.
7. Never run `git add`, `git commit`, `git push`, or open a PR for the
   scaffolded files — leave them unstaged so the user decides how to land
   them.
8. **Idempotency on re-run:** If the skill is re-invoked after a partial failure, re-run from the last failing step — not from scratch. The Entra app, federated credentials, role assignments, and GitHub environments created before the failure are safe to reuse; do not create duplicates. Surface each already-provisioned resource as `⊝ Already exists` rather than re-creating it.

## Suggested Agent Flow

**First-turn rule:** the very first response to any onboarding request must be a **gated handoff** — surface prereq results and collect required inputs. It must NOT be a walkthrough, a full set of CLI commands, or a completion report. The agent must not narrate or execute onboarding steps until: (a) prereq check confirms ✅ READY, and (b) all five required inputs from step 2 are in hand.

1. **Run `/prereq-check`** to validate tools and auth. Surface the full results table — tool versions, Azure CLI auth status, GitHub CLI auth status, and a ✅/❌ per check. If CLI commands cannot execute in the current environment, present the required checklist items and ask the user to confirm each one passes manually (`az` ≥ 2.50 installed and authenticated, `gh` ≥ 2.0 installed and authenticated, `jq` ≥ 1.6, `git` installed). **Never advance to step 2 until prereq results are confirmed — this is a hard gate.**
2. **Collect the required inputs.** Ask for — and wait for answers to — at minimum: (1) target GitHub repository URL, (2) Azure subscription ID (or one per environment for multi-env), (3) RBAC role to grant (`Contributor` or `Owner`), (4) onboarding mode (`single` or `multi-environment`), (5) default branch (confirm `main` or ask if non-standard). Do not proceed to step 3 without all five.
3. Validate current Azure/GitHub auth context (subscription, tenant, GitHub org).
4. Ask for final confirmation.
5. Execute the required Azure CLI and GitHub CLI commands directly from this playbook.
6. Scaffold workflow files and `copilot-instructions.md` via `./scripts/scaffold-repo.sh` on macOS/Linux/WSL, or `pwsh ./scripts/scaffold-repo.ps1` on Windows (Step 9 in playbook). Report which files were created vs skipped.
7. *(Optional)* Offer to onboard the drift detector workflow by provisioning `COPILOT_GITHUB_TOKEN` (Step 10 in playbook). Skip if the user does not want scheduled drift detection.
8. Ask compliance framework and enforcement mode preferences (Step 11 in playbook).
9. Update `copilot-instructions.md` with compliance preferences — or, if the file was skipped by the scaffold step, surface the preferences in chat for manual integration.
10. Summarize outcome (including scaffolded file counts) and suggest verification commands.

## Known Gotchas

### GitHub Org Custom OIDC Subject Template (e.g. Azure org)

Some GitHub organizations (notably the `Azure` org) override the default OIDC subject
claim template to use **numeric ID-based** subjects instead of name-based ones.

The skill auto-detects this by calling:
```bash
gh api "orgs/{org}/actions/oidc/customization/sub" --jq ".use_default"
```
- Returns `true` → standard format: `repo:Azure/git-ape:pull_request`
- Returns `false` → ID format: `repository_owner_id:6844498:repository_id:1184905165:pull_request`

If OIDC login fails with `AADSTS700213: No matching federated identity record`, the
federated credential subjects don't match what GitHub is presenting. Fix by re-running
onboarding (the skill will auto-detect and use the correct format), or manually updating
existing credentials:
```bash
# Get repo/owner IDs
gh api repos/Azure/git-ape --jq '{repo_id: .id, owner_id: .owner.id}'

# Update each federated credential with correct subject
az ad app federated-credential update \
  --id <APP_OBJECT_ID> \
  --federated-credential-id <CRED_ID> \
  --parameters '{"subject":"repository_owner_id:<OWNER_ID>:repository_id:<REPO_ID>:pull_request"}'
```

### Disabled Subscriptions

Azure subscriptions in a `Disabled` state are read-only — RBAC assignments will fail.
Verify subscription state before onboarding:
```bash
az account show --subscription <SUB_ID> --query "{name:name,state:state}" -o table
# Test write access:
az group list --subscription <SUB_ID> --query "length(@)" -o tsv
```

## Verification Commands

```bash
# Azure context
az account show --query "{name:name,id:id,tenantId:tenantId}" -o table

# GitHub auth
gh auth status

# Validate app federated credentials — check subjects match org OIDC format
az ad app federated-credential list --id <APP_OBJECT_ID> -o json | jq -r '.[] | "\(.name): \(.subject)"'

# Check GitHub org OIDC subject template (true = name-based, false = ID-based)
gh api orgs/<ORG>/actions/oidc/customization/sub --jq '.use_default'

# Get repo and owner numeric IDs (needed for ID-based subject construction)
gh api repos/<ORG>/<REPO> --jq '{repo_id: .id, owner_id: .owner.id}'

# Validate role assignments for SP (replace principal object id)
az role assignment list --assignee-object-id <SP_OBJECT_ID> --all -o table

# (Optional, drift detector) Confirm the Copilot engine credential is set
gh secret list --repo <ORG>/<REPO> | grep -q '^COPILOT_GITHUB_TOKEN' \
  && echo "✅ COPILOT_GITHUB_TOKEN set" \
  || echo "⚠️ COPILOT_GITHUB_TOKEN missing — drift workflow will fail its preflight"
```
