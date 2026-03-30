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
fix(pipeline): resolve null reference in caseTemplate routing script
chore(deps): update requests library to v2.31.0
docs(runbook): add phase 0 discovery procedures
```

---

<!-- IR_START -->
## § 4 — IR / Security Engagement Context

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

### TheHive / SOAR Context
- Case templates follow the **consolidated 25-template schema** — do not introduce new templates without discussion
- JavaScript routing scripts must explicitly define `caseTemplate` before use — never assume it exists in scope
- All API integrations must handle `null`, `undefined`, and HTTP error responses gracefully
- Prefix concatenation for case template names must be validated — confirm format before committing

### Sensitive Data Rules
- **Never** log, print, commit, or suggest code that exposes credentials, API keys, tokens, or PII
- Mask or redact sensitive fields in all example data and test fixtures
- Any code touching authentication, access control, or credential management must be **explicitly flagged** for user review before implementation

<!-- IR_END -->

---

## § 5 — Problem Framing Protocol

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

## Assumptions
[Anything being assumed that the user has not explicitly stated]

---
Awaiting approval to proceed.
```

Copilot must not deviate from this structure for new tasks. For follow-up clarifications within the same task, abbreviated responses are acceptable.
