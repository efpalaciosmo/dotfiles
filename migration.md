# Aeon + Tumbleweed Dotfiles Migration Plan

## Summary

Refactor the dotfiles automation before reinstalling or migrating the machine. The repo should target an openSUSE Aeon host plus a manually entered openSUSE Tumbleweed Distrobox.

Aeon facts used for this plan:

- Aeon favors Flatpak, user Distrobox, local binaries, then transactional-update.
- Distrobox and Podman are included in Aeon.
- The current Aeon base pattern includes `vim-small`.
- Aeon is still marked as a release candidate in the official docs.

Sources:

- [Aeon Desktop](https://aeondesktop.github.io/)
- [Aeon Software Installation](https://github.com/AeonDesktop/Project/wiki/Software-Installation)
- [patterns-aeon.spec](https://build.opensuse.org/projects/openSUSE%3AFactory/packages/patterns-aeon/files/patterns-aeon.spec?expand=0)

## Key Changes

- Rename public targets:
  - Add `make aeon` for host user-space setup.
  - Add `make tw-vm` for the Tumbleweed Distrobox profile.
  - Keep temporary compatibility aliases `home -> aeon` and `vm -> tw-vm` only during the transition, then remove them after docs are updated.
- Remove host package management:
  - Delete Arch `pacman` role usage and package lists.
  - Do not add `transactional-update` package installs.
  - Keep only user-space host actions: Flatpaks, fonts, local user tools, shell/git/starship/vim dotfiles.
- Remove Distrobox creation from this repo:
  - Delete the host-side Distrobox install, create, and podman bridge workflow.
  - The VM profile assumes the user already entered a Tumbleweed environment manually.
- Replace Fedora VM with Tumbleweed VM:
  - Replace `dnf` tasks with `zypper` tasks.
  - Rename Fedora package variables to Tumbleweed package variables.
  - Map package names to openSUSE names, for example `fd-find -> fd`, `ninja-build -> ninja`, `clang-tools-extra -> clang-tools`, while keeping confirmed names like `gh`, `ripgrep`, and `zig`.
- Remove the old desktop stack:
  - Delete or unmanage Niri, Waybar, Mako, Rofi, and Foot configs.
  - Host dotfiles should focus on GNOME and Aeon-compatible configs only.
- Remove all context and compatibility checks as requested:
  - Delete Distrobox, ostree, host/VM, and OS guard logic.
  - Keep tasks profile-driven; wrong-target execution becomes the user's responsibility.

## Editor Plan

- Split editor packages:
  - Host: `packages/vim` with `~/.vimrc`, targeting Aeon's default `vim-small`.
  - VM: `packages/nvim-vm` with the full plugin-based Neovim config.
- Translate only portable host behavior from Neovim to Vimscript:
  - indentation, search, line numbers when supported, colors fallback, netrw basics, sensible file handling, and minimal keymaps.
  - no Lua, no Neovim APIs, no plugins, no Treesitter, no LSP, and no Mason on host.
- Apply `packages/vim` only in `make aeon`.
- Apply `packages/nvim-vm` only in `make tw-vm`.

## Best Execution Order

1. Commit or stash current work, especially the untracked `packages/nvim/`.
2. Refactor the repo and docs while still on the current system.
3. Run syntax checks locally.
4. Install openSUSE Aeon.
5. On the Aeon host, run `make setup`, then `make aeon`.
6. Manually enter the Aeon-provided Tumbleweed Distrobox.
7. Inside that container, run `make setup`, then `make tw-vm`.
8. Remove compatibility aliases once both profiles work.

## Test Plan

- `make check` passes for both renamed profiles.
- `DRY_RUN=1 make aeon` does not call `pacman`, `dnf`, `zypper`, `transactional-update`, or Distrobox creation.
- `DRY_RUN=1 make tw-vm` uses `zypper`, not `dnf`.
- Host stow list contains only Aeon-safe packages.
- VM stow list applies the full Neovim config.
- Host Vim starts with `vim -Nu ~/.vimrc` without plugin or Lua errors.

## Assumptions

- "No host packages" means no RPM or transactional system package installs, but Flatpaks, fonts, and user-local binaries are still allowed.
- The Tumbleweed Distrobox lifecycle is manual and outside this repo.
- No context checks means no safety assertions against running the wrong profile in the wrong place.
