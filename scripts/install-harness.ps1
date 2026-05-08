<#!
Usage:
  .\scripts\install-harness.ps1 [-Directory <path>] [-Yes] [-Force] [-DryRun]
  .\scripts\install-harness.ps1 <path> [-Yes] [-Force] [-DryRun]

Apply the Harness v0 files and folders to a target project directory.
#>
[CmdletBinding()]
param(
    [Alias('d')]
    [string]$Directory,

    [Alias('y')]
    [switch]$Yes,

    [switch]$Force,

    [switch]$DryRun,

    [Alias('h')]
    [switch]$Help,

    [Parameter(Position = 0)]
    [string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
    @'
Usage: install-harness.ps1 [options] [path]

Apply the Harness v0 files and folders to a target project directory.

Options:
  -Directory, -d <path>  Target directory. Defaults to the current directory.
  -Yes, -y              Accept defaults and skip prompts.
  -Force                Overwrite existing files after backing them up.
  -DryRun               Show what would change without writing files.
  -Help, -h             Show this help.

Safety:
  The installer stops if AGENTS.md, docs/, or scripts/ already exist in the
  target directory. Pick an empty target or move those paths first.

Examples:
  .\scripts\install-harness.ps1 -Yes
  .\scripts\install-harness.ps1 -Directory C:\path\to\project -Yes
  .\scripts\install-harness.ps1 .\my-project -Force
  & ([ScriptBlock]::Create((Invoke-RestMethod "https://raw.githubusercontent.com/sonle0311/harness-experimental/main/scripts/install-harness.ps1"))) -Yes
'@ | Write-Output
}

function Write-Log {
    param([string]$Message)
    Write-Output $Message
}

function Fail {
    param([string]$Message)
    Write-Error "Error: $Message"
    exit 1
}

function Warn-Stop {
    param([string]$Message)
    Write-Error "Warning: $Message"
    exit 1
}

function Get-TargetFullPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Fail 'Target path cannot be empty'
    }

    $expanded = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $parent = Split-Path -Parent $expanded
    if (-not $parent) {
        $parent = (Get-Location).ProviderPath
    }

    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        Fail "Parent directory does not exist: $parent"
    }

    [System.IO.Path]::GetFullPath($expanded)
}

function Test-SamePath {
    param(
        [string]$Left,
        [string]$Right
    )

    $leftFull = [System.IO.Path]::GetFullPath($Left)
    $rightFull = [System.IO.Path]::GetFullPath($Right)
    [string]::Equals($leftFull, $rightFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function Write-SourceFile {
    param(
        [string]$Relative,
        [string]$Target
    )

    if ($script:SourceMode -eq 'local') {
        $source = Join-Path $script:SourceRoot $Relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            Fail "Source file missing: $source"
        }

        Copy-Item -LiteralPath $source -Destination $Target -Force
        return
    }

    $relativeUrl = $Relative -replace '\\', '/'
    $url = "$script:SourceBaseUrl/$relativeUrl"
    if ($url.StartsWith('file://', [System.StringComparison]::OrdinalIgnoreCase)) {
        $filePath = ([System.Uri]$url).LocalPath
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            Fail "Source file missing: $filePath"
        }

        Copy-Item -LiteralPath $filePath -Destination $Target -Force
        return
    }

    try {
        Invoke-WebRequest -Uri $url -OutFile $Target -UseBasicParsing
    }
    catch {
        Fail "Could not download $url"
    }
}

function Copy-HarnessFile {
    param([string]$Relative)

    $target = Join-Path $script:TargetDir $Relative

    if (Test-Path -LiteralPath $target) {
        if ($script:SourceMode -eq 'local') {
            $source = Join-Path $script:SourceRoot $Relative
            if ((Test-Path -LiteralPath $source -PathType Leaf) -and (Test-SamePath $source $target)) {
                Write-Log "skip     $Relative (source file)"
                $script:Skipped++
                return
            }
        }

        if ($script:Force) {
            if ($script:DryRun) {
                Write-Log "overwrite $Relative (backup first)"
            }
            else {
                $backup = Join-Path $script:BackupDir $Relative
                $backupParent = Split-Path -Parent $backup
                New-Item -ItemType Directory -Force -Path $backupParent | Out-Null
                Copy-Item -LiteralPath $target -Destination $backup -Force
                Write-SourceFile $Relative $target
                $displayBackup = $backup.Substring($script:TargetDir.Length).TrimStart('\', '/')
                Write-Log "updated $Relative (backup: $displayBackup)"
            }
            $script:Updated++
        }
        else {
            Write-Log "skip     $Relative (already exists)"
            $script:Skipped++
        }
        return
    }

    if ($script:DryRun) {
        Write-Log "create   $Relative"
    }
    else {
        $targetParent = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
        Write-SourceFile $Relative $target
        Write-Log "created  $Relative"
    }
    $script:Created++
}

function Check-ProtectedTargetPaths {
    $conflicts = @()

    if (Test-Path -LiteralPath (Join-Path $script:TargetDir 'AGENTS.md')) { $conflicts += 'AGENTS.md' }
    if (Test-Path -LiteralPath (Join-Path $script:TargetDir 'docs')) { $conflicts += 'docs/' }
    if (Test-Path -LiteralPath (Join-Path $script:TargetDir 'scripts')) { $conflicts += 'scripts/' }

    if ($conflicts.Count -gt 0) {
        $joined = $conflicts -join ', '
        Warn-Stop "target already contains protected Harness paths: $joined. Refusing to install so existing project instructions or docs are not mixed or overwritten. Use an empty target directory, or move those paths before running the installer."
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

if ($Directory -and $Path) {
    Fail 'Use either -Directory or a positional target path, not both'
}

$targetInput = if ($env:HARNESS_TARGET_DIR) { $env:HARNESS_TARGET_DIR } else { (Get-Location).ProviderPath }
if ($Directory) {
    $targetInput = $Directory
}
elseif ($Path) {
    $targetInput = $Path
}

if (-not $Yes -and [Environment]::UserInteractive) {
    $replyTarget = Read-Host "Install Harness v0 into [$targetInput]"
    if (-not [string]::IsNullOrWhiteSpace($replyTarget)) {
        $targetInput = $replyTarget
    }
}

$script:SourceRoot = ''
$script:SourceMode = 'remote'
$script:SourceBaseUrl = if ($env:HARNESS_SOURCE_BASE_URL) {
    $env:HARNESS_SOURCE_BASE_URL.TrimEnd('/', '\')
}
else {
    'https://raw.githubusercontent.com/sonle0311/harness-experimental/main'
}

if ($PSScriptRoot) {
    $candidateRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..') -ErrorAction SilentlyContinue
    if ($candidateRoot) {
        $candidatePath = $candidateRoot.ProviderPath
        if (
            (Test-Path -LiteralPath (Join-Path $candidatePath 'AGENTS.md') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $candidatePath 'docs\HARNESS.md') -PathType Leaf)
        ) {
            $script:SourceRoot = $candidatePath
            $script:SourceMode = 'local'
        }
    }
}

$script:TargetDir = Get-TargetFullPath $targetInput
$script:BackupDir = Join-Path $script:TargetDir (Join-Path '.harness-backup' (Get-Date -Format 'yyyyMMddHHmmss'))
$script:Force = [bool]$Force
$script:DryRun = [bool]$DryRun
$script:Created = 0
$script:Updated = 0
$script:Skipped = 0

if ($DryRun) {
    Write-Log 'Dry run: no files will be written.'
}
elseif (-not (Test-Path -LiteralPath $script:TargetDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $script:TargetDir | Out-Null
}

if (-not (Test-Path -LiteralPath $script:TargetDir -PathType Container)) {
    if ($DryRun) {
        Write-Log "Target directory would be created: $script:TargetDir"
    }
    else {
        Fail "Target directory could not be created: $script:TargetDir"
    }
}
else {
    Check-ProtectedTargetPaths
}

if ($script:SourceMode -eq 'local') {
    Write-Log "Harness source: $script:SourceRoot"
}
else {
    Write-Log "Harness source: $script:SourceBaseUrl"
}
Write-Log "Target project: $script:TargetDir"

$payload = @(
    'AGENTS.md',
    'README.md',
    'README.vi.md',
    'docs/ARCHITECTURE.md',
    'docs/FEATURE_INTAKE.md',
    'docs/GLOSSARY.md',
    'docs/HARNESS.md',
    'docs/HARNESS_BACKLOG.md',
    'docs/README.md',
    'docs/TEST_MATRIX.md',
    'docs/decisions/0001-harness-first-development.md',
    'docs/decisions/0002-post-spec-product-lifecycle.md',
    'docs/decisions/0003-generic-spec-intake-harness.md',
    'docs/decisions/README.md',
    'docs/product/README.md',
    'docs/stories/README.md',
    'docs/stories/backlog.md',
    'docs/templates/decision.md',
    'docs/templates/spec-intake.md',
    'docs/templates/story.md',
    'docs/templates/validation-report.md',
    'docs/templates/high-risk-story/design.md',
    'docs/templates/high-risk-story/execplan.md',
    'docs/templates/high-risk-story/overview.md',
    'docs/templates/high-risk-story/validation.md',
    'scripts/README.md'
)

foreach ($relative in $payload) {
    Copy-HarnessFile $relative
}

Write-Log ''
Write-Log "Done. Created: $script:Created, updated: $script:Updated, skipped: $script:Skipped."

if ($script:Skipped -gt 0 -and -not $Force) {
    Write-Log 'Existing files were left untouched. Re-run with -Force to overwrite with backups.'
}

if ($Force -and $script:Updated -gt 0 -and -not $DryRun) {
    Write-Log "Backups were written to: $script:BackupDir"
}
