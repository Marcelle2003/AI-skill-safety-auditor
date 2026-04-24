#!/usr/bin/env bash
# Heuristic static scan of a cloned skill/repo directory (read-only).
# Usage: ./audit_skill_repo.sh /path/to/repo
# Optional: MAX_MATCHES_PER_RULE=50 ./audit_skill_repo.sh /path/to/repo

set -euo pipefail

MAX_MATCHES_PER_RULE="${MAX_MATCHES_PER_RULE:-20}"
ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "Usage: $0 <repo-root>" >&2
  exit 2
fi

ROOT="$(cd "$ROOT" && pwd)"

echo "=== skill-safety-auditor: audit_skill_repo.sh ==="
echo "Root: $ROOT"
echo ""

if [[ -f "$ROOT/.gitmodules" ]]; then
  echo "[SUBMODULES] .gitmodules present — review URLs before recursive clone:"
  sed 's/^/  /' "$ROOT/.gitmodules"
  echo ""
else
  echo "[SUBMODULES] none"
  echo ""
fi

if [[ -d "$ROOT/.github/workflows" ]]; then
  echo "[CI] .github/workflows:"
  find "$ROOT/.github/workflows" -maxdepth 1 -type f 2>/dev/null | while read -r f; do
    echo "  $(basename "$f")"
  done
  echo ""
else
  echo "[CI] no .github/workflows"
  echo ""
fi

for f in .gitlab-ci.yml azure-pipelines.yml buildkite.yml; do
  [[ -f "$ROOT/$f" ]] && echo "[CI] additional: $f"
done
[[ -f "$ROOT/.circleci/config.yml" ]] && echo "[CI] additional: .circleci/config.yml"
echo ""

echo "[INVENTORY] file counts by extension (top 15):"
find "$ROOT" -type f \
  ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/__pycache__/*' \
  ! -path '*/.venv/*' ! -path '*/venv/*' ! -path '*/dist/*' ! -path '*/build/*' \
  2>/dev/null \
  | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -15 \
  | awk '{ext=$2; if(ext=="") ext="(noext)"; else ext="." ext; printf "  %-12s %s\n", ext, $1}'
echo ""

# Build find args for scannable text files
match_file() {
  local base="${1##*/}"
  case "$base" in
    *.ps1|*.psm1|*.sh|*.bash|*.zsh|*.bat|*.cmd) return 0 ;;
    *.py|*.js|*.mjs|*.cjs|*.ts|*.tsx|*.jsx) return 0 ;;
    *.json|*.yml|*.yaml|*.toml|*.md|*.txt|*.gradle|*.rb|*.php) return 0 ;;
    *) return 1 ;;
  esac
}

scan_rule() {
  local rule_name="$1"
  local pattern="$2"
  local count=0
  local printed_header=0

  while IFS= read -r -d '' file; do
    match_file "$file" || continue
    if ! grep -E -q "$pattern" "$file" 2>/dev/null; then
      continue
    fi
    if [[ $printed_header -eq 0 ]]; then
      echo "[HIT] $rule_name (cap $MAX_MATCHES_PER_RULE):"
      printed_header=1
    fi
    while IFS= read -r line; do
      rel="${file#$ROOT/}"
      echo "  $rel:$line"
      count=$((count + 1))
      if [[ $count -ge $MAX_MATCHES_PER_RULE ]]; then
        echo ""
        return
      fi
    done < <(grep -E -n "$pattern" "$file" 2>/dev/null)
  done < <(find "$ROOT" -type f \
    ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/__pycache__/*' \
    ! -path '*/.venv/*' ! -path '*/venv/*' -print0 2>/dev/null)

  if [[ $printed_header -eq 1 ]]; then
    echo ""
  fi
}

scan_rule "pipe_to_shell" '(curl|wget)[^|]*\|(bash|sh)'
scan_rule "powershell_iex" '(irm|iwr)[^|]*\|[[:space:]]*iex|Invoke-Expression'
scan_rule "base64_decode" 'FromBase64String|base64([[:space:]]+)(-d|--decode)'
scan_rule "token_exfil_hint" 'GITHUB_TOKEN|AWS_SECRET|Authorization:[[:space:]]*Bearer'
scan_rule "download_exec" 'DownloadString|DownloadFile|Invoke-WebRequest.*-OutFile|Start-BitsTransfer'
scan_rule "ssh_paths" '~/.ssh|\.ssh/id_|/\.ssh/|USERPROFILE.*\.ssh'
scan_rule "wallet_browser_profiles" '[Mm]etamask|[Ee]xodus|[Ee]lectrum|Chrome/User Data|Firefox/Profiles'
scan_rule "defender_tamper" 'Add-MpPreference|DisableRealtimeMonitoring|Set-MpPreference'
scan_rule "persistence" 'schtasks|Register-ScheduledTask|reg[[:space:]]+add.*Run|LaunchAgents'
scan_rule "clipboard_env_steal" 'Get-Clipboard|pbpaste|xclip|os\.environ\[|getenv[[:space:]]*\('

echo "[DONE] Review all [HIT] sections; confirm CI workflows manually."
