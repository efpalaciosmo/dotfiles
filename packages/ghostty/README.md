# Ghostty Configuration

This Stow package manages `~/.config/ghostty/config`. Ghostty itself is not
installed automatically because Fedora 44 does not publish it in the official
repositories used by this setup.

Install Ghostty manually using its upstream documentation, then apply the
configuration with:

```sh
make dotfiles
```

The configured font is JetBrains Mono. The font role installs its Nerd Font
variant under `~/.local/share/fonts/dotfiles` and refreshes the user font cache.
