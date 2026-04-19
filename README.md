# dotclaude

Personal **Claude Code** dotfiles for Windows: global skills under `skills/`, shared `settings.json`, and per-machine `CLAUDE.md`. Documented skill index and how-tos live in the separate [`ai_enhancement`](https://github.com/racmac57/ai_enhancement) repo.

**Not in this repo:** machine-local caches, session history, plugins marketplace trees, and optional per-folder tooling — see `.gitignore`.

## Multi-Machine CLAUDE.md

The repo contains three variants of the global Claude instructions:

| File | Purpose |
|------|---------|
| `CLAUDE.desktop.md` | Desktop (carucci_r is the real profile, no junction) |
| `CLAUDE.laptop.md`  | Laptop (RobertCarucci is real; carucci_r is a junction) |
| `CLAUDE.shared.md`  | Reference copy of the identical shared content |
| `CLAUDE.md`         | Current deployed version (kept in sync with the above) |

**To deploy on any machine**, run from the repo root:

```powershell
.\Deploy-ClaudeConfig.ps1
```

The script auto-detects which machine it's on (junction check) and copies the correct variant to `~/.claude/CLAUDE.md`.
