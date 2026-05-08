# US-001 Install Harness Into A Project

## Status

implemented

## Lane

normal

## Product Contract

A user can apply the Harness v0 operating files and folder structure to a
target project directory without introducing an application stack, package
scripts, CI, tests, or product implementation.

## Relevant Product Docs

- `README.md`
- `docs/HARNESS.md`
- `docs/FEATURE_INTAKE.md`
- `scripts/README.md`

## Acceptance Criteria

- The installer defaults to the current directory when no target is provided.
- The installer accepts a specific target path through a command-line option or
  positional argument.
- If `AGENTS.md`, `docs/`, or `scripts/` already exists in the target, the
  installer shows a warning and stops before writing files.
- Existing non-protected files are not overwritten by default.
- Forced overwrites create a timestamped backup before replacing non-protected
  files.
- A dry-run mode reports planned file operations without writing files.
- The installer copies only Harness v0 operating files and does not scaffold
  application code, package scripts, CI, or validation commands.
- The installer script and this installer story are not copied into target
  projects.
- Windows users can install from PowerShell without requiring Bash.
- Target projects receive both English and Vietnamese README files.

## Design Notes

- Commands: `scripts/install-harness.sh [--directory path] [--yes] [--force] [--dry-run]`
- Windows commands: `scripts/install-harness.ps1 [-Directory path] [-Yes] [-Force] [-DryRun]`
- Remote install: `curl -fsSL "https://raw.githubusercontent.com/sonle0311/harness-experimental/main/scripts/install-harness.sh?$(date +%s)" | bash -s -- --yes`
- Windows remote install: `& ([ScriptBlock]::Create((Invoke-RestMethod "https://raw.githubusercontent.com/sonle0311/harness-experimental/main/scripts/install-harness.ps1?$(Get-Date -UFormat %s)"))) -Yes`
- Queries: none.
- API: none.
- Tables: none.
- Domain rules: preserve Harness v0 as a generic, spec-intake-first operating
  framework.
- UI surfaces: terminal prompts and summary output only.

## Validation

| Layer | Expected proof |
| --- | --- |
| Unit | Shell syntax check for `scripts/install-harness.sh`. |
| Integration | Dry-run into a temporary target reports expected file creation. |
| E2E | Install into a temporary target creates the harness file structure. |
| Platform | POSIX shell execution on macOS/Linux/Git Bash and PowerShell execution on Windows. |
| Release | Not applicable until packaging exists. |

## Harness Delta

Adds the first real harness automation script while keeping installer internals
out of target projects and preserving the Harness v0 rule that application
implementation surfaces are not scaffolded.

## Evidence

- `bash -n scripts/install-harness.sh`
- `scripts/install-harness.sh --directory "$LOCAL_TARGET" --yes`
- `scripts/install-harness.sh --directory "$README_TARGET" --yes` after adding a
  custom `README.md` in the target
- `scripts/install-harness.sh --directory "$AGENTS_CONFLICT" --yes`
- `scripts/install-harness.sh --directory "$DOCS_CONFLICT" --yes`
- `scripts/install-harness.sh --directory "$SCRIPTS_CONFLICT" --yes --force`
- `HARNESS_SOURCE_BASE_URL="file:///Users/themrb/Documents/personal/harness-experimental" bash -s -- --directory "$REMOTE_TARGET" --yes < scripts/install-harness.sh`
- `curl -fsSL "file:///Users/themrb/Documents/personal/harness-experimental/scripts/install-harness.sh" | HARNESS_SOURCE_BASE_URL="file:///Users/themrb/Documents/personal/harness-experimental" bash -s -- --directory "$TARGET" --yes`
- `HARNESS_SOURCE_BASE_URL="file:///Users/themrb/Documents/personal/harness-experimental" bash -s -- --directory "$DRY_TARGET" --yes --dry-run < scripts/install-harness.sh`
- `[ScriptBlock]::Create((Get-Content -Raw scripts\install-harness.ps1))`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-harness.ps1 -Directory $LOCAL_TARGET -Yes -DryRun`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-harness.ps1 -Directory $LOCAL_TARGET -Yes`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-harness.ps1 -Directory $AGENTS_CONFLICT -Yes`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-harness.ps1 -Directory $README_TARGET -Yes` after adding a custom `README.md` in the target
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-harness.ps1 -Directory $README_FORCE_TARGET -Yes -Force` after adding a custom `README.md` in the target
- `HARNESS_SOURCE_BASE_URL="file:///C:/path/to/harness-experimental"; & ([ScriptBlock]::Create((Get-Content -Raw .\scripts\install-harness.ps1))) -Directory $REMOTE_TARGET -Yes`

Validated behaviors: dry-run writes no files, real install creates the harness
structure, existing `README.md` is left untouched by default, targets containing
`AGENTS.md`, `docs/`, or `scripts/` stop with a warning before writing files,
protected-path conflicts stop even when `--force` is provided, remote-source
mode works when the script is piped into Bash, and target projects do not
receive `scripts/install-harness.sh`, `scripts/install-harness.ps1`, or this
installer story.
