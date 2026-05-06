---
name: azure-stack-destroy
description: "Destroy a Git-Ape deployment by deleting its Azure Deployment Stack with --action-on-unmanage deleteAll, then purging soft-deleted resources (Key Vault, Cognitive Services) that are not purge-protected. Reads state.json (schemaVersion 1.0) to know exactly what to clean up. Use for any local CLI / VS Code Git-Ape teardown so the result matches the CI workflow."
argument-hint: "Deployment ID — add --yes to skip the typed confirmation"
user-invocable: true
---

# Azure Stack Destroy

Destroy a Git-Ape deployment by deleting its subscription-scoped **Azure Deployment Stack** in a single idempotent call (`az stack sub delete --action-on-unmanage deleteAll --bypass-stack-out-of-sync-error true`). The stack owns every resource the matching deploy created — across resource groups and subscription scope — so one delete cleans up everything.

After the stack is gone, this skill performs a **soft-delete purge sweep** for resource types that linger after deletion (Key Vault, Cognitive Services, App Configuration, API Management, ML workspaces, Recovery Services vaults). Resources flagged `purgeProtected: true` in `state.json` are intentionally retained.

This skill mirrors `.github/workflows/git-ape-destroy.exampleyml` so local destroys and CI destroys are interchangeable.

## When to Use

- User says: "destroy this deployment", "tear down deploy-XXX", "clean up the stack"
- Pair with the matching [`azure-stack-deploy`](../azure-stack-deploy/SKILL.md) — same stack, same `state.json` key (`stackId`)
- Any time you would otherwise run `az group delete` against a Git-Ape deployment (don't — you'll miss soft-delete cleanup and multi-RG resources)

## Prerequisites

| Tool | Why |
|------|-----|
| `az` (Azure CLI ≥ 2.59) | `az stack sub delete --bypass-stack-out-of-sync-error` requires a recent CLI |
| `jq` | Read state.json |
| `bash` ≥ 4 OR PowerShell 7+ | Either runner works |
| Active `az login` | Must be the same subscription where the stack lives |
| Existing `state.json` under `.azure/deployments/<id>/` | Source of truth for `stackId`, `managedResources`, `softDeletable`, `purgeProtected` |

The skill **refuses to run** without `state.json`. Re-deploy first or hand-write a minimal state file (not recommended).

## Procedure

### Fast mode vs sync mode

The scripts default to **fast mode** (interactive default). The CI workflow keeps **sync mode** (deterministic).

| | How | Wait time (small VNet stack) | When to use |
|--|--|--|--|
| Fast (default) | Background the `az stack sub delete` call, then poll managed RGs with `az group exists` | ~2 min | Local CLI / VS Code use; user wants quick feedback |
| Sync (`--wait` / `-Wait`) | `az stack sub delete ... --yes` (blocks until stack metadata is fully cleaned) | ~5 min | CI pipelines (default in `git-ape-destroy.exampleyml`); when you need every Azure-side cleanup completed before the script exits |

The Azure CLI does not expose `--no-wait` on `az stack sub delete`, so the fast path runs the same command as a detached background process. In fast mode the stack-metadata cleanup continues asynchronously in Azure after the script returns. The next destroy of the same `deploymentId` is idempotent: if the stack is still finalizing, `az stack sub show` will return it and the script will simply pick up where Azure left off.

### 1. Identify deployment

```bash
DEPLOYMENT_ID="deploy-20260506-001"
DEPLOYMENT_PATH=".azure/deployments/$DEPLOYMENT_ID"
[[ -f "$DEPLOYMENT_PATH/state.json" ]] || { echo "state.json missing — cannot destroy"; exit 1; }
```

### 2. Run the script

```bash
.github/skills/azure-stack-destroy/scripts/destroy-stack.sh \
  --deployment-id "$DEPLOYMENT_ID"
```

Skip the confirmation prompt (use only in automation):

```bash
.github/skills/azure-stack-destroy/scripts/destroy-stack.sh \
  --deployment-id "$DEPLOYMENT_ID" \
  --yes
```

Force CI-equivalent sync wait (default for the CI workflow; opt-in for the script):

```bash
.github/skills/azure-stack-destroy/scripts/destroy-stack.sh \
  --deployment-id "$DEPLOYMENT_ID" \
  --yes --wait
```

PowerShell equivalents:

```powershell
.github/skills/azure-stack-destroy/scripts/destroy-stack.ps1 -DeploymentId "$DEPLOYMENT_ID"
.github/skills/azure-stack-destroy/scripts/destroy-stack.ps1 -DeploymentId "$DEPLOYMENT_ID" -Yes
.github/skills/azure-stack-destroy/scripts/destroy-stack.ps1 -DeploymentId "$DEPLOYMENT_ID" -Yes -Wait
```

### 3. What the script does

1. Reads `state.json` and extracts `stackId`, `deployMethod`, `resourceGroup`, `managedResources[]`, `softDeletable[]`
2. Prints a **destroy plan** — stack ID, resource group, count of soft-deletables (with purge-protection flagged)
3. Prompts for typed `destroy` confirmation (unless `--yes`)
4. **Stack delete path** (`stackId` present):
   - `az stack sub delete --action-on-unmanage deleteAll --bypass-stack-out-of-sync-error true --yes`
   - The bypass flag is safe in destroy because it's a one-shot operation — we don't need the stale-manifest safety check that protects iterative updates
5. **Fallback path** (no `stackId`, only `resourceGroup`): `az group delete --name <rg> --yes`
6. **Purge sweep** for each `softDeletable` resource not marked `purgeProtected`:
   - Key Vaults: `az keyvault list-deleted` + `az keyvault purge`
   - Cognitive Services: `az cognitiveservices account purge`
   - Other types: skipped (soft-delete expires naturally)
7. Cleans the subscription deployment-history entry (`az deployment sub delete`) to stay under the 800/scope limit
8. Updates `state.json` and `metadata.json` with terminal status:

| Status | Meaning |
|--------|---------|
| `destroyed` | Stack/RG gone and all soft-deletables purged or absent |
| `retained-soft-deleted` | Stack gone but at least one soft-deletable retained (purge-protected or purge failed) |
| `partially-destroyed` | Stack delete partially failed |
| `destroy-failed` | Stack/RG delete failed entirely |
| `already-destroyed` | Stack and RG were already gone before this call |

### 4. Inspect the result

```text
=== Destroy Summary ===
Status:   destroyed
Duration: 87s
=======================
```

Or, when something is intentionally retained:

```text
=== Destroy Summary ===
Status:   retained-soft-deleted
Duration: 92s
Retained: 1 soft-deleted resource(s) (purge-protected)
=======================
```

`state.json` gains `destroyedAt`, `destroyedBy`, `destroyDuration`, and a `purgeResults[]` array describing each soft-deletable's outcome.

## Arguments

| Flag (bash) | Param (pwsh) | Required | Description |
|-------------|--------------|----------|-------------|
| `--deployment-id <id>` | `-DeploymentId <id>` | yes | Folder name under `.azure/deployments/` |
| `--yes` | `-Yes` | no | Skip the typed `destroy` confirmation prompt (CI-only) |
| `--wait` | `-Wait` | no | Sync mode: block until Azure has cleaned up stack metadata. Matches the CI workflow. Slower (~3-4×) but fully deterministic. |
| `--poll-timeout <sec>` | `-PollTimeout <sec>` | no | Fast-mode timeout per managed RG poll (default 600s) |

## Failure modes

| Symptom | Likely cause | Recovery |
|---------|--------------|----------|
| `state.json missing` | Deployment never reached the state-write phase, or was hand-edited | Re-deploy (idempotent on stack name) then destroy, OR delete the `.azure/deployments/<id>/` folder if Azure has nothing |
| `Stack out of sync` despite `--bypass-stack-out-of-sync-error` | Old CLI version | Upgrade `az` to ≥ 2.59 |
| Key Vault purge fails | Vault is purge-protected (`purgeProtected: true`) | Expected — wait 7-90 days for soft-delete window to expire, or purge manually after disabling protection |
| `Cannot delete resource group …`/`InUseSubnetCannotBeDeleted` | A resource outside the stack references one inside (e.g. external subnet peered to a deleted VNet) | Inspect `externalReferences[]` in `state.json`; remove the reference and rerun |

## Related

- [`azure-stack-deploy`](../azure-stack-deploy/SKILL.md) — the matching deploy skill (writes the `state.json` this skill consumes)
- [`azure-drift-detector`](../azure-drift-detector/SKILL.md) — check for unmanaged drift BEFORE destroy
- [`azure-resource-visualizer`](../azure-resource-visualizer/SKILL.md) — visualize what's in the stack before tearing it down
