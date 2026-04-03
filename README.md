# copilot-workspace-init

A repeatable GitHub Copilot initialization toolkit for VS Code. Drop it into your repository template and get consistent, disciplined Copilot behavior on every clone — with enforced GitFlow branching, Conventional Commits, mandatory plan-before-execute, file versioning standards, and optional IR/security engagement context.

---

## What It Does

When you clone a repo built from this template and run the **Initialize Copilot Workspace** task, it:

1. Prompts you for project-specific context (name, description, problem statement, language, IR flag)
2. Injects that context into `.github/copilot-instructions.md` as a structured header
3. Enables or strips the language and IR sections based on your answers
4. Scaffolds a standard directory structure with stub files and a pre-populated `CHANGELOG.md`
5. Commits everything as the first logical unit of work on the branch

Copilot automatically loads `copilot-instructions.md` on every session — no manual prompting required.

---

## Repository Structure

```
.
├── .github/
│   └── copilot-instructions.md   # Standing orders + project context (managed by init task)
└── .vscode/
    ├── tasks.json                 # VS Code task definitions
    ├── init-copilot.ps1          # Initialization script -- instructions + scaffold
    └── scaffold-structure.ps1    # Standalone directory structure scaffold
```

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| VS Code | Any recent version |
| GitHub Copilot extension | Must be installed and authenticated |
| PowerShell 5.1+ (`powershell.exe`) | Built into Windows -- no install required |
| Git | Must be on PATH |

> **Note:** The toolkit targets Windows PowerShell 5.1 for maximum compatibility. If your environment has PowerShell 7+ (`pwsh`) and you prefer it, change `"command": "powershell.exe"` to `"command": "pwsh"` in `.vscode/tasks.json`. Both versions are fully supported by the scripts.

---

## Setup

### Option A -- Use as a Repository Template

1. Fork or use this repository as a GitHub template
2. When creating a new repo, select this as the template source
3. Clone the new repo and follow the [Usage](#usage) steps

### Option B -- Add to an Existing Repo Template

Copy all four files into your existing template repository, maintaining the directory structure:

```
.github/copilot-instructions.md
.vscode/tasks.json
.vscode/init-copilot.ps1
.vscode/scaffold-structure.ps1
```

Commit them to the default branch of your template. Every repo created from that template will include the full toolkit on first clone.

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

> **Protected branch detection:** If you run the init task while on `main`, `master`, or `develop`, the script will write and stage the instructions file but skip the commit. It will print the exact commands to create your branch and commit the staged file.

### 3. Run the initialization task

```
Ctrl+Shift+P -> Tasks: Run Task -> Initialize Copilot Workspace
```

The terminal panel opens and the script prompts for each value interactively:

```
  Copilot Workspace Initialization
  ----------------------------------

  Project name: Acme Corp - API Refactor Phase 2
  Description (one sentence): Migrate legacy REST endpoints to GraphQL
  Problem statement: No versioning exists, breaking changes on every release
  IR/security engagement? (yes/no): no
  Scripting language? (python/powershell/both): python
```

All fields are required -- the script re-prompts on empty input and validates the `yes/no` and language fields. After the prompts complete, the script automatically runs the scaffold task to build the directory structure.

> **CLI / non-interactive use:** All five values can be passed as named parameters for pipeline or automation use:
> ```powershell
> powershell.exe -File .vscode/init-copilot.ps1 -ProjectName "Acme Corp" -Description "..." -ProblemStatement "..." -IsIR no -Language python
> ```

### 4. Re-scaffold if needed (optional)

The scaffold task can be run independently at any time without re-running the full init:

```
Ctrl+Shift+P -> Tasks: Run Task -> Scaffold Project Structure
```

Language is auto-detected from the committed `copilot-instructions.md` -- no input required. Only missing files and folders are created; existing content is never overwritten.

### 5. Begin work

Copilot now has full project context and standing instructions. Open a Copilot Chat session and describe your task -- it will restate the problem, present a plan including version impact, and wait for your approval before generating any code.

---

## Copilot Behavior Enforced

### Plan Before Execute

Copilot will **always** present a structured plan before taking any action:

```
## Problem Restatement
## Ambiguities / Missing Information
## Proposed Approach
## Files Affected
## Version Impact
## Assumptions
---
Awaiting approval to proceed.
```

The **Version Impact** block requires Copilot to state the current version -> new version and the changelog entry for every file it will touch before you approve. New files are always `v1.0`.

Copilot will not proceed until you provide an explicit approval signal: `approved`, `go ahead`, `proceed`, `yes`, `looks good`.

To skip the plan for a single request, say **"just do it"** -- plan mode resets on the next request.

Copilot must never:
- Assume silence or partial agreement is approval
- Skip the plan because the task seems simple
- Modify a file without updating its version header and `CHANGELOG.md`

### GitFlow Branching

| Branch Type | Pattern | Example |
|-------------|---------|---------|
| Feature | `feature/<description>` | `feature/add-oauth-support` |
| Bug Fix | `bugfix/<description>` | `bugfix/null-token-reference` |
| Hotfix | `hotfix/<description>` | `hotfix/auth-bypass-patch` |
| Release | `release/<semver>` | `release/2.1.0` |
| Chore | `chore/<description>` | `chore/update-dependencies` |

Copilot checks the current branch at the start of every session and blocks work if it detects `main` or `develop` as the active branch.

### Conventional Commits

All suggested commit messages follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>
```

Supported types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `perf`, `revert`

---

## File Versioning Standard

Every file created or modified must carry a versioned header. Copilot enforces this as part of the plan protocol -- it will never modify a file without updating its version and will never create a file without a `v1.0` header.

### Version Rules

| Change Type | Bump | Example |
|-------------|------|---------|
| Initial creation | `v1.0` | New module or script |
| Bug fix / minor enhancement | Increment minor | `v1.1`, `v1.2` |
| New feature in existing file | Increment minor | `v1.3` |
| Breaking change | Bump major | `v2.0` |

### Python Header Format

```python
"""
<Module Name>
<Module Name> v1.0
YYYYMMDD

One paragraph describing what this module does.

Functions:
  function_name()     # Brief description

Version History:
- v1.0: Initial implementation
"""
```

The header docstring must be the first statement in every `.py` file -- before imports.

### PowerShell Header Format

```powershell
<#
.SYNOPSIS
    One-line description.

.VERSION
    v1.0

.DATE
    YYYYMMDD

.NOTES
    Version History:
    - v1.0: Initial implementation
#>
```

`.VERSION` and `.DATE` are custom fields -- PowerShell ignores unknown help keys so they are safe to include in any `.ps1` file.

### CHANGELOG.md

Every project maintains a `CHANGELOG.md` in the repo root following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format. Copilot adds an entry under `## [Unreleased]` for every approved change using the appropriate subsection: `Added`, `Changed`, `Fixed`, `Removed`, `Deprecated`, or `Security`.

The scaffold task writes a pre-populated `CHANGELOG.md` with an `[Unreleased]` block and a `[0.1.0]` initial entry dated at scaffold time.

---

## Language Sections

When you select a language at init time, Copilot receives standing instructions specific to that stack. Unselected sections are stripped from the instructions file before it is committed.

### Python
Covers PEP 8 compliance, type hints, Google-style docstrings, import ordering, error handling (no bare `except`), logging standards (`logging` module, named loggers), and virtual environment / dependency management conventions (`venv`, pinned `requirements.txt`).

### PowerShell
Covers PS 5.1 compatibility rules (no `??`, no `&&/||`, no three-argument `Join-Path`), approved verb usage, `[CmdletBinding()]` and parameter validation, error handling (`$ErrorActionPreference = 'Stop'`, `try/catch`), output channel discipline (`Write-Verbose` vs `Write-Host`), and idempotency expectations.

### Both
Both sections are retained. Use this for repos that mix Python automation scripts with PowerShell operational scripts -- Copilot applies the appropriate standard based on the file it is working in.

---

## IR / Security Engagement Section

When you answer **yes** to the IR prompt, Copilot receives additional standing instructions covering:

- Defensive, reversible change posture -- flag anything that could degrade detection coverage
- SIEM/SPL awareness (index-time vs search-time operations, `.conf` files as source of truth)
- Detection engineering standards (MITRE ATT&CK mapping, false positive assessment, severity rating, sample event)
- SOAR / case management hygiene (project-defined schema, null handling, identifier validation)
- Sensitive data rules (no credentials, keys, or PII in logs, commits, or example data)

When you answer **no**, the entire IR section is stripped before the file is committed -- keeping context lean for non-security projects.

---

## Scaffolded Directory Structures

The scaffold task creates the following structure based on the language selected at init time. All folders include a `README.md` stub. Existing files are never overwritten.

### Python

```
src/                   # Core application source
  __init__.py          # Package marker
  example_module.py    # Versioned header example stub
  README.md
config/                # Environment config and constants -- no secrets
  README.md
docs/                  # Architecture decisions, runbooks, reference material
  README.md
logs/                  # Runtime output -- .gitkeep tracked, log files excluded
  .gitkeep
  README.md
scripts/               # Utility and automation scripts
  README.md
tests/                 # Unit and integration tests
  __init__.py
  README.md
requirements.txt
requirements-dev.txt
CHANGELOG.md           # Pre-populated with [Unreleased] + [0.1.0] initial entry
.gitignore
```

### PowerShell

```
Public/                # Exported functions -- one file per cmdlet
  Get-ExampleItem.ps1  # Versioned header example stub
  README.md
Private/               # Internal helpers -- not exported
  README.md
Tests/                 # Pester tests -- mirrors Public/ and Private/
  README.md
Config/                # JSON/PSD1 config data -- no secrets
  README.md
Docs/                  # Module documentation and generated help
  README.md
Scripts/               # Standalone operational scripts
  README.md
<ModuleName>.psd1      # Module manifest stub -- GUID auto-generated
<ModuleName>.psm1      # Module root -- dot-sources Public/ and Private/
CHANGELOG.md           # Pre-populated with [Unreleased] + [0.1.0] initial entry
.gitignore
```

### Both

All folders from both structures above are created. The `CHANGELOG.md` and `.gitignore` are written once at the repo root covering both language profiles.

---

## Re-Initializing

The init task is safe to re-run at any point. If a project context block already exists in `copilot-instructions.md`, it is **replaced** rather than appended. The scaffold task is also safe to re-run -- it only creates what is missing. This is useful when:

- Project scope or language profile changes mid-engagement
- You are starting a new phase of the same project
- You cloned an already-initialized repo and need to update the context

---

## Contributing

Issues and pull requests are welcome. If you extend the IR section for a specific domain (cloud, AppSec, GRC), consider keeping the toggle pattern (`<!-- IR_START -->` / `<!-- IR_END -->`) so the section remains optional for general use. The same applies to the language sections -- `<!-- PYTHON_START/END -->` and `<!-- POWERSHELL_START/END -->` are the markers the init script uses to strip unused sections.

---

## License

MIT
