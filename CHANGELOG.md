# Changelog

## [0.1.1] - 2026-05-28

Changes since [v0.1.0](https://github.com/Azure/git-ape/releases/tag/v0.1.0):

### Bug Fixes

- **prereq-check:** parse az version via JSON on PowerShell (`47c76d2`)

### Chores

- **daily-status:** move schedule to 08:00 SGT (00:00 UTC) (`913988f`)
- **git-ape:** switch progress bar from ASCII to Unicode blocks (`a800e91`)

### Other Changes

- Merge pull request #126 from Azure/chore/git-ape-unicode-progress-bar (`058b4ed`)
- Merge pull request #125 from Azure/fix/release-drop-odd-minor-prerelease (`8f0498c`)
- Merge pull request #127 from Azure/chore/daily-status-schedule-sgt (`022208f`)
- Merge pull request #131 from Azure/fix/prereq-check-ps-az-parsing (`2ae81c7`)

All notable changes to this project are documented here.
This project follows [Semantic Versioning](https://semver.org/).

> Entries for `0.0.2` and `0.0.3` were reconstructed retroactively as part of
> recovering version-bump drift on `main`; future entries are generated
> automatically by the release workflow.

## [0.0.3] - 2026-05-13

### Documentation

- **extension:** fill VS Code Marketplace listing and surface install paths (`d6c6a8f`)
- Make VS Code install badges clickable via HTTPS redirects (`58905b5`)
- **extension:** add blank line between list and heading to satisfy markdownlint (`d6a6e3f`)

### Dependencies

- **website:** bump mermaid from 11.14.0 to 11.15.0 (`434796f`)

## [0.0.2] - 2026-05-11

### Features

- **extension:** add VS Code extension scaffolding and CI/CD workflows (`b6bcc13`)
- **extension:** set publisher to Git-APE and auto-publish to VS Code Marketplace (`845b6c2`)
- **release:** publish to VS Code Marketplace using odd-minor channel convention (`6b5cebf`)
- **plugin:** add `ape-context` plugin for enhanced context management (`ac2c892`)
- **devcontainer:** customize dev environment and add VS Code tasks (`f5fce29`)
- **devcontainer:** split into website and agent-engineering configs (`2131f9f`)
- **devcontainer:** add waza CLI and chat-customizations-evaluations to agent container (`d4972db`)
- **devcontainer:** ensure sandbox dependencies are installed before IaC tools (`d428922`)
- Add `CONTRIBUTING.md` and structural PR validation CI (`0dec1ad`)
- Add agentic workflows for issue-triage and daily repo status (`14bda1c`, `2de05d1`)

### Bug Fixes

- **extension:** correct chat contribution schema and bump engines/Node (`71c8c9d`)
- **extension:** set publisher to Git-ApeTeam (`2302f73`)
- **release:** remove stray `gh release upload` from marketplace publish step (`11c8fe4`)
- **workflows:** disable lockdown on issue-triage-agent (`8732a46`)
- **workflows:** silence SC2015 in gh-aw lock files and fix README fences (`499d25c`)
- **workflows:** recompile gh-aw lock files to v0.72.1 for valid awf release (`19cab81`)
- **devcontainer:** use sudo for waza installation to ensure proper binary placement (`96ebebe`)
- **devcontainer:** correct image tag for Git-Ape Website (`5c84ec5`)

### Documentation

- Reframe pitch as workload-agnostic and document workflow activation (`5080705`)

### Performance

- **devcontainer:** tighten install steps in both containers (`e2a1eab`)

### CI/CD

- **deps:** add Dependabot, bump Node to 24 LTS (`3d23ee0`)

### Chores

- **devcontainer:** drop Node feature from agent container (`451fde8`)
- Remove downloaded actionlint binary (`58df8de`)

### Dependencies

- **website:** bump the react group across 1 directory with 2 updates (`3ddf958`)
- **website:** bump the docusaurus group (`caa7d32`)
- **website:** bump `@babel/plugin-transform-modules-systemjs` (`ef6a125`)
- **website:** bump `fast-uri` from 3.1.0 to 3.1.2 (`6997bdb`)
- **actions:** bump the github-actions group with 7 updates (`e8aa1a3`)

## [0.0.1] - 2026-05-05

Initial tagged release.
