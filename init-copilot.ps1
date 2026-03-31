#Requires -Version 5.1
<#
.SYNOPSIS
    Initializes the GitHub Copilot workspace for a newly cloned repository.

.DESCRIPTION
    - Prompts interactively for project context when parameters are not supplied
    - Injects a project context block into .github/copilot-instructions.md
    - Toggles IR and language sections based on engagement type
    - Stages and commits the updated instructions file
    - Safe to re-run: replaces existing context block rather than appending
    - All parameters are optional — omit them to use interactive Read-Host prompts
    - Supply all parameters to run non-interactively (CI/CD or CLI use)

.PARAMETER ProjectName
    Human-readable project name. Used in the context block and commit message.

.PARAMETER Description
    One-sentence description of what this project delivers.

.PARAMETER ProblemStatement
    The problem being solved — current state and desired outcome.

.PARAMETER IsIR
    'yes' to retain the IR/security section. 'no' to strip it.

.PARAMETER Language
    'python' to retain Python standards only, 'powershell' for PowerShell only, 'both' for all language sections.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .vscode/init-copilot.ps1 `
        -ProjectName "Acme Corp - API Modernization" `
        -Description "Migrate legacy REST endpoints to a versioned API" `
        -ProblemStatement "Zero normalization exists across 1381 sourcetypes" `
        -IsIR "yes"
#>

param(
    [string]$ProjectName      = "",
    [string]$Description      = "",
    [string]$ProblemStatement = "",
    [string]$IsIR             = "",
    [string]$Language         = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve paths ──────────────────────────────────────────────────────────────
# Use git to locate the repo root — reliable regardless of PS invocation mode.
# git rev-parse returns forward slashes on Windows; normalize to OS separator.
$repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim().Replace('/', [IO.Path]::DirectorySeparatorChar)
if (-not $repoRoot) {
    Write-Error "Unable to determine repository root. Ensure git is on PATH and you are inside a git repository."
    exit 1
}

# Join-Path only accepts two arguments in PS 5.1 — nest calls for compatibility
$instructionsPath = Join-Path (Join-Path $repoRoot '.github') 'copilot-instructions.md'

# ── Pre-flight checks ──────────────────────────────────────────────────────────
if (-not (Test-Path $instructionsPath)) {
    Write-Error "copilot-instructions.md not found at expected path:`n  $instructionsPath`n`nEnsure the repo template includes .github/copilot-instructions.md"
    exit 1
}

$gitCheck = git -C $repoRoot rev-parse --is-inside-work-tree 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not inside a git repository. Run 'git init' or clone a repo first."
    exit 1
}

# ── Branch protection check ────────────────────────────────────────────────────
$currentBranch   = git -C $repoRoot branch --show-current
$protectedBranches = @('main', 'master', 'develop')
$skipCommit      = $protectedBranches -contains $currentBranch

if ($skipCommit) {
    Write-Host ""
    Write-Host "  ⚠️  Protected branch detected: '$currentBranch'" -ForegroundColor Yellow
    Write-Host "  The instructions file will be written and staged but NOT committed." -ForegroundColor Yellow
    Write-Host "  Direct commits to this branch will be rejected by AZDO." -ForegroundColor Yellow
    Write-Host ""
}

# ── Interactive prompts (fires only when params not supplied) ─────────────────
Write-Host ""
Write-Host "  Copilot Workspace Initialization" -ForegroundColor Cyan
Write-Host "  $(([string][char]0x2500) * 34)" -ForegroundColor DarkGray
Write-Host ""

if (-not $ProjectName) {
    $ProjectName = (Read-Host "  Project name").Trim()
    while (-not $ProjectName) {
        Write-Host "  Project name is required." -ForegroundColor Red
        $ProjectName = (Read-Host "  Project name").Trim()
    }
}

if (-not $Description) {
    $Description = (Read-Host "  Description (one sentence)").Trim()
    while (-not $Description) {
        Write-Host "  Description is required." -ForegroundColor Red
        $Description = (Read-Host "  Description (one sentence)").Trim()
    }
}

if (-not $ProblemStatement) {
    $ProblemStatement = (Read-Host "  Problem statement").Trim()
    while (-not $ProblemStatement) {
        Write-Host "  Problem statement is required." -ForegroundColor Red
        $ProblemStatement = (Read-Host "  Problem statement").Trim()
    }
}

if (-not $IsIR) {
    do {
        $IsIR = (Read-Host "  IR/security engagement? (yes/no)").Trim().ToLower()
        if ($IsIR -notin @('yes','no')) {
            Write-Host "  Please enter 'yes' or 'no'." -ForegroundColor Red
        }
    } while ($IsIR -notin @('yes','no'))
}

if (-not $Language) {
    do {
        $Language = (Read-Host "  Scripting language? (python/powershell/both)").Trim().ToLower()
        if ($Language -notin @('python','powershell','both')) {
            Write-Host "  Please enter 'python', 'powershell', or 'both'." -ForegroundColor Red
        }
    } while ($Language -notin @('python','powershell','both'))
}

Write-Host ""

# ── Read template ──────────────────────────────────────────────────────────────
Write-Host "  Reading instructions template..." -ForegroundColor Cyan
$content = Get-Content $instructionsPath -Raw

# ── Strip IR block if non-security engagement ───────────────────────────────
if ($IsIR -eq 'no') {
    Write-Host "  IR section: DISABLED (non-security engagement)" -ForegroundColor Yellow
    $content = $content -replace '(?s)\r?\n?<!-- IR_START -->.*?<!-- IR_END -->\r?\n?', "`n"
} else {
    Write-Host "  IR section: ENABLED (security engagement)" -ForegroundColor Green
}

# ── Toggle language sections ───────────────────────────────────────────────────
switch ($Language) {
    'python' {
        Write-Host "  Language  : PYTHON only" -ForegroundColor Green
        $content = $content -replace '(?s)\r?\n?<!-- POWERSHELL_START -->.*?<!-- POWERSHELL_END -->\r?\n?', "`n"
    }
    'powershell' {
        Write-Host "  Language  : POWERSHELL only" -ForegroundColor Green
        $content = $content -replace '(?s)\r?\n?<!-- PYTHON_START -->.*?<!-- PYTHON_END -->\r?\n?', "`n"
    }
    'both' {
        Write-Host "  Language  : PYTHON + POWERSHELL" -ForegroundColor Green
    }
}

# ── Build project context block ────────────────────────────────────────────────
$today = Get-Date -Format 'yyyy-MM-dd'

$contextBlock = @"
<!-- PROJECT_CONTEXT_START -->
## Project Context

> Auto-generated by **Initialize Copilot Workspace** on $today.
> Re-run the task to update. Do not edit the PROJECT_CONTEXT markers manually.

| Field | Value |
|-------|-------|
| **Project** | $ProjectName |
| **Description** | $Description |
| **Problem Statement** | $ProblemStatement |
| **Initialized** | $today |
| **Branch** | $(git -C $repoRoot branch --show-current) |

<!-- PROJECT_CONTEXT_END -->
"@

# ── Inject or replace context block ───────────────────────────────────────────
if ($content -match '<!-- PROJECT_CONTEXT_START -->') {
    Write-Host "  Updating existing project context block..." -ForegroundColor Cyan
    $content = $content -replace '(?s)<!-- PROJECT_CONTEXT_START -->.*?<!-- PROJECT_CONTEXT_END -->', $contextBlock.Trim()
} else {
    Write-Host "  Injecting new project context block..." -ForegroundColor Cyan
    # Preserve any content that was above the first heading
    $content = $contextBlock + "`n`n" + $content.TrimStart()
}

# ── Write file (UTF-8 without BOM) ─────────────────────────────────────────────
Write-Host "  Writing updated instructions file..." -ForegroundColor Cyan
# New-Object UTF8Encoding($false) = UTF-8 without BOM — works in PS 5.1 and PS 7
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($instructionsPath, $content, $utf8NoBom)

# ── Stage ─────────────────────────────────────────────────────────────────────
Write-Host "  Staging .github/copilot-instructions.md..." -ForegroundColor Cyan
git -C $repoRoot add '.github/copilot-instructions.md'

# ── Commit (skipped on protected branches — AZDO requires PR approval) ─────────
if (-not $skipCommit) {
    $commitMsg = "chore: initialize copilot workspace for $ProjectName"
    Write-Host "  Committing: $commitMsg" -ForegroundColor Cyan
    git -C $repoRoot commit -m $commitMsg
}

# ── Scaffold directory structure ──────────────────────────────────────────────
Write-Host "  Scaffolding project directory structure..." -ForegroundColor Cyan
$scaffoldScript = Join-Path (Join-Path $repoRoot '.vscode') 'scaffold-structure.ps1'
if (Test-Path $scaffoldScript) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scaffoldScript -Language $Language -ProjectName $ProjectName
} else {
    Write-Host "  scaffold-structure.ps1 not found — skipping structure scaffold." -ForegroundColor Yellow
}

# ── Success summary ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ✅  Copilot workspace initialized" -ForegroundColor Green
Write-Host ""
Write-Host "  Project   : $ProjectName" -ForegroundColor White
Write-Host "  Branch    : $currentBranch" -ForegroundColor White
Write-Host "  IR        : $IsIR" -ForegroundColor White
Write-Host "  Language  : $Language" -ForegroundColor White
Write-Host "  File      : $instructionsPath" -ForegroundColor White

if ($skipCommit) {
    Write-Host ""
    Write-Host "  ⚠️  File staged but not committed (protected branch)" -ForegroundColor Yellow
    Write-Host "  Next steps:" -ForegroundColor Yellow
    Write-Host "    1. Create your working branch:" -ForegroundColor White
    Write-Host "       git checkout -b feature/<your-description>" -ForegroundColor Cyan
    Write-Host "    2. Commit the staged file:" -ForegroundColor White
    Write-Host "       git commit -m `"chore: initialize copilot workspace for $ProjectName`"" -ForegroundColor Cyan
} else {
    Write-Host "  Commit    : $(git -C $repoRoot log --oneline -1)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Copilot will now load project context and standing instructions automatically." -ForegroundColor DarkGray
}
Write-Host ""
