---
name: azure-policy-advisor
description: "Map ARM templates to Azure Policy definitions and initiatives. Queries subscription assignments via `az policy assignment list`, identifies unassigned built-in and custom policies (CIS, NIST, FedRAMP), and emits a two-part report: template-fixable gaps (Part 1) and subscription-level policy assignments (Part 2). INVOKES: az policy assignment list, az policy set-definition list, microsoft_docs_search, microsoft_docs_fetch."
argument-hint: "ARM template JSON or resource types to assess, and optionally a compliance framework (CIS, NIST, general)"
user-invocable: true
---

# Azure Policy Advisor

Recommend Azure Policy assignments for ARM template resources by combining three sources of truth: existing Azure subscription policy state (assignments + definitions), Microsoft Learn built-in recommendations, and ARM template configuration analysis. Produces per-resource policy recommendations with severity ratings, built-in/custom definition IDs, and ready-to-use implementation options.

## When to Use

- After template generation — recommend policies that complement deployed resources
- Compliance audit — assess resources against CIS, NIST, or general best practices
- During onboarding — recommend baseline policies for a new subscription
- When user asks "what policies should we enforce?" or "are we compliant with X?"

**Scope:** This skill assesses (a) ARM template resources you supply and (b) the existing policy state in the target Azure subscription (active assignments + unassigned custom definitions). It does **not** enumerate the live configuration of deployed resources — for that, use `azure-drift-detector`.

## When NOT to Use

- **Per-resource security configuration assessment** (HTTPS-only, public access, shared-key access, TLS version, etc.) → use `azure-security-analyzer`
- **RBAC role recommendations / least-privilege role selection** → use `azure-role-selector`
- **CAF naming abbreviations or name-string length/character constraints** → use `azure-naming-research`
- **Pricing or monthly cost estimation** → use `azure-cost-estimator`
- **VM SKU / API version / quota availability checks** → use `azure-resource-availability`
- **Comparing deployed state vs stored template state** (configuration drift) → use `azure-drift-detector`
- **Generating a new ARM template from requirements** → invoke the `Azure Template Generator` agent

## Procedure

### 1. Load Compliance Context and Identify Resources

Read compliance preferences from the `## Compliance & Azure Policy` section in `copilot-instructions.md` (available automatically in conversation context). Extract:

- **Compliance frameworks** (e.g., CIS Azure Foundations v3.0, NIST SP 800-53 Rev 5, general best practices)
- **Enforcement mode** (Audit or Deny)
- **Policy categories** (identity, networking, storage, compute, monitoring, tagging)

If no compliance section exists in copilot-instructions.md, ask the user:

```
Which compliance approach should I assess against?
1. General Azure best practices (recommended)
2. CIS Azure Foundations v3.0
3. NIST SP 800-53 Rev 5
4. Custom — tell me what to check
```

Then parse the ARM template (if provided) to extract all resource types:

```markdown
Extract for each resource:
- Resource type (e.g., Microsoft.Storage/storageAccounts)
- Resource name
- Current security-relevant properties (cross-reference with security-analyzer output if available)
```

### 1b. Resolve Subscription and Management Group Context

If `{subscription-id}` is not provided, discover it:

- `az account show --query id -o tsv` — current default subscription
- `az account list --query "[].{id:id, name:name}" -o table` — all subscriptions the user has access to

If `{mg-name}` is needed (for management-group-scoped queries) and not provided, list available management groups:

- `az account management-group list --query "[].{name:name, displayName:displayName}" -o table`

If multiple subscriptions or management groups exist, ask the user which one to assess — do not guess.

### 2. Discover Existing Policy State (Assignments + Custom Definitions)

Before recommending new policies, discover what is **already enforced** in the target subscription and what **custom definitions exist but are unassigned**. This prevents redundant recommendations, surfaces enforcement gaps, and lets you prefer unassigned custom definitions over equivalent built-ins.

**Run the discovery script:**

```bash
bash .github/skills/azure-policy-advisor/scripts/discover_policy_state.sh \
  --subscription "{subscription-id}" \
  [--management-group "{mg-name}"] \
  --output /tmp/policy-state.json
```

The script wraps `az policy assignment list`, `az policy definition list`, and `az policy set-definition list` at both subscription and (optional) management-group scope, then normalises the output into a single JSON document:

```jsonc
{
  "subscription_id": "...", "management_group": "..." | null,
  "assigned_policies":        [ { policy_definition_id, enforcement_mode, scope, source: "subscription" | "management-group-inherited", ... } ],
  "assigned_initiatives":     [ { policy_set_definition_id, ... } ],
  "unassigned_custom_policies":     [ { definition_id, display_name, category, target_resource_type, effect, source: "subscription" | "management-group" } ],
  "unassigned_custom_initiatives":  [ { definition_id, display_name, ... } ],
  "errors": [ "..." ]   // non-fatal; partial results still usable
}
```

Use `.assigned_policies` keyed by `policy_definition_id` for the "already-assigned" lookup in Step 5. Use `.unassigned_custom_policies` filtered by `target_resource_type` matching ARM template resources to surface unassigned custom definitions that the platform team should consider assigning.

**If `az` is not available or `az login` has not been run**, the script exits non-zero and prints an error to stderr. Skip Step 5's assigned-vs-unassigned classification and note in the report:

```markdown
⚠️ Could not query Azure subscription — existing assignments and custom
   definitions unknown. Recommendations are based on Microsoft Learn and
   template analysis only. Run `az login` and re-run for subscription-aware
   assessment.
```

### 3. Verify Definition IDs Before Recommending

> **Always verify policy and initiative definition IDs from Microsoft Learn (`microsoft_docs_search` / `microsoft_docs_fetch`) or by calling `az policy set-definition list --query "[?contains(displayName, 'CIS')]" -o table` and `az policy definition list` before recommending them for assignment.** Definition IDs and display names change over time and across Microsoft cloud regions (Public, Government, China). Do not rely on memorized IDs from training data — emit only IDs you have verified live in this run.

### 4. Research Applicable Built-in Policies via Microsoft Learn

**For EACH resource type**, query Microsoft Learn for current built-in policy definitions:

```
Tool: microsoft_docs_search
Query: "Azure Policy built-in {resource-type-category}"

Examples:
- "Azure Policy built-in Storage Accounts"
- "Azure Policy built-in App Service Function Apps"
- "Azure Policy built-in SQL Server database"
- "Azure Policy built-in Key Vault"
- "Azure Policy built-in Kubernetes AKS"
- "Azure Policy built-in virtual machines compute"
- "Azure Policy built-in network security"
- "Azure Policy built-in monitoring diagnostic settings"
```

For **compliance frameworks**, also query:

```
Tool: microsoft_docs_search
Query: "Azure Policy built-in initiative {framework-name}"

Examples:
- "Azure Policy built-in initiative CIS Azure Foundations"
- "Azure Policy built-in initiative NIST SP 800-53"
- "Azure Policy regulatory compliance initiative"
```

When search results reference a high-value page, use `microsoft_docs_fetch` to retrieve the full content:

```
Tool: microsoft_docs_fetch
URL: https://learn.microsoft.com/azure/governance/policy/samples/built-in-policies

Use this to get the complete list of built-in policies organized by category (Storage, App Service, SQL, Key Vault, Network, Monitoring, etc.)
```

Key Microsoft Learn reference pages: **Read [references/ms-learn-policy-pages.md](references/ms-learn-policy-pages.md) when you need a specific Microsoft Learn URL** (canonical built-in policies list, framework-specific pages for CIS/NIST/FedRAMP/PCI-DSS, ARM assignment syntax) — it lists the high-value entry points with guidance on which to fetch when.

### 5. Classify and Prioritize Recommendations

For each recommended policy, assign a severity tier, classify its current status against the ARM template and Steps 2–3 inventory, and resolve precedence when multiple sources cover the same control. **Read [references/classification-rules.yaml](references/classification-rules.yaml) for the full rule set** — it defines the four severity tiers (Critical/High/Medium/Low with Audit/Deny effects), the five status classifications (✅ Already assigned, 🔵 Compliant via template, 🟣 Unassigned custom available, ⚠️ Gap, 🔄 Complementary), and the three-rule precedence ladder (`assigned_wins` → `custom_over_builtin` → `builtin_fallback`).

**Per resource type, prioritize policy categories ranked by severity. Read [references/per-resource-policy-priorities.md](references/per-resource-policy-priorities.md) when classifying recommendations for any of these resource types: Storage Accounts, App Service / Function Apps, SQL Servers / Databases, Key Vault, Compute / VMs, AKS / Kubernetes, Networking, or general cross-cutting controls.** For resource types not in that list, fall back to the `microsoft_docs_search` query template in Step 4.

### 6. Generate Policy Recommendations Report

Present findings split into two clear action tracks: **template improvements** (changes to the ARM template) and **subscription-level actions** (policy/initiative assignments). This separation clarifies who needs to act and where.

**Report outline** — **Read [references/policy-assessment-template.md](references/policy-assessment-template.md) before producing the final markdown report.** The template includes the canonical heading order, table column definitions for each section, and example rows. Skim the headings here, then fetch the full template:

```markdown
## Azure Policy Compliance Assessment
**Scope** · **Deployment** · **Compliance Framework** · **Enforcement Mode** · **Subscription Policy State**

### Summary       — table of {Recommended, Already Assigned, Template Compliant, Template Fixable, Subscription-Level Gap} per category

## Part 1: Template Improvements    (developer acts; edit the ARM template)
### Gaps Fixable in the Template     — table of {Resource Type, Gap, Compliance Control, Fix}
### Already Compliant in Template    — table of {Resource Type, Property, Template Value, Compliance Control}

## Part 2: Subscription-Level Actions    (platform team acts; assign at sub/mg scope)
### Existing Policy Assignments      — table of {Policy/Initiative, Scope, Enforcement, Type, Relevant?}
### Unassigned Custom Policies       — table of {Policy, Category, Target Resource, Effect, Scope}
### Recommended Built-in Assignments — table of {Policy, Effect, Severity, Definition ID, Category, Source}
### Recommended Compliance Initiative — table of {Initiative, Policies, Built-in ID, Status}
```

### 7. Provide Implementation Options

Split implementation guidance into both tracks:

**Track 1: Template Changes (for gaps in Part 1)**

For each gap listed in Part 1, provide the exact ARM template JSON to add. Include:
- The full resource definition (type, apiVersion, name, properties)
- Required `dependsOn` references
- Any new variables needed (e.g., Log Analytics workspace name)

Present as ready-to-copy code blocks that the developer can insert into the nested template's `resources` array. Group related resources together (e.g., Log Analytics workspace + all diagnostic settings that depend on it).

**Track 2: Subscription-Level Assignments (for gaps in Part 2)**

**Option A: Azure CLI (quickest for individual policies)**

```bash
# Assign unassigned custom policies (prioritize — they already exist)
az policy assignment create \
  --name "{custom-policy-short-name}" \
  --display-name "{custom policy display name}" \
  --policy "{full-custom-definition-id-with-mg-scope}" \
  --scope "/subscriptions/{subscription-id}" \
  --enforcement-mode DoNotEnforce

# Assign a built-in policy at subscription scope
az policy assignment create \
  --name "{policy-short-name}" \
  --display-name "{policy display name}" \
  --policy "{built-in-definition-id}" \
  --scope "/subscriptions/{subscription-id}" \
  --params '{}' \
  --enforcement-mode Default

# Assign a compliance initiative
az policy assignment create \
  --name "{initiative-short-name}" \
  --display-name "{initiative display name}" \
  --policy-set-definition "{initiative-id}" \
  --scope "/subscriptions/{subscription-id}"
```

**Option B: ARM Template (for IaC-managed policies)**

```json
{
  "type": "Microsoft.Authorization/policyAssignments",
  "apiVersion": "2024-04-01",
  "name": "{assignment-name}",
  "properties": {
    "displayName": "{display name}",
    "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/{built-in-id}",
    "scope": "/subscriptions/{subscription-id}",
    "enforcementMode": "Default",
    "parameters": {}
  }
}
```

**Enforcement mode guidance:**

| Mode | When to Use |
|------|-------------|
| `Default` | Active enforcement — new non-compliant resources are denied or audited |
| `DoNotEnforce` | Audit-only — evaluates compliance without blocking. Recommended for initial rollout |

### Policy Gate

The policy gate is **advisory** — it surfaces findings without blocking deployment.

```markdown
### Policy Gate: ADVISORY

**Part 1 — Template Compliance:**
🔵 {T} of {R} checks pass via template configuration
🔧 {F} gaps can be fixed by updating the template (see Part 1)

**Part 2 — Subscription Enforcement:**
✅ {A} policies already assigned in subscription
🟣 {C} custom policies available but unassigned — assign for immediate coverage
⚠️ {S} subscription-level gaps — recommend assigning built-in policies or initiative
Enforcement coverage: {percentage}% of recommended policies actively assigned

**Action items:**

_Template (developer):_
1. 🔧 {list of template changes from Part 1, e.g. "Add blob soft delete", "Add diagnostic settings"}

_Subscription (platform team):_
1. 🟣 Assign existing custom policies: {list — these already exist, just need assignment}
2. ⚠️ Assign built-in policies: {list of built-in policies to assign}
3. {initiative to assign if framework selected}
```

## Output Artifacts

When invoked during a deployment workflow, save results to the deployment directory:

| File | Format | Content |
|------|--------|---------|
| `policy-assessment.md` | Markdown | Full assessment report (Section 4 output) |
| `policy-recommendations.json` | JSON | Structured policy data for automation |

**JSON structure for `policy-recommendations.json`** — **Read [references/policy-recommendations-schema.json](references/policy-recommendations-schema.json) when emitting the JSON sidecar.** The reference includes complete field definitions, status/actionTrack enum values, and a fully-worked example. Skeleton:

```json
{
  "assessedAt": "...", "deploymentId": "...", "framework": "...",
  "enforcementMode": "Audit|Deny", "subscriptionState": "queried|unavailable",
  "summary": { "totalRecommended": 16, "alreadyAssigned": 2, "templateCompliant": 8,
               "templateFixable": 3, "customAvailable": 1, "subscriptionGaps": 3 },
  "existingAssignments": [ /* from Step 2 .assigned_policies */ ],
  "unassignedCustomDefinitions": [ /* from Step 2 .unassigned_custom_policies */ ],
  "templateImprovements": [ /* Part 1 gaps */ ],
  "policies": [ /* full recommendation list with status + actionTrack */ ],
  "initiative": { /* compliance-framework initiative if selected */ }
}
```

**Status values for the `status` field:**

| Value | Meaning | Action Track |
|-------|---------|-------------|
| `already-assigned` | Policy actively assigned in subscription (✅) | `none` |
| `template-compliant` | ARM template satisfies the policy, not assigned (🔵) | `subscription` (assign to prevent drift) |
| `template-fixable` | Gap that can be closed by modifying the template (🔧) | `template` |
| `custom-available` | Custom definition exists but not assigned (🟣) | `subscription` |
| `gap` | Not covered — recommend built-in policy assignment (⚠️) | `subscription` |
| `complementary` | Would add enforcement on top of existing config (🔄) | `subscription` |

**Action track values for the `actionTrack` field:**

| Value | Meaning |
|-------|---------|
| `template` | Fix by modifying the ARM template (Part 1 — developer) |
| `subscription` | Fix by assigning a policy at subscription scope (Part 2 — platform team) |
| `none` | No action needed (already assigned or compliant) |

## Integration with Git-Ape

- **Template Generator:** After `/azure-security-analyzer`, optionally invoke `/azure-policy-advisor` to recommend subscription-level policies that complement the template
- **Onboarding:** After RBAC setup, the onboarding flow captures compliance preferences and adds them to `copilot-instructions.md` — this skill reads them automatically
- **Drift Detector:** Cross-reference drift findings with policy recommendations — drift items covered by assigned policies will auto-remediate
