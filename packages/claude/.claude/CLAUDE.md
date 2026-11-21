# Global instructions

Shared by Claude Code and opencode (opencode falls back to `~/.claude/CLAUDE.md`
when it has no `~/.config/opencode/AGENTS.md`). Managed from the dotfiles repo:
edit `packages/claude/.claude/CLAUDE.md` there, not this link.

## Language
- Reply in the language I write in (usually Spanish).
- Code, comments, commit messages and repository documentation stay in English
  unless the project already uses another language.

## Environment
- Fedora atomic desktop (`/home` is a symlink to `/var/home`); Niri + Waybar + Fuzzel +
  Mako, Ghostty terminal, Vim, Thunar as file manager, Zsh with Starship. A Fedora Distrobox holds
  development toolchains.
- Visual identity everywhere: Adwaita Dark with orange accent `#ff7800`
  (surface `#1d1d20`, raised `#36363a`, text orange `#ff9c5b`) and JetBrainsMono Nerd Font.
  Keep new UI/theme work consistent with it.
- Configuration lives in `~/Projects/dotfiles_home` and is linked with GNU Stow
  (`make`). Edit the repository file, never the symlink target's copy, and run
  `make check` before saying a change is done.

## Working style
- Read before editing; make the smallest change that solves the problem.
- Do not commit, push or open pull requests unless I ask.
- Say plainly what you did not verify (e.g. visual results need a real session).

## Secrets
- Never read, print or commit credential files: `~/.claude/.credentials.json`,
  `~/.config/opencode/service.json`, `~/.ssh`, `~/.gnupg`, `.env*`.
