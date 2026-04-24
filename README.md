# AI-skill-safety-auditor

## Skill Safety Auditor

Agent skill for auditing third-party Cursor/Claude skills before install: remote pre-check, clone, local scan (including optional `scripts/audit_skill_repo.*`), and safe install steps. See `SKILL.md` for the full workflow and `POLICY.md` for severity rules.

### Pick how you use Claude (important)

| You use… | What to do | Skills folder on disk? |
|----------|------------|-------------------------|
| **Claude web app** (browser) — upload a skill | Use **ZIP → Downloads** below | **No** — cloud upload only |
| **Claude Code** (CLI / desktop coding) | Use **Install → `~/.claude/skills`** below | **Yes** |
| **Cursor** | Use **Install for Cursor** below | **Yes** (`~/.cursor/skills`) |

`~/.claude/skills` is for **Claude Code**, not for the browser app. Teammates on **claude.ai** should use the **ZIP** flow and upload that file in the product UI.

---

## ZIP for Claude web app (upload) — Windows

Creates `skill-safety-auditor-for-claude-app.zip` in your **Downloads** folder. The archive root contains `SKILL.md`, `POLICY.md`, `README.md`, and `scripts/` (what Claude expects for a skill ZIP).

**With Git** (paste in PowerShell):

```powershell
$t="$env:TEMP\ai-skill-safety-build"; Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue; git clone --depth 1 https://github.com/Marcelle2003/AI-skill-safety-auditor.git $t; $out=Join-Path $env:USERPROFILE "Downloads\skill-safety-auditor-for-claude-app.zip"; Remove-Item -Force $out -ErrorAction SilentlyContinue; Compress-Archive -Path (Join-Path $t '*') -DestinationPath $out; Remove-Item -Recurse -Force $t; Write-Host "Wrote: $out"
```

**No Git** (PowerShell only):

```powershell
$e="$env:TEMP\ai-skill-safety-x"; $z="$env:TEMP\ai-skill-safety-src.zip"; Remove-Item -Recurse -Force $e -ErrorAction SilentlyContinue; Remove-Item -Force $z -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "https://github.com/Marcelle2003/AI-skill-safety-auditor/archive/refs/heads/main.zip" -OutFile $z -UseBasicParsing; Expand-Archive -Path $z -DestinationPath $e -Force; $inner=Join-Path $e "AI-skill-safety-auditor-main"; $out=Join-Path $env:USERPROFILE "Downloads\skill-safety-auditor-for-claude-app.zip"; Remove-Item -Force $out -ErrorAction SilentlyContinue; Compress-Archive -Path (Join-Path $inner '*') -DestinationPath $out; Remove-Item -Recurse -Force $z,$e; Write-Host "Wrote: $out"
```

Then in the **Claude web app**, use **Upload skill** (or your team’s equivalent) and choose that ZIP from Downloads.

### ZIP — macOS / Linux (Downloads)

From a clone of this repo at `./AI-skill-safety-auditor`:

```bash
cd AI-skill-safety-auditor && zip -r ~/Downloads/skill-safety-auditor-for-claude-app.zip SKILL.md POLICY.md README.md scripts/
```

---

## One-line install (Windows + Claude Code only)

Paste into **PowerShell** or **Windows Terminal** (requires [Git for Windows](https://git-scm.com/download/win); free install, defaults are fine):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" | Out-Null; git clone https://github.com/Marcelle2003/AI-skill-safety-auditor.git "$env:USERPROFILE\.claude\skills\skill-safety-auditor"
```

If the folder already exists, remove it first, then run the line again:

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\skills\skill-safety-auditor" -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" | Out-Null; git clone https://github.com/Marcelle2003/AI-skill-safety-auditor.git "$env:USERPROFILE\.claude\skills\skill-safety-auditor"
```

**No Git?** One-liner using only PowerShell (downloads the repo into the **Claude Code** skills folder):

```powershell
$s="$env:USERPROFILE\.claude\skills\skill-safety-auditor"; $p=Split-Path $s; New-Item -ItemType Directory -Force -Path $p | Out-Null; Remove-Item -Recurse -Force $s -ErrorAction SilentlyContinue; $z="$env:TEMP\ai-skill-safety.zip"; Invoke-WebRequest -Uri "https://github.com/Marcelle2003/AI-skill-safety-auditor/archive/refs/heads/main.zip" -OutFile $z -UseBasicParsing; Expand-Archive -Path $z -DestinationPath "$env:TEMP\ai-skill-safety-x" -Force; Move-Item -Path (Join-Path "$env:TEMP\ai-skill-safety-x" "AI-skill-safety-auditor-main") -Destination $s -Force; Remove-Item $z -Force; Remove-Item "$env:TEMP\ai-skill-safety-x" -Recurse -Force
```

Then restart **Claude Code** or open a new session so it picks up `~/.claude/skills/skill-safety-auditor/SKILL.md`.

## Install for Cursor

Personal (all projects):

1. Ensure the skills directory exists:
   - **Windows:** `%USERPROFILE%\.cursor\skills`
   - **macOS / Linux:** `~/.cursor/skills`
2. Copy this entire folder so the path is:
   - **Windows:** `%USERPROFILE%\.cursor\skills\skill-safety-auditor\`
   - **macOS / Linux:** `~/.cursor/skills/skill-safety-auditor/`
3. Confirm `SKILL.md` is at `skill-safety-auditor/SKILL.md`.
4. **Optional (Unix):** make the shell scanner executable:
   ```bash
   chmod +x ~/.cursor/skills/skill-safety-auditor/scripts/audit_skill_repo.sh
   ```

Project-only (this repo’s teammates):

1. Copy the folder to: `<your-repo>/.cursor/skills/skill-safety-auditor/`
2. Commit if you want the skill shared via git.

Cursor loads personal skills from `~/.cursor/skills/` and project skills from `.cursor/skills/`. After copying, start a new chat or reload the window if skills do not appear.

## Install for Claude Code (folder on disk)

Personal:

1. Ensure the skills directory exists:
   - **Windows:** `%USERPROFILE%\.claude\skills`
   - **macOS / Linux:** `~/.claude/skills`
2. Copy this entire folder so the path is:
   - **Windows:** `%USERPROFILE%\.claude\skills\skill-safety-auditor\`
   - **macOS / Linux:** `~/.claude/skills/skill-safety-auditor/`
3. Confirm `SKILL.md` is at `skill-safety-auditor/SKILL.md`.
4. **Optional (Unix):**
   ```bash
   chmod +x ~/.claude/skills/skill-safety-auditor/scripts/audit_skill_repo.sh
   ```

Project-only:

1. Copy the folder to: `<your-repo>/.claude/skills/skill-safety-auditor/`

Use the same skill content in both Cursor and Claude Code if you want identical behavior in each tool; maintain two copies (or sync from one git repo) under the respective `skills` roots above. Use the **ZIP** section above for **Claude web app** teammates instead.

## Quick copy examples

**Windows (PowerShell)** — adjust the source path to where you cloned or unzipped this skill:

```powershell
$dest = Join-Path $env:USERPROFILE ".cursor\skills\skill-safety-auditor"
New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
Copy-Item -Path "C:\path\to\skill-safety-auditor" -Destination $dest -Recurse -Force
```

Repeat with `.claude\skills\skill-safety-auditor` for Claude Code.

**macOS / Linux:**

```bash
mkdir -p ~/.cursor/skills ~/.claude/skills
cp -R /path/to/skill-safety-auditor ~/.cursor/skills/
cp -R /path/to/skill-safety-auditor ~/.claude/skills/
chmod +x ~/.cursor/skills/skill-safety-auditor/scripts/audit_skill_repo.sh
chmod +x ~/.claude/skills/skill-safety-auditor/scripts/audit_skill_repo.sh
```

## Using the local scanner (optional)

After you clone a third-party repo into a temp directory:

- **Windows:**  
  `powershell -NoProfile -File "%USERPROFILE%\.cursor\skills\skill-safety-auditor\scripts\audit_skill_repo.ps1" -Path "C:\temp\reviewed-repo"`
- **macOS / Linux:**  
  `~/.cursor/skills/skill-safety-auditor/scripts/audit_skill_repo.sh /tmp/reviewed-repo`

Interpretation notes are in `SKILL.md` (documentation files may match patterns harmlessly).

## Uninstall

- **Claude Code / Cursor:** delete the `skill-safety-auditor` folder from the relevant `skills` directory.
- **Claude web app:** remove the skill in the app UI; delete the ZIP from Downloads if you like.
