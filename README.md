# copilot-workspace-init

A repeatable GitHub Copilot initialization toolkit for VS Code. Drop it into your repository template and get consistent, disciplined Copilot behavior on every clone — with enforced GitFlow branching, Conventional Commits, mandatory plan-before-execute, and an optional IR/security engagement context block.

---

## What It Does

When you clone a repo built from this template and run the **Initialize Copilot Workspace** task, it:

1. Prompts you for project-specific context (name, description, problem statement)
2. Injects that context into `.github/copilot-instructions.md` as a structured header
3. Optionally enables or strips the IR/security section based on engagement type
4. Commits the initialized file as the first logical unit of work on the branch

Copilot automatically loads `copilot-instructions.md` on every session — no manual prompting required.

---

## Repository Structure

```
.
├── .github/
│   └── copilot-instructions.md   # Standing orders + project context (managed by init task)
└── .vscode/
    ├── tasks.json                 # VS Code task definition
    └── init-copilot.ps1          # Initialization script called by the task
```

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| VS Code | Any recent version |
| GitHub Copilot extension | Must be installed and authenticated |
| PowerShell 5.1+ (`powershell`) | Required for the init script |
| Git | Must be on PATH |

> **Note:** If your environment uses PowerShell 7+ instead of Windows PowerShell 5.1, change `"command": "powershell"` to `"command": "pwsh"` in `.vscode/tasks.json`.

---

## Setup

### Option A — Use as a Repository Template

1. Fork or use this repository as a GitHub template
2. When creating a new repo, select this as the template source
3. Clone the new repo and follow the [Usage](#usage) steps

### Option B — Add to an Existing Repo Template

Copy the three files into your existing template repository, maintaining the directory structure:

```bash
.github/copilot-instructions.md
.vscode/tasks.json
.vscode/init-copilot.ps1
```

Commit them to the default branch of your template. Every repo created from that template will include the toolkit on first clone.

---

## Usage

### 1. Clone your repo and open it in VS Code

```bash
git clone <your-repo-url>
code <repo-directory>
```

### 2. Create your working branch

Follow the GitFlow naming conventions enforced by this toolkit before running the task:

```bash
git checkout -b feature/your-feature-name
```

### 3. Run the initialization task

```
Ctrl+Shift+P → Tasks: Run Task → Initialize Copilot Workspace
```

VS Code will present four sequential input prompts:

| Prompt | Example |
|--------|---------|
| Project name | `Acme Corp - API Refactor Phase 2` |
| One-sentence description | `Migrate legacy REST endpoints to GraphQL` |
| Problem statement | `Existing REST API has no versioning and causes breaking changes on every release` |
| IR/security engagement? | `yes` or `no` |
| Scripting language(s)? | `python`, `powershell`, or `both` |

### 4. Begin work

Copilot now has full project context and standing instructions. Open a Copilot Chat session and describe your task — it will restate the problem, present a plan, and wait for your approval before generating any code.

---

## Copilot Behavior Enforced

### Plan Before Execute

Copilot will **always** present a structured plan before taking any action:

```
## Problem Restatement
## Ambiguities / Missing Information
## Proposed Approach
## Files Affected
## Assumptions
---
Awaiting approval to proceed.
```

It will not proceed until you provide an explicit approval signal (`approved`, `go ahead`, `proceed`, `yes`, `looks good`).

To skip the plan for a single request, say **"just do it"** — plan mode resets on the next request.

### GitFlow Branching

| Branch Type | Pattern | Example |
|-------------|---------|---------|
| Feature | `feature/<description>` | `feature/add-oauth-support` |
| Bug Fix | `bugfix/<description>` | `bugfix/null-token-reference` |
| Hotfix | `hotfix/<description>` | `hotfix/auth-bypass-patch` |
| Release | `release/<semver>` | `release/2.1.0` |
| Chore | `chore/<description>` | `chore/update-dependencies` |

Copilot will check the current branch at the start of every session and block work if it detects `main` or `develop` as the active branch.

### Conventional Commits

All suggested commit messages follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>
```

Supported types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `perf`, `revert`

---

## IR / Security Engagement Section

When you answer **yes** to the IR prompt, Copilot receives additional standing instructions covering:

- Defensive, reversible change posture
- SIEM/SPL awareness (index-time vs search-time, `.conf` as source of truth)
- Detection engineering standards (MITRE ATT&CK mapping, false positive assessment, severity)
- SOAR/case management hygiene (null handling, template variable scoping)
- Sensitive data rules (no credentials, keys, or PII in logs, commits, or example data)

When you answer **no**, this entire section is stripped from the instructions file before it is committed — keeping the context lean for non-security projects.

---

## Re-Initializing

The task is safe to re-run at any point. If a project context block already exists in `copilot-instructions.md`, it is **replaced** rather than appended. This is useful when:

- Project scope changes mid-engagement
- You are starting a new phase of the same project
- You cloned an already-initialized repo and need to update the context

---

## Language Sections

When you select a language at init time, Copilot receives standing instructions specific to that stack.

### Python
Covers PEP 8 compliance, type hints, Google-style docstrings, import ordering, error handling (no bare `except`), logging standards, and virtual environment / dependency management conventions.

### PowerShell
Covers PS 5.1 compatibility rules, approved verb usage, `[CmdletBinding()]` and parameter validation, error handling patterns, output channel discipline (`Write-Verbose` vs `Write-Host`), and idempotency expectations.

### Both
Both sections are retained. Use this when a project mixes Python automation scripts with PowerShell operational scripts — Copilot will apply the appropriate standard based on the file extension it is working in.

---

## Contributing

Issues and pull requests are welcome. If you extend the IR section for a specific domain (cloud, AppSec, GRC), consider keeping the toggle pattern (`<!-- IR_START -->` / `<!-- IR_END -->`) so the section remains optional for general use.

---

## License

MIT
