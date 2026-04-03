#Requires -Version 5.1
<#
.SYNOPSIS
    Scaffolds a standard project directory structure based on the repo language profile.

.DESCRIPTION
    - Creates a standard directory structure for Python, PowerShell, or mixed repos
    - Writes stub files into every folder so git can track them
    - Idempotent — will not overwrite existing files, only creates what is missing
    - Auto-detects language from .github/copilot-instructions.md when -Language is omitted
    - Falls back to interactive Read-Host prompt if auto-detection fails
    - Stages and commits all new files in a single chore commit

.PARAMETER Language
    'python', 'powershell', or 'both'. Optional — auto-detected from copilot-instructions.md.

.PARAMETER ProjectName
    Used to derive the PowerShell module name. Optional — falls back to the repo folder name.

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .vscode/scaffold-structure.ps1

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .vscode/scaffold-structure.ps1 -Language python
#>

param(
    [string]$Language    = "",
    [string]$ProjectName = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve repo root via git ──────────────────────────────────────────────────
$repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim().Replace('/', [IO.Path]::DirectorySeparatorChar)
if (-not $repoRoot) {
    Write-Error "Unable to determine repository root. Ensure git is on PATH and you are inside a git repository."
    exit 1
}

$instructionsPath = Join-Path (Join-Path $repoRoot '.github') 'copilot-instructions.md'

# ── Auto-detect language from copilot-instructions.md ─────────────────────────
if (-not $Language) {
    if (Test-Path $instructionsPath) {
        $instrContent  = Get-Content $instructionsPath -Raw
        $hasPython     = $instrContent -match '<!-- PYTHON_START -->'
        $hasPowerShell = $instrContent -match '<!-- POWERSHELL_START -->'

        if ($hasPython -and $hasPowerShell) {
            $Language = 'both'
            Write-Host "  Auto-detected language: PYTHON + POWERSHELL" -ForegroundColor Cyan
        } elseif ($hasPython) {
            $Language = 'python'
            Write-Host "  Auto-detected language: PYTHON" -ForegroundColor Cyan
        } elseif ($hasPowerShell) {
            $Language = 'powershell'
            Write-Host "  Auto-detected language: POWERSHELL" -ForegroundColor Cyan
        }
    }
}

# ── Fall back to Read-Host if detection failed ─────────────────────────────────
if (-not $Language) {
    Write-Host "  Could not auto-detect language from copilot-instructions.md." -ForegroundColor Yellow
    do {
        $Language = (Read-Host "  Scripting language? (python/powershell/both)").Trim().ToLower()
        if ($Language -notin @('python', 'powershell', 'both')) {
            Write-Host "  Please enter 'python', 'powershell', or 'both'." -ForegroundColor Red
        }
    } while ($Language -notin @('python', 'powershell', 'both'))
}

# ── Derive module/project name ─────────────────────────────────────────────────
if (-not $ProjectName) {
    # Try to read from copilot-instructions.md project context block
    if (Test-Path $instructionsPath) {
        $match = Select-String -Path $instructionsPath -Pattern '\|\s\*\*Project\*\*\s+\|\s+(.+?)\s+\|'
        if ($match) {
            $ProjectName = $match.Matches[0].Groups[1].Value.Trim()
        }
    }
    # Fall back to repo folder name
    if (-not $ProjectName) {
        $ProjectName = Split-Path $repoRoot -Leaf
    }
}

# Derive a safe module name — PascalCase, alphanumeric only
$moduleName = ($ProjectName -replace '[^a-zA-Z0-9 ]', '') -replace '\s+(.)', { $_.Groups[1].Value.ToUpper() }
$moduleName = $moduleName.Substring(0,1).ToUpper() + $moduleName.Substring(1)

# ── Helper functions ───────────────────────────────────────────────────────────
function Get-Changelog {
    param([string]$Name)
    $today = Get-Date -Format 'yyyy-MM-dd'
    $lines = @(
        "# Changelog",
        "",
        "All notable changes to $Name will be documented in this file.",
        "",
        "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),",
        "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).",
        "",
        "## [Unreleased]",
        "",
        "## [0.1.0] - $today",
        "",
        "### Added",
        "- Initial project scaffold"
    )
    return ($lines -join "`n") + "`n"
}

function New-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "    + $(($Path).Replace($repoRoot, '').TrimStart('\/'))" -ForegroundColor Green
    } else {
        Write-Host "    ~ $(($Path).Replace($repoRoot, '').TrimStart('\/'))" -ForegroundColor DarkGray
    }
}

function New-StubFile {
    param(
        [string]$Path,
        [string]$Content
    )
    if (-not (Test-Path $Path)) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
        Write-Host "    + $(($Path).Replace($repoRoot, '').TrimStart('\/'))" -ForegroundColor Green
    } else {
        Write-Host "    ~ $(($Path).Replace($repoRoot, '').TrimStart('\/'))" -ForegroundColor DarkGray
    }
}

function Get-FolderReadme {
    param([string]$Title, [string]$Description)
    return "# $Title`n`n$Description`n"
}

# ── Python structure ───────────────────────────────────────────────────────────
function Build-PythonStructure {
    Write-Host ""
    Write-Host "  Building Python structure..." -ForegroundColor Cyan

    # src/
    $srcDir = Join-Path $repoRoot 'src'
    New-Directory $srcDir
    New-StubFile (Join-Path $srcDir '__init__.py') "# src package`n"
    New-StubFile (Join-Path $srcDir 'README.md') (Get-FolderReadme 'src' 'Core application source code. All primary modules and packages live here.')

    # config/
    $configDir = Join-Path $repoRoot 'config'
    New-Directory $configDir
    New-StubFile (Join-Path $configDir 'README.md') (Get-FolderReadme 'config' 'Configuration files — environment settings, YAML/JSON configs, and constants. No secrets should be committed here.')

    # docs/
    $docsDir = Join-Path $repoRoot 'docs'
    New-Directory $docsDir
    New-StubFile (Join-Path $docsDir 'README.md') (Get-FolderReadme 'docs' 'Project documentation — architecture decisions, runbooks, and reference material.')

    # logs/
    $logsDir = Join-Path $repoRoot 'logs'
    New-Directory $logsDir
    New-StubFile (Join-Path $logsDir '.gitkeep') ""
    New-StubFile (Join-Path $logsDir 'README.md') (Get-FolderReadme 'logs' 'Runtime log output. Log files are excluded via .gitignore — this folder is tracked for structure only.')

    # scripts/
    $scriptsDir = Join-Path $repoRoot 'scripts'
    New-Directory $scriptsDir
    New-StubFile (Join-Path $scriptsDir 'README.md') (Get-FolderReadme 'scripts' 'Utility and automation scripts — setup, deployment, data migration, and one-off tooling.')

    # tests/
    $testsDir = Join-Path $repoRoot 'tests'
    New-Directory $testsDir
    New-StubFile (Join-Path $testsDir '__init__.py') "# tests package`n"
    New-StubFile (Join-Path $testsDir 'README.md') (Get-FolderReadme 'tests' 'Unit and integration tests. Mirror the src/ structure where possible.')

    # Root files
    New-StubFile (Join-Path $repoRoot 'requirements.txt') "# Production dependencies — pin exact versions`n# Example: requests==2.31.0`n"
    New-StubFile (Join-Path $repoRoot 'requirements-dev.txt') "# Development-only dependencies`n# Example: pytest==7.4.0`n"
    New-StubFile (Join-Path $repoRoot '.gitignore') @"
# Python
__pycache__/
*.py[cod]
*.pyo
*.egg-info/
dist/
build/
.eggs/

# Virtual environments
.venv/
venv/
env/

# Logs
logs/*.log

# Environment files
.env
.env.*

# VS Code
.vscode/settings.json
"@

    # Example stub -- demonstrates the required versioned header standard
    $today = Get-Date -Format 'yyyyMMdd'
    $pyHeader = "# Example Module`n# Example Module v1.0`n# $today`n#`n# Starter module demonstrating the required file versioning header standard.`n# Replace this description with a summary of what the module does.`n#`n# Functions:`n#   example_function()     -- Placeholder, replace with real functions`n#`n# Version History:`n# - v1.0: Initial scaffold`n"
    $pyBody   = "`nimport logging`n`nlogger = logging.getLogger(__name__)`n`n`ndef example_function() -> None:`n    `"Placeholder function -- replace with real implementation.`"`n    logger.info('example_function called')`n"
    New-StubFile (Join-Path $srcDir 'example_module.py') ($pyHeader + $pyBody)

    New-StubFile (Join-Path $repoRoot 'CHANGELOG.md') (Get-Changelog $ProjectName)
}


# ── PowerShell structure ───────────────────────────────────────────────────────
function Build-PowerShellStructure {
    Write-Host ""
    Write-Host "  Building PowerShell structure..." -ForegroundColor Cyan

    # Public/
    $publicDir = Join-Path $repoRoot 'Public'
    New-Directory $publicDir
    New-StubFile (Join-Path $publicDir 'README.md') (Get-FolderReadme 'Public' 'Exported functions — cmdlets that are part of the public module API. One function per file, named identically to the function.')

    # Private/
    $privateDir = Join-Path $repoRoot 'Private'
    New-Directory $privateDir
    New-StubFile (Join-Path $privateDir 'README.md') (Get-FolderReadme 'Private' 'Internal helper functions — not exported, not part of the public API. One function per file.')

    # Tests/
    $testsDir = Join-Path $repoRoot 'Tests'
    New-Directory $testsDir
    New-StubFile (Join-Path $testsDir 'README.md') (Get-FolderReadme 'Tests' 'Pester test files. Mirror the Public/ and Private/ structure. Naming convention: FunctionName.Tests.ps1')

    # Config/
    $configDir = Join-Path $repoRoot 'Config'
    New-Directory $configDir
    New-StubFile (Join-Path $configDir 'README.md') (Get-FolderReadme 'Config' 'Configuration data files — JSON, PSD1 data files, and environment-specific settings. No secrets committed here.')

    # Docs/
    $docsDir = Join-Path $repoRoot 'Docs'
    New-Directory $docsDir
    New-StubFile (Join-Path $docsDir 'README.md') (Get-FolderReadme 'Docs' 'Module documentation — usage guides, architecture notes, and generated help content.')

    # Scripts/
    $scriptsDir = Join-Path $repoRoot 'Scripts'
    New-Directory $scriptsDir
    New-StubFile (Join-Path $scriptsDir 'README.md') (Get-FolderReadme 'Scripts' 'Standalone utility scripts — not part of the module. Setup, deployment, and operational tooling.')

    # Module manifest stub
    $manifestPath = Join-Path $repoRoot "$moduleName.psd1"
    New-StubFile $manifestPath @"
@{
    ModuleVersion     = '0.1.0'
    GUID              = '$([guid]::NewGuid())'
    Author            = ''
    Description       = ''
    PowerShellVersion = '5.1'
    RootModule        = '$moduleName.psm1'
    FunctionsToExport = @()
    CmdletsToExport   = @()
    AliasesToExport   = @()
}
"@

    # Module root stub
    $psmPath = Join-Path $repoRoot "$moduleName.psm1"
    New-StubFile $psmPath @"
# $moduleName.psm1
# Dot-source all public and private functions

`$Public  = Get-ChildItem -Path (Join-Path `$PSScriptRoot 'Public')  -Filter '*.ps1' -ErrorAction SilentlyContinue
`$Private = Get-ChildItem -Path (Join-Path `$PSScriptRoot 'Private') -Filter '*.ps1' -ErrorAction SilentlyContinue

foreach (`$function in @(`$Public + `$Private)) {
    try   { . `$function.FullName }
    catch { Write-Error "Failed to import `$(`$function.FullName): `$_" }
}

Export-ModuleMember -Function `$Public.BaseName
"@

    # Root .gitignore
    New-StubFile (Join-Path $repoRoot '.gitignore') @"
# PowerShell
*.pssproj
*.suo

# Build output
Release/
Output/

# Pester results
TestResults/
*.xml

# VS Code
.vscode/settings.json
"@

    # Example stub -- demonstrates the required versioned header standard
    $today = Get-Date -Format 'yyyyMMdd'
    $psStub = "function Get-ExampleItem {`n<#`n.SYNOPSIS`n    Placeholder function demonstrating the required versioned header standard.`n`n.DESCRIPTION`n    Replace this description with a summary of what the function does.`n    This file lives in Public/ because it is part of the exported module API.`n`n.VERSION`n    v1.0`n`n.DATE`n    $today`n`n.PARAMETER Name`n    The name of the item to retrieve.`n`n.EXAMPLE`n    Get-ExampleItem -Name 'sample'`n`n.NOTES`n    Version History:`n    - v1.0: Initial scaffold`n#>`n    [CmdletBinding()]`n    param(`n        [Parameter(Mandatory)][string]`$Name`n    )`n    Write-Verbose `"Get-ExampleItem called with Name='`$Name'`"`n    # TODO: Replace with real implementation`n}`n"
    New-StubFile (Join-Path $publicDir 'Get-ExampleItem.ps1') $psStub

    New-StubFile (Join-Path $repoRoot 'CHANGELOG.md') (Get-Changelog $ProjectName)
}


# ── Execute based on language ──────────────────────────────────────────────────
Write-Host ""
Write-Host "  Project   : $ProjectName" -ForegroundColor White
Write-Host "  Language  : $Language" -ForegroundColor White
if ($Language -in @('powershell', 'both')) {
    Write-Host "  Module    : $moduleName" -ForegroundColor White
}
Write-Host ""

switch ($Language) {
    'python'     { Build-PythonStructure }
    'powershell' { Build-PowerShellStructure }
    'both'       { Build-PythonStructure; Build-PowerShellStructure }
}

# ── Stage and commit ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Staging new files..." -ForegroundColor Cyan
git -C $repoRoot add --all

$stagedCount = (git -C $repoRoot diff --cached --name-only | Measure-Object -Line).Lines
if ($stagedCount -gt 0) {
    $commitMsg = "chore: scaffold $Language project structure"
    Write-Host "  Committing $stagedCount file(s): $commitMsg" -ForegroundColor Cyan
    git -C $repoRoot commit -m $commitMsg
    Write-Host ""
    Write-Host "  ✅  Structure scaffolded and committed" -ForegroundColor Green
    Write-Host "  Commit : $(git -C $repoRoot log --oneline -1)" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "  ✅  Structure already up to date — nothing new to commit" -ForegroundColor Green
}

Write-Host ""
