---
title: "GitHub Codespaces"
sidebar_label: "Codespaces"
sidebar_position: 4
description: "Dev container and Codespaces setup"
---

# GitHub Codespaces Dev Environment

Git-Ape ships with two purpose-built [dev container](https://containers.dev/) configurations so you can pick the smallest, fastest environment for the work you're doing — whether you're editing the docs site or authoring agents, skills, and ARM templates.

## Choose Your Container

| Configuration | Use it when you want to… | Image | Footprint |
|---------------|--------------------------|-------|-----------|
| **Website** (`.devcontainer/website/`) | Edit Docusaurus docs, MDX pages, sidebars, or theme | `mcr.microsoft.com/devcontainers/javascript-node:1-24-bookworm` | Small (Node-only) |
| **Agent Engineering** (`.devcontainer/agent-engineering/`) | Author agents, skills, prompts, ARM templates, run IaC scans, deploy to Azure | `mcr.microsoft.com/devcontainers/python:3-3.12-bookworm` | Larger (Azure CLI, PowerShell, Python, Node) |

Both configs are detected automatically by Codespaces and the VS Code Dev Containers extension — you'll see a picker when you create a Codespace or run **Dev Containers: Reopen in Container**.

## Quick Start

### Option 1: GitHub Codespaces (recommended)

1. Navigate to the [Git-Ape repository](https://github.com/Azure/git-ape).
2. Click **Code** → **Codespaces** → **New codespace with options**.
3. In the **Dev container configuration** dropdown, pick **Git-Ape Website** or **Git-Ape Agent Engineering**.
4. Click **Create codespace**.
5. Wait for the container to build and the post-create setup to finish.
6. For the Agent Engineering container, sign in to Azure with `az login --use-device-code` when prompted.

### Option 2: VS Code Dev Containers (local)

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
2. Clone the repository and open it in VS Code.
3. Run **Dev Containers: Reopen in Container** from the command palette and pick the configuration you want.
4. For the Agent Engineering container, sign in to Azure with `az login`.

## What's Included

### Website Container

Optimized for Docusaurus development. Boots quickly and stays out of the way.

- **Base image**: `javascript-node:1-24-bookworm` (Node 24 LTS)
- **Features**: GitHub CLI, common-utils (Zsh + Oh My Zsh)
- **Post-create**: `npm install` in `website/`
- **Forwarded port**: 3333 (Docusaurus dev/serve)
- **Extensions**: GitHub Copilot, Copilot Chat, Mermaid Preview, MDX, ESLint
- **Remote user**: `node`

### Agent Engineering Container

Full toolchain for agent authoring, ARM template work, IaC scanning, and Azure deployments.

- **Base image**: `python:3-3.12-bookworm`
- **Features**: Azure CLI, PowerShell, GitHub CLI, Copilot CLI, Node 24
- **Post-create**: installs Checkov, PSRule for Azure, ARM-TTK, and the [waza](https://github.com/microsoft/waza) skill-eval CLI in parallel
- **Extensions**: GitHub Copilot, Copilot Chat, Azure Resource Groups, Azure Functions, Azure MCP Server, PSRule, [Chat Customizations Evaluations](https://github.com/microsoft/vscode-chat-customizations-evaluation)
- **Settings**: Azure MCP server preconfigured (`namespace` mode, read/write enabled); `chatCustomizationsEvaluations.waza.command` set to `waza`
- **Remote user**: `vscode`

### VS Code Tasks

The Docusaurus tasks below live in `.vscode/tasks.json` and are available in the **Website** container via **Terminal → Run Task** (or `⇧⌘B`):

| Task | What it does |
|------|--------------|
| **Docs: Dev Server** | Starts Docusaurus in hot-reload mode on port 3333 |
| **Docs: Build (local)** | Generates docs and builds with `baseUrl=/` for local preview |
| **Docs: Build (production)** | Generates docs and builds with `baseUrl=/git-ape/` for GitHub Pages |
| **Docs: Serve** | Builds locally and serves the static output on port 3333 |
| **Docs: Generate** | Runs `generate-docs.js` to regenerate auto-generated pages |
| **Docs: Install** | Installs website npm dependencies |

## After Setup

Once the environment is ready:

1. **Sign in to Azure** *(Agent Engineering only)*: Run `az login`. For Codespaces, `az login --use-device-code` works best.
2. **Verify the setup** *(Agent Engineering only)*: Run `az account show` to confirm your subscription.
3. **Start using Git-Ape**: Open Copilot Chat and try `@git-ape deploy a Python function app`.

## Customization

Each container is independent, so customize the file under the configuration you actually use:

- **Dev container features**: Add entries to the `features` object in `.devcontainer/<config>/devcontainer.json`.
- **Post-create tools**: Add installation commands to `.devcontainer/<config>/post-create.sh`.
- **VS Code extensions**: Add extension IDs to `customizations.vscode.extensions` in the same `devcontainer.json`.

Replace `<config>` with `website` or `agent-engineering`.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Codespace build fails | Check the creation log for errors. Common cause: feature version conflicts. |
| Wrong container picked | Stop the Codespace, then create a new one with **New codespace with options** and pick the right config. |
| `az login` fails in Codespaces | Use `az login --use-device-code` for browser-based auth. |
| ARM-TTK not found | You're probably in the Website container — switch to **Agent Engineering**, or run `pwsh` and verify the profile: `Get-Module arm-ttk -ListAvailable`. |
| Checkov not found | You're probably in the Website container — switch to **Agent Engineering**, or run `pip install --user checkov` manually. |
| Extensions missing | Reload the window (`Ctrl+Shift+P` → `Developer: Reload Window`). |
| Docs site broken locally | Use the **Docs: Build (local)** task or set `DOCUSAURUS_BASE_URL=/` before building. The production build uses `/git-ape/` as the base path. |
| Port 3333 already in use | Run `lsof -ti:3333 \| xargs kill -9` to free the port. |
