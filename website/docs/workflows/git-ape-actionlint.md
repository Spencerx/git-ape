---
title: "Git-Ape: Workflow Lint"
sidebar_label: "Workflow Lint"
description: "GitHub Actions workflow: Git-Ape: Workflow Lint"
---

<!-- AUTO-GENERATED — DO NOT EDIT. Source: .github/workflows/git-ape-actionlint.yml -->


# Git-Ape: Workflow Lint

**Workflow file:** `.github/workflows/git-ape-actionlint.yml`

## Triggers

- **`pull_request`** — paths: `.github/workflows/**, .github/actions/**`


## Permissions

- `contents: read`

## Jobs

### `actionlint`

| Property | Value |
|----------|-------|
| **Display Name** | actionlint |
| **Runs On** | `ubuntu-latest` |
| **Steps** | 2 |



## Source

<details>
<summary>Click to view full workflow YAML</summary>

```yaml
name: "Git-Ape: Workflow Lint"

on:
  pull_request:
    paths:
      - '.github/workflows/**'
      - '.github/actions/**'

permissions:
  contents: read

jobs:
  actionlint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Run actionlint
        run: |
          set -euo pipefail
          # Download the official actionlint binary into the workspace.
          bash <(curl --silent --show-error --fail \
            https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash)
          ./actionlint -color

```

</details>
