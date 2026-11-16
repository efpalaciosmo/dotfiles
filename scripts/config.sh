#!/usr/bin/env bash
# shellcheck disable=SC2034
# One owner per tool. Formula/cask versions roll with Homebrew; runtime majors do not.
MACOS_FORMULAE=(
  bash bash-completion@2 git gh starship jq xz sevenzip
  zsh-autosuggestions zsh-syntax-highlighting
  make cmake ninja pkgconf llvm tree fd ripgrep fzf bat btop zoxide duf ncdu fastfetch
  shellcheck neovim uv fnm octave anomalyco/tap/opencode-v2
)
FONT_CASKS=(font-blex-mono-nerd-font font-jetbrains-mono-nerd-font font-inter)
CORE_CASKS=(mactex-no-gui ghostty visual-studio-code)
APP_CASKS=(
  telegram localsend libreoffice discord obsidian screen-studio raycast
  orbstack zen chatgpt bruno zotero brave-browser rnote onedrive
)
APP_FORMULAE=(mpv)
# App Store ownership: do not also add WhatsApp to APP_CASKS.
MAS_APPS=('310633997|WhatsApp' '937984704|Amphetamine')
ZATHURA_TAP=homebrew-zathura/zathura
ZATHURA_PLUGINS=(pdf-mupdf djvu ps cb)
NODE_VERSION=24
PNPM_VERSION=10
OCTAVE_PACKAGES=(image statistics control signal)
# specfun is archived, not part of today's Octave package index.
SPECFUN_URL=https://downloads.sourceforge.net/octave/specfun-1.1.0.tar.gz
TEX_RESOURCES=(
  article.cls beamer.cls amsmath.sty amsthm.sty amsfonts.sty amssymb.sty
  mathtools.sty booktabs.sty enumitem.sty caption.sty listings.sty geometry.sty
  microtype.sty lmodern.sty eepic.sty setspace.sty threeparttable.sty
  csquotes.sty biblatex.sty
)
EXPECTED_COMMANDS=(
  brew defaults bash zsh git gh make starship curl unzip xz 7zz jq
  gmake cmake ctest ninja pkg-config clang lldb clangd clang-format clang-tidy
  tree fd rg fzf bat btop zoxide duf ncdu fastfetch infocmp tic
  shellcheck nvim uv python3 fnm node pnpm octave opencode mas mpv zathura
  pdflatex xelatex lualatex latexmk bibtex biber kpsewhich
)
SCREENSHOT_DIR=$HOME/Pictures/Screenshots
# Explicitly approved per-user macOS preferences: domain|key|type|value.
MACOS_DEFAULTS=(
  'NSGlobalDomain|AppleShowAllExtensions|bool|true'
  'com.apple.finder|AppleShowAllFiles|bool|true'
  'com.apple.finder|ShowPathbar|bool|true'
  'com.apple.finder|ShowStatusBar|bool|true'
  'com.apple.finder|_FXSortFoldersFirst|bool|true'
  'com.apple.finder|FXDefaultSearchScope|string|SCcf'
  'com.apple.dock|autohide|bool|true'
  'com.apple.dock|show-recents|bool|false'
  "com.apple.screencapture|location|string|$SCREENSHOT_DIR"
  'com.apple.screencapture|type|string|png'
  'NSGlobalDomain|NSAutomaticQuoteSubstitutionEnabled|bool|false'
  'NSGlobalDomain|NSAutomaticDashSubstitutionEnabled|bool|false'
  'NSGlobalDomain|NSAutomaticSpellingCorrectionEnabled|bool|false'
  'com.apple.AppleMultitouchTrackpad|Clicking|bool|true'
  'com.apple.driver.AppleBluetoothMultitouch.trackpad|Clicking|bool|true'
)
