# Desktop Setup Checklist

Run these once when sitting down at the desktop for the first time after the multi-machine refactor.

## One-time setup

```powershell
# 1. Pull latest main
cd C:\Users\carucci_r\dotclaude
git pull origin main

# 2. Deploy correct CLAUDE.md (auto-detects desktop)
.\Deploy-ClaudeConfig.ps1

# 3. Create council skill junction
Remove-Item -Recurse -Force "C:\Users\carucci_r\.claude\skills\council"
New-Item -ItemType Junction -Path "C:\Users\carucci_r\.claude\skills\council" -Target "C:\Users\carucci_r\dotclaude\skills\council"

# 4. Verify junction
ls C:\Users\carucci_r\.claude\skills\council\SKILL.md
```

## Verify council skill is live

In Claude Code on the desktop:
```
/council --c1 Confirm council skill is live on desktop.
List the five Phase 1 agent names.
```

---

## Ongoing workflow note

After any `git pull` on either machine, run `.\Deploy-ClaudeConfig.ps1` if `CLAUDE.md` was in the changeset.
The script auto-detects the machine — safe no-op if nothing changed.
