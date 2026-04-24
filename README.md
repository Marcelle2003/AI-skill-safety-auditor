# AI-skill-safety-auditor

## Skill Safety Auditor

Agent skill for auditing third-party Cursor/Claude skills before install: remote pre-check, clone, local scan (including optional `scripts/audit_skill_repo.*`), and safe install steps. See `SKILL.md` for the full workflow and `POLICY.md` for severity rules.

### One-line install (Windows + Claude Code)

Paste into **PowerShell** or **Windows Terminal** (requires [Git for Windows](https://git-scm.com/download/win); free install, defaults are fine):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" | Out-Null; git clone https://github.com/Marcelle2003/AI-skill-safety-auditor.git "$env:USERPROFILE\.claude\skills\skill-safety-auditor"
```

If the folder already exists, remove it first, then run the line again:

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\skills\skill-safety-auditor" -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills" | Out-Null; git clone https://github.com/Marcelle2003/AI-skill-safety-auditor.git "$env:USERPROFILE\.claude\skills\skill-safety-auditor"
```

**No Git?** One-liner using only PowerShell (downloads the repo zip):

```powershell
$s="$env:USERPROFILE\.claude\skills\skill-safety-auditor"; $p=Split-Path $s; New-Item -ItemType Directory -Force -Path $p | Out-Null; Remove-Item -Recurse -Force $s -ErrorAction SilentlyContinue; $z="$env:TEMP\ai-skill-safety.zip"; Invoke-WebRequest -Uri "https://github.com/Marcelle2003/AI-skill-safety-auditor/archive/refs/heads/main.zip" -OutFile $z -UseBasicParsing; Expand-Archive -Path $z -DestinationPath "$env:TEMP\ai-skill-safety-x" -Force; Move-Item -Path (Join-Path "$env:TEMP\ai-skill-safety-x" "AI-skill-safety-auditor-main") -Destination $s -Force; Remove-Item $z -Force; Remove-Item "$env:TEMP\ai-skill-safety-x" -Recurse -Force
```

Then restart Claude Code or open a new session so it picks up `~/.claude/skills/skill-safety-auditor/SKILL.md`.

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

## Install for Claude Code

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

Use the same skill content in both Cursor and Claude Code if you want identical behavior in each tool; maintain two copies (or sync from one git repo) under the respective `skills` roots above.

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

Delete the `skill-safety-auditor` folder from the relevant `skills` directory (`.cursor` and/or `.claude`, personal and/or project).
