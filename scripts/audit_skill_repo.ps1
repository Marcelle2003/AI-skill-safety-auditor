#Requires -Version 5.1
<#
.SYNOPSIS
  Heuristic static scan of a cloned skill/repo directory (read-only).

.DESCRIPTION
  Use after git clone, before running installers. Output is for triage only;
  false positives and false negatives are possible.

.PARAMETER Path
  Absolute or relative path to the repository root.

.PARAMETER MaxMatchesPerRule
  Stop reporting hits per rule after this many (keeps output small).

.EXAMPLE
  .\audit_skill_repo.ps1 -Path C:\temp\claude-ads
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [int]$MaxMatchesPerRule = 20
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param([string]$P)
    $item = Get-Item -LiteralPath $P -ErrorAction Stop
    if (-not $item.PSIsContainer) {
        throw "Path is not a directory: $P"
    }
    return $item.FullName
}

$root = Resolve-RepoRoot $Path

Write-Host "=== skill-safety-auditor: audit_skill_repo.ps1 ===" -ForegroundColor Cyan
Write-Host "Root: $root"
Write-Host ""

# --- .gitmodules ---
$gitmodules = Join-Path $root ".gitmodules"
if (Test-Path -LiteralPath $gitmodules) {
    Write-Host '[SUBMODULES] .gitmodules present — review URLs before recursive clone:' -ForegroundColor Yellow
    Get-Content -LiteralPath $gitmodules | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
}
else {
    Write-Host '[SUBMODULES] none'
    Write-Host ""
}

# --- CI workflows ---
$wfDir = Join-Path $root ".github\workflows"
if (Test-Path -LiteralPath $wfDir) {
    Write-Host '[CI] .github/workflows:' -ForegroundColor Yellow
    Get-ChildItem -LiteralPath $wfDir -File -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "  $($_.Name)"
    }
    Write-Host ""
}
else {
    Write-Host '[CI] no .github/workflows'
    Write-Host ""
}

# --- Other common CI files ---
$ciNames = @(
    ".gitlab-ci.yml",
    "azure-pipelines.yml",
    ".circleci\config.yml",
    "buildkite.yml"
)
$ciFound = @()
foreach ($n in $ciNames) {
    $p = Join-Path $root $n
    if (Test-Path -LiteralPath $p) { $ciFound += $n }
}
if ($ciFound.Count -gt 0) {
    Write-Host ('[CI] additional configs: ' + ($ciFound -join ', ')) -ForegroundColor Yellow
    Write-Host ""
}

# --- File inventory (counts by extension) ---
$excludeDirNames = @(
    "node_modules", ".git", "__pycache__", "dist", "build", "target",
    ".venv", "venv", ".tox"
)
$allFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
    $dir = $_.DirectoryName
    $skip = $false
    foreach ($ex in $excludeDirNames) {
        if ($dir -like "*\$ex\*" -or $dir -like "*\$ex") { $skip = $true; break }
    }
    -not $skip
}

$extGroups = $allFiles | Group-Object { $_.Extension.ToLowerInvariant() } | Sort-Object Count -Descending
Write-Host '[INVENTORY] file counts by extension (top 15):'
$extGroups | Select-Object -First 15 | ForEach-Object {
    Write-Host ("  {0,-8} {1}" -f $(if ($_.Name) { $_.Name } else { "(noext)" }), $_.Count)
}
$binExt = @(".exe", ".dll", ".jar", ".msi", ".scr", ".com", ".pif", ".app")
$binCount = ($allFiles | Where-Object { $binExt -contains $_.Extension.ToLowerInvariant() }).Count
if ($binCount -gt 0) {
    Write-Host ('[INVENTORY] binary-like files: ' + $binCount + ' (review manually)') -ForegroundColor Yellow
}
Write-Host ""

# --- Pattern scan ---
$scanExtensions = @(
    ".ps1", ".psm1", ".sh", ".bash", ".zsh", ".bat", ".cmd",
    ".py", ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx",
    ".json", ".yml", ".yaml", ".toml", ".md", ".txt", ".gradle", ".rb", ".php"
)

$rules = @(
    @{ Name = "pipe_to_shell"; Pattern = '(?i)(curl|wget)[^\n]*\|\s*(bash|sh)' }
    @{ Name = "powershell_iex"; Pattern = '(?i)(irm|iwr)[^\n]*\|\s*iex|Invoke-Expression\b' }
    @{ Name = "base64_decode"; Pattern = '(?i)FromBase64String|base64\s+(-d|--decode)' }
    @{ Name = "token_exfil_hint"; Pattern = '(?i)GITHUB_TOKEN|AWS_SECRET|Authorization:\s*Bearer' }
    @{ Name = "download_exec"; Pattern = '(?i)DownloadString|DownloadFile|Invoke-WebRequest.*-OutFile|Start-BitsTransfer' }
    @{ Name = "ssh_paths"; Pattern = '(?i)(~\/\.ssh|\.ssh\/id_|\\\.ssh\\|USERPROFILE.*\.ssh)' }
    @{ Name = "wallet_browser_profiles"; Pattern = '(?i)(metamask|exodus|electrum|chrome\\User Data|Firefox\\Profiles)' }
    @{ Name = "defender_tamper"; Pattern = '(?i)Add-MpPreference|DisableRealtimeMonitoring|Set-MpPreference' }
    @{ Name = "persistence"; Pattern = '(?i)schtasks|Register-ScheduledTask|reg\s+add.*\\Run|Startup\\\\|LaunchAgents' }
    @{ Name = "clipboard_env_steal"; Pattern = '(?i)Get-Clipboard|pbpaste|xclip|os\.environ\[|getenv\s*\(' }
)

$scanFiles = $allFiles | Where-Object { $scanExtensions -contains $_.Extension.ToLowerInvariant() }

Write-Host ('[PATTERN SCAN] files: ' + $scanFiles.Count + ' (extensions filtered; node_modules/.git skipped)')
Write-Host ""

foreach ($rule in $rules) {
    $hits = @()
    foreach ($f in $scanFiles) {
        if ($hits.Count -ge $MaxMatchesPerRule) { break }
        try {
            $m = Select-String -LiteralPath $f.FullName -Pattern $rule.Pattern -AllMatches -ErrorAction SilentlyContinue
            if ($m) {
                foreach ($line in $m) {
                    $hits += [PSCustomObject]@{
                        Path = $f.FullName.Substring($root.Length).TrimStart('\')
                        Line = $line.LineNumber
                        Text = $line.Line.Trim()
                    }
                    if ($hits.Count -ge $MaxMatchesPerRule) { break }
                }
            }
        }
        catch {
            # binary or locked; skip
        }
    }
    if ($hits.Count -gt 0) {
        Write-Host ('[HIT] ' + $rule.Name + ' (' + $hits.Count + ' matches, cap ' + $MaxMatchesPerRule + '):') -ForegroundColor Yellow
        $hits | ForEach-Object { Write-Host ("  {0}:{1}: {2}" -f $_.Path, $_.Line, $_.Text.Substring(0, [Math]::Min(120, $_.Text.Length))) }
        Write-Host ""
    }
}

Write-Host '[DONE] Review all [HIT] sections; confirm CI workflows manually.' -ForegroundColor Green
