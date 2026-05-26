---
title: "VS Code vs Copilot CLI"
sidebar_label: "VS Code vs CLI"
sidebar_position: 5
description: "How Git-Ape behaves across the VS Code agent plugin and Copilot CLI surfaces"
---

# VS Code vs Copilot CLI

Git-Ape ships as a single cross-tool plugin. The same `plugin.json` manifest at the repo root is loaded by both the [VS Code agent plugin](https://code.visualstudio.com/docs/copilot/customization/agent-plugins) system and the [GitHub Copilot CLI](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference). You don't need to maintain two copies — pick whichever surface you prefer.

## Feature parity

| Capability | VS Code agent plugin | Copilot CLI |
|---|---|---|
| `@git-ape` and other agents | ✅ Available in Copilot Chat | ✅ Available as agent participants |
| Slash commands (`/prereq-check`, `/azure-security-analyzer`, …) | ✅ Surface in Chat command picker | ✅ Available via `/` in CLI |
| Skills auto-loading | ✅ Listed under **Configure Skills** | ✅ Listed via `copilot skill list` |
| MCP servers | ✅ Auto-started, listed in **MCP: List Servers** | ✅ Started by CLI on session start |
| Hooks (`SessionStart`, `PreToolUse`, …) | ✅ Run alongside workspace hooks | ✅ Run alongside CLI hooks |
| Marketplace install | ✅ [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=Git-ApeTeam.git-ape) · `chat.plugins.marketplaces` | ✅ `copilot plugin marketplace add` |
| Install from source | ✅ **Chat: Install Plugin From Source** | ✅ `copilot plugin install <git-url>` |
| Local dev install | ✅ `chat.pluginLocations` | ✅ Local clone + plugin link |
| Per-workspace enable/disable | ✅ Extensions view + Chat Customizations editor | ✅ Per-project plugin config |
| Workspace recommendations | ✅ `.github/copilot/settings.json` (this repo) | ✅ Same file |
| Update notifications | ✅ Driven by `version` in `plugin.json` | ✅ Driven by `version` in `plugin.json` |

## When to use which

**Use the VS Code agent plugin when you want:**

- An interactive, GUI-driven deployment loop (`@git-ape deploy a Function App`).
- Inline review of generated ARM templates and architecture diagrams.
- Easy enable/disable per workspace from the Extensions view.

**Use the Copilot CLI when you want:**

- A scriptable, terminal-first workflow (CI runners, headless dev containers, Codespaces over SSH).
- To compose Git-Ape with shell pipelines and existing CLI tooling.
- A consistent experience across machines that may not have VS Code installed.

Both modes share the same security gates, cost estimator, and deployment state under `.azure/deployments/` — switching between them on the same repo is safe.

## Workspace recommendation

This repository ships a workspace recommendation at [.github/copilot/settings.json](https://github.com/Azure/git-ape/blob/main/.github/copilot/settings.json) so contributors who open it in VS Code with `chat.plugins.enabled: true` get prompted to install Git-Ape automatically through the agent-plugin marketplace:

```jsonc
{
  "extraKnownMarketplaces": {
    "git-ape": {
      "source": { "source": "github", "repo": "Azure/git-ape" }
    }
  },
  "enabledPlugins": {
    "git-ape@git-ape": true
  }
}
```

If your organization has `chat.plugins.enabled` disabled, contributors can install Git-Ape from the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=Git-ApeTeam.git-ape) instead — that path is a regular extension install and bypasses the plugin gating.

The same file is honored by the Copilot CLI when running inside the workspace.

## Cross-tool authoring rules

If you fork Git-Ape or build a similar plugin, keep the manifest cross-tool compatible:

- Place `plugin.json` at the repo root (VS Code also accepts `.plugin/plugin.json`, `.github/plugin/plugin.json`, or `.claude-plugin/plugin.json`).
- Use a plain kebab-case `name` (no `owner/repo` prefix). VS Code silently skips invalid names.
- Skill `name` fields in `SKILL.md` frontmatter must match their directory name and be plain kebab-case.
- Bump `version` in both `plugin.json` and `marketplace.json` when publishing changes — VS Code's update check uses these fields.

## Related

- [Installation](./installation) — full install paths for both surfaces
- [Plugin manifest reference](../reference/plugin-json) — current `plugin.json` contents
- [VS Code agent plugin docs](https://code.visualstudio.com/docs/copilot/customization/agent-plugins)
- [Copilot CLI plugin reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference)
