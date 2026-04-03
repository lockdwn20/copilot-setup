<!-- PROJECT_CONTEXT_START -->
<!-- PROJECT_CONTEXT_END -->

---

# GitHub Copilot — Standing Instructions

> These instructions are active for every Copilot session in this repository.
> The Project Context block above is managed by the **Initialize Copilot Workspace** VS Code task.
> Do not edit the PROJECT_CONTEXT markers manually.

---

## § 1 — Core Behavior: Plan Before Execute

**This rule has no exceptions unless the user explicitly invokes override.**

Before generating any code, configuration, file changes, or shell commands, Copilot **must**:

1. **Restate** the request in its own words to confirm understanding
2. **List** every file that will be created, modified, or deleted
3. **Describe** the approach at a logical level — not pseudocode, but intent
4. **Flag** any assumptions being made that have not been explicitly stated
5. **Ask** one clarifying question if the request is ambiguous — never guess
6. **Versioning** — for every file being modified: state the current version, the new version, and the changelog entry that will be written. For new files, state v1.0 and the initial changelog entry.

Then **stop and wait** for explicit approval before proceeding.

### Valid Approval Signals
- "approved", "go ahead", "proceed", "yes", "do it", "looks good"

### Override Signal
- "just do it" — skips the plan for **that single request only**. The next request resets to full plan mode.

### What Copilot Must Never Do
- Assume silence or partial agreement is approval
- Begin implementation while still asking questions
- Skip the plan because the task "seems simple"
- Generate multiple files in one response without listing them first
- Modify a file without updating its version header and CHANGELOG.md

---

## § 2 — Git Branching Standards (GitFlow)

### Branch Naming Convention

| Branch Type | Pattern | Example |
|-------------|---------|---------|
| Feature | `feature/<short-description>` | `feature/add-oauth-support` |
| Bug Fix | `bugfix/<short-description>` | `bugfix/eventtype-tag-mismatch` |
| Hotfix | `hotfix/<short-description>` | `hotfix/api-response-timeout` |
| Release | `release/<semver>` | `release/1.2.0` |
| Chore | `chore/<short-description>` | `chore/update-gitignore` |

### Branch Rules
- **Never commit directly to `main` or `develop`**
- `feature/*` and `bugfix/*` always branch from `develop`
- `hotfix/*` branches from `main` and merges back into both `main` and `develop`
- `release/*` branches from `develop`, merges into both `main` and `develop`
- Names must be: **lowercase, hyphen-separated, no spaces, no special characters**
- Keep descriptions short — 3 to 5 words maximum

### Session Start Check
At the beginning of every work session, Copilot must confirm:
```
Current branch: [output of git branch --show-current]
```
If the current branch is `main` or `develop`, Copilot must **stop** and prompt the user to create a correctly named branch before proceeding with any work.

---

## § 3 — Conventional Commits

All commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format
```
<type>(<scope>): <short description>

[optional body — explain WHY, not WHAT]

[optional footer — breaking changes, issue refs]
```

### Commit Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature or capability added |
| `fix` | Bug fix — corrects unintended behavior |
| `chore` | Maintenance — tooling, deps, config, cleanup |
| `docs` | Documentation changes only |
| `refactor` | Code restructured with no behavior change |
| `test` | Adding or modifying tests |
| `ci` | CI/CD pipeline or build system changes |
| `perf` | Performance improvement |
| `revert` | Reverts a previous commit |

### Rules
- Subject line: **72 characters max**, imperative mood ("add" not "added"), no trailing period
- Scope is optional but encouraged — use the affected module or component
- Copilot must **always suggest a commit message** for every logical unit of work
- One logical change per commit — do not bundle unrelated changes

### Examples
```
feat(auth): add OAuth2 token validation middleware
fix(pipeline): resolve null reference in event routing script
chore(deps): update requests library to v2.31.0
docs(runbook): add phase 0 discovery procedures
```

---


## § 4 — File Versioning Standard

Every file created or modified in this project must carry a versioned header. This is a **hard requirement** — Copilot must never modify a file without updating its version and must never create a file without a v1.0 header.

### Version Rules

| Change Type | Version Bump | Example |
|-------------|-------------|---------|
| Initial creation | `v1.0` | New module or script |
| Bug fix / minor enhancement | Increment minor | `v1.1`, `v1.2` |
| New feature added to existing file | Increment minor | `v1.3` |
| Breaking change (signature, behaviour, output) | Bump major | `v2.0` |

Date format: `YYYYMMDD` — always use today's date when modifying.

---

### Python File Header

Every `.py` file must open with a module-level docstring in this exact format:

```python
"""
<Module Name>
<Module Name> v1.0
YYYYMMDD

<One paragraph describing what this module does.>

Functions:
  function_name()     # Brief description
  other_function()    # Brief description

Version History:
- v1.0: Initial implementation
"""
```

**Rules:**
- The header docstring must be the **first statement** in the file — before imports
- `Functions:` lists every public function with a one-line description
- When modifying: increment version, update date, add one entry to `Version History`
- Version history entries must describe the **what and why**, not just "updated"

**Example — after a bug fix:**
```python
"""
Event Processor
Event Processor v1.2
20260402

Processes incoming events and routes them to the appropriate handler.

Functions:
  process_event()     # Parse and route a single event dict
  batch_process()     # Process a list of events with error isolation

Version History:
- v1.0: Initial implementation
- v1.1: Add batch_process() for bulk ingestion support
- v1.2: Fix KeyError in process_event() when event type field is absent
"""
```

---

### PowerShell File Header

Every `.ps1` file must use comment-based help extended with a version block:

```powershell
<#
.SYNOPSIS
    One-line description of what this script or function does.

.DESCRIPTION
    Full description. Include important behaviours, side effects,
    and any dependencies.

.VERSION
    v1.0

.DATE
    YYYYMMDD

.PARAMETER ParameterName
    Description of the parameter.

.EXAMPLE
    Verb-Noun -Parameter Value

.NOTES
    Version History:
    - v1.0: Initial implementation
#>
```

**Rules:**
- `.VERSION` and `.DATE` are custom fields — PowerShell ignores unknown help keys, so they are safe to include
- `.NOTES` carries the full version history
- When modifying: increment `.VERSION`, update `.DATE`, add one line to `Version History` in `.NOTES`
- For function files in `Public/` or `Private/`, the help block goes inside the function, not at the top of the file

**Example — after adding a parameter:**
```powershell
<#
.SYNOPSIS
    Retrieves configuration values from the project config directory.

.VERSION
    v1.2

.DATE
    20260402

.NOTES
    Version History:
    - v1.0: Initial implementation
    - v1.1: Add -Strict flag to throw on missing keys instead of returning null
    - v1.2: Support array values in JSON config via -AsArray switch
#>
```

---

### CHANGELOG.md

Every project must maintain a `CHANGELOG.md` in the repo root following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format with [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Copilot must update CHANGELOG.md as part of every approved change.** The entry goes under `## [Unreleased]` using the appropriate subsection:

| Subsection | When to use |
|------------|-------------|
| `### Added` | New files, functions, features, parameters |
| `### Changed` | Modified behaviour, renamed items, refactored logic |
| `### Fixed` | Bug fixes |
| `### Removed` | Deleted files, functions, or parameters |
| `### Deprecated` | Items that will be removed in a future version |
| `### Security` | Vulnerability fixes |

**Format:**
```markdown
## [Unreleased]

### Added
- `module_name.process_event()` — initial implementation of event routing logic

### Fixed
- `module_name.process_event()` — resolve KeyError when event type field is absent
```


<!-- PYTHON_START -->
## § 5 — Python Coding Standards

> This section is active when the project language is set to **python** or **both**.

### Style and Formatting
- All code must comply with [PEP 8](https://peps.python.org/pep-0008/)
- Maximum line length: **99 characters**
- Use **f-strings** for string interpolation — never `%` formatting or `.format()`
- Use **double quotes** for strings unless the string itself contains double quotes

### Type Hints
- All function signatures must include type hints (PEP 484)
- Use `Optional[X]` for values that may be `None`
- Return types must always be declared, including `-> None`

### Docstrings
- All modules, classes, and public functions must have a docstring
- Use **Google-style** docstrings

### Imports
Order imports in three groups separated by blank lines:
1. Standard library
2. Third-party packages
3. Local modules

### Error Handling
- **Never** use bare `except:` clauses — always specify the exception type
- Use `except Exception as e` only as a last resort and always log the error
- Prefer specific exception types and handle them individually

### Logging
- Use the `logging` module — **never** use `print()` for diagnostic output in scripts
- Always get a named logger: `logger = logging.getLogger(__name__)`
- Use appropriate levels: `DEBUG` for trace, `INFO` for milestones, `WARNING` for recoverable issues, `ERROR` for failures

### Virtual Environments and Dependencies
- Every project must use `venv` for environment isolation
- Dependencies must be pinned in `requirements.txt` with exact versions
- Dev-only dependencies go in `requirements-dev.txt`
- Never commit `.venv/`, `__pycache__/`, or `*.pyc` — ensure `.gitignore` covers these

### General Rules
- Functions must do one thing — if a function needs more than a paragraph to describe, split it
- No magic numbers — assign constants at the module level with descriptive names
- Copilot must suggest a `requirements.txt` entry for every third-party import it introduces

<!-- PYTHON_END -->

<!-- POWERSHELL_START -->
## § 6 — PowerShell Coding Standards

> This section is active when the project language is set to **powershell** or **both**.
> All scripts must be compatible with **Windows PowerShell 5.1**.

### Script Structure
Every script must open with a `#Requires -Version 5.1` declaration and comment-based help block covering `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE`.

### Functions and Naming
- Use **approved PowerShell verbs** — run `Get-Verb` to verify before using a new verb
- Function names follow `Verb-Noun` PascalCase: `Get-EventRecord`, `Invoke-ApiRequest`
- Variable names use camelCase: `$inputPath`, `$recordCount`
- **Never use aliases** in scripts (`%`, `?`, `gci`, etc.) — always use full cmdlet names

### Parameters
All non-trivial scripts must use `[CmdletBinding()]` and declared parameters with validation attributes (`[Parameter(Mandatory)]`, `[ValidateSet(...)]`, `[ValidateNotNullOrEmpty()]`).

### Error Handling
- Set `$ErrorActionPreference = 'Stop'` at the top of every script
- Wrap external calls and file operations in `try/catch` blocks
- Always include a specific error message — never silently swallow errors

### Output
- Use `Write-Verbose` for diagnostic trace output (visible with `-Verbose` flag)
- Use `Write-Warning` for recoverable issues
- Use `Write-Error` for failures — never use `Write-Host` for errors
- Reserve `Write-Host` for intentional user-facing console output only
- Functions should output objects via the pipeline, not formatted strings

### Compatibility Rules (PS 5.1)
- Do not use `??` null coalescing — use `if ($null -eq $x)` instead
- Do not use `&&` or `||` pipeline chain operators — use `if ($LASTEXITCODE -ne 0)`
- Write files with explicit no-BOM UTF-8: `New-Object System.Text.UTF8Encoding($false)`
- Do not use `ForEach-Object -Parallel` — not available in PS 5.1

### General Rules
- Scripts must be idempotent where possible — re-running should not cause unintended side effects
- Always validate input paths with `Test-Path` before use
- Copilot must flag any cmdlet or syntax introduced after PS 5.1

<!-- POWERSHELL_END -->

<!-- IR_START -->
## § 7 — IR / Security Engagement Context

> This section is active for security operations and detection engineering engagements.
> It is removed by the init task for non-IR projects.

### Domain Posture
- This is a **security-sensitive environment** — treat all changes as potentially production-impacting
- Prefer **defensive, reversible changes**; flag anything that could degrade detection coverage or alert fidelity
- When in doubt, do less and ask — never assume a security control change is safe

### Splunk / CIM Awareness
- CIM normalization is implemented via `eventtypes` and `tags` in `.conf` files — these are **not** the same as raw field extractions
- `.conf` files are the authoritative source of truth; never suggest UI-only changes as a solution
- Always distinguish between **index-time** and **search-time** operations — state which one applies
- Search macros use backtick syntax in SPL: `` `macro_name` ``
- Before suggesting any SPL, verify that referenced fields and macros exist in context

### Detection Engineering Standards
Every new detection must include:
- [ ] Description of what behavior is being detected
- [ ] MITRE ATT&CK Tactic and Technique (e.g., `TA0006 / T1003.006 - DCSync`)
- [ ] False positive assessment — what legitimate activity could trigger this?
- [ ] Severity rating: `Critical / High / Medium / Low / Informational`
- [ ] Sample event or test case

Alert logic changes must include an inline comment explaining the rationale for the change.

### SOAR / Case Management Context
- Case templates follow a **project-defined schema** — do not introduce new templates or schema changes without discussion
- Routing scripts must explicitly define all schema items before use — never assume a field or variable exists in scope
- All API integrations must handle `null`, `undefined`, and HTTP error responses gracefully
- Any string concatenation used to build identifiers (template names, keys, prefixes) must be validated for correct format before committing

### Sensitive Data Rules
- **Never** log, print, commit, or suggest code that exposes credentials, API keys, tokens, or PII
- Mask or redact sensitive fields in all example data and test fixtures
- Any code touching authentication, access control, or credential management must be **explicitly flagged** for user review before implementation

<!-- IR_END -->

---

## § 8 — Problem Framing Protocol

When a new task or feature request is received, Copilot will structure its response as follows before any planning or execution:

```
## Problem Restatement
[Copilot's understanding of what needs to be done]

## Ambiguities / Missing Information
[Any gaps that need clarification before work begins]

## Proposed Approach
[High-level intent — not code, but logic and rationale]

## Files Affected
[List of files to be created, modified, or deleted]

## Version Impact
[For each modified file: current version → new version and the changelog entry to be written]
[For new files: v1.0 — initial implementation]

## Assumptions
[Anything being assumed that the user has not explicitly stated]

---
Awaiting approval to proceed.
```

Copilot must not deviate from this structure for new tasks. For follow-up clarifications within the same task, abbreviated responses are acceptable.
