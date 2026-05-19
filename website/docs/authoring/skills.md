---
title: "Authoring Skills"
sidebar_label: "Skills"
sidebar_position: 2
description: "How to add a new skill: directory layout, SKILL.md frontmatter, structure, and registration."
---

# Authoring Skills

A **skill** is a focused, callable capability with a documented procedure. Skills are the atomic unit Git-Ape composes into agent workflows. Each skill is a directory under [`.github/skills/`](https://github.com/Azure/git-ape/tree/main/.github/skills) containing one `SKILL.md` file (plus optional helper files).

## Quick start

```bash
SKILL=my-new-skill
mkdir -p .github/skills/"$SKILL"
$EDITOR .github/skills/"$SKILL"/SKILL.md
```

Then write the frontmatter and body following the template below. No further registration is needed — `plugin.json` declares `"skills": ".github/skills/"` and Copilot auto-discovers every subdirectory containing a `SKILL.md`.

## File layout

```
.github/skills/my-new-skill/
├── SKILL.md             # Required: frontmatter + procedure
├── scripts/             # Optional: helper scripts the skill shells out to
└── templates/           # Optional: text/config templates referenced by the skill
```

The directory name **must** match the `name:` field in frontmatter.

## SKILL.md template

```markdown
---
name: my-new-skill
description: "One sentence describing what the skill does and when it should fire. Used by the trigger router."
argument-hint: "Free-text hint shown to users when they invoke the skill"
user-invocable: true
---

# Display Title

One paragraph describing what the skill does and the value it delivers.

## When to Use

- Bullet describing trigger condition 1
- Bullet describing trigger condition 2
- Bullet describing trigger condition 3

## Inputs

- `argument-1`: what it is and whether required
- `argument-2`: what it is and whether required

## Execution Playbook

Run the steps below in order. Stop at the first blocking failure.

### Step 1 — Verify prerequisites

```bash
command -v az >/dev/null || { echo "az not found"; exit 1; }
```

### Step 2 — Do the thing

Describe the action. Use fenced code blocks for any shell or API calls so they
can be reused verbatim.

### Step 3 — Report results

Describe the output format. Where possible, show a sample table or JSON shape.

## Output Format

Show the literal structure the skill is contracted to produce. Skills are
graded on producing this output, so make it concrete.
```

## Frontmatter reference

| Field | Required | Purpose |
|-------|:--------:|---------|
| `name` | ✅ | Kebab-case skill identifier. Must match directory name. |
| `description` | ✅ | One sentence used by the Copilot router to decide when to trigger the skill. Specific verbs and nouns matter — vague descriptions hurt trigger precision. |
| `argument-hint` | ⚪ | Free-text hint displayed in the prompt picker. |
| `user-invocable` | ⚪ | Defaults to `true`. Set `false` for skills that only run as a sub-step of an agent and should not be surfaced standalone. |

## Anatomy of a good skill

Look at [`prereq-check/SKILL.md`](https://github.com/Azure/git-ape/blob/main/.github/skills/prereq-check/SKILL.md) for a reference. It demonstrates the patterns Git-Ape skills follow:

1. **Crisp `description:`** — the router uses this text to decide whether to fire. Mention the verbs and resource types the skill handles.
2. **`## When to Use`** — three to five concrete trigger conditions written from the user's point of view (`Before first-time onboarding`, `When any Git-Ape skill fails with a "command not found" error`, …). The eval suite's negative tasks will probe the edges.
3. **`## Execution Playbook`** — numbered steps with verbatim shell or API calls. Each step has one job. Steps reference each other by number when ordering matters.
4. **Explicit output contract** — what the skill returns (table, JSON, file). The `behavior` and `prompt` graders score the agent against this contract.
5. **No persona language** — skills are tools, not characters. Persona-lock belongs in the agent that calls the skill, not in the skill itself.

## Token budget

`waza` runs a token audit on every skill. The thresholds live in [`.waza.yaml`](https://github.com/Azure/git-ape/blob/main/.waza.yaml):

```yaml
tokens:
  warningThreshold: 1000   # warn above this
  fallbackLimit: 1300      # hard fail above this (waza tokens compare --strict)
```

Run `waza tokens count .github/skills/my-new-skill/SKILL.md` while iterating to keep the skill within budget. The [`/skill-improve`](./prompts#skill-improve) prompt automates the audit + edit loop and shows a before/after delta.

## Local validation

Before opening a PR, run:

```bash
# Lint frontmatter and structure
waza check .github/skills/my-new-skill

# (Optional) Estimate token count
waza tokens count .github/skills/my-new-skill

# If you also wrote an eval suite (see "Eval suites"):
waza run .github/evals/my-new-skill/eval.yaml --no-cache
```

`waza check` validates the skill against the [agentskills.io](https://agentskills.io) frontmatter spec.

## CI integration

Adding the skill file is enough to ship it as a runtime capability. To opt the skill into the [PR-time eval matrix](./evals#how-ci-picks-up-your-eval), add a row to [`.github/evals/manifest.yaml`](https://github.com/Azure/git-ape/blob/main/.github/evals/manifest.yaml) **and** create `.github/evals/my-new-skill/eval.yaml`. The matrix runs the suite against every model in the selected tier on each PR that touches relevant files.

## Common pitfalls

- **Vague `description:` text** — the trigger grader will catch this. Specific verbs/nouns improve routing.
- **Directory name doesn't match `name:`** — `waza check` will flag it but the plugin loader silently skips the skill in some clients. Always match exactly.
- **Skill embeds persona** — move "you are X" framing into an `.agent.md` and have the agent call the skill. Skills should read like runbooks, not personas.
- **No output contract** — the `behavior` grader needs something concrete to verify. Document the literal output shape.

## Read next

- [Eval suites](./evals) — score the skill across models
- [Maintainer prompts](./prompts#skill-improve) — local audit + edit loop
- [Authoring agents](./agents) — wrap the skill in a persona
