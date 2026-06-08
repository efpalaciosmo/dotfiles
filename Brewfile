# Portable Brewfile for Linux and macOS.
# Optimized for CLI development, Neovim, LaTeX/math writing, data work,
# and immutable Linux systems such as Fedora Silverblue.

# =============================================================================
# 1. Bootstrap essentials
# =============================================================================
# Keep this section small: tools needed early by dotfiles, scripts, shells,
# and the rest of the setup.

brew "git"
brew "gh"
brew "curl"
brew "wget"
brew "make"
brew "stow"
brew "unzip"
brew "xz"
brew "sevenzip"
brew "bash"
brew "bash-completion@2"
brew "zsh"
brew "starship"
brew "jq"


# =============================================================================
# 2. GNU compatibility / OS-specific base
# =============================================================================
# macOS ships BSD variants of many tools. These GNU versions make scripts
# more portable between macOS and Linux.
#
# On Linux/Silverblue, many of these may already exist at the system level,
# but installing them with Brew gives you a consistent Homebrew-managed toolset.

if OS.mac?
  brew "coreutils"
  brew "findutils"
  brew "gnu-sed"
  brew "grep"
  brew "gawk"
end

if OS.linux?
  # Useful when Homebrew needs a self-contained Linux toolchain.
  brew "binutils"
  brew "gcc"
  brew "glibc"
end


# =============================================================================
# 3. Build tools
# =============================================================================

brew "cmake"
brew "ninja"
brew "pkgconf"


# =============================================================================
# 4. Daily CLI tools
# =============================================================================
# Removed duplicates:
# - fd appeared twice
# - jq appeared twice
# - rg and ripgrep are the same idea; the formula name is ripgrep

brew "tree"
brew "fd"
brew "ripgrep"
brew "fzf"
brew "bat"
brew "tmux"
brew "zoxide"
brew "duf"
brew "ncdu"
brew "fastfetch"
brew "lazygit"
brew "lazydocker"
brew "yazi"
brew "resvg"


# =============================================================================
# 5. Shell / script quality tools
# =============================================================================
# Very useful for dotfiles, automation scripts, CI scripts and Brew-managed setup.

brew "shellcheck"
brew "shfmt"


# =============================================================================
# 6. Editor tooling
# =============================================================================

brew "neovim"
brew "tree-sitter-cli"
brew "lua"
brew "stylua"

# =============================================================================
# 7. LaTeX / thesis writing
# =============================================================================
# Linux:
#   Use TeX Live directly through Homebrew.
#
# macOS:
#   Prefer MacTeX through cask. For a terminal/Neovim workflow, mactex-no-gui
#   is usually better than full mactex because it avoids extra GUI apps.
#
# Do not install both texlive and mactex/mactex-no-gui on macOS unless you
# intentionally want parallel TeX installations.

if OS.linux?
  brew "texlive"
  brew "biber"
end

if OS.mac?
  cask "mactex-no-gui"
  # Alternative if you want TeXShop and other GUI applications:
  cask "mactex"
end


# =============================================================================
# 8. Language/package managers
# =============================================================================

brew "uv"
brew "fnm"
brew "pnpm"
brew "rustup"


# =============================================================================
# 9. Programming languages / heavier toolchains
# =============================================================================

brew "go"
brew "zig"
brew "juliaup"
brew "llvm"


# =============================================================================
# 10. Data, documents, PDFs, images and media
# =============================================================================
# poppler: PDF tools, pdftotext, pdfinfo, etc.
# imagemagick-full: broader image format support than imagemagick.
# ffmpeg-full: broader codec/library support than ffmpeg.

brew "poppler"
brew "imagemagick-full"
brew "ffmpeg-full"
brew "zathura"
brew "zathura-cb"
brew "zathura-djvu"
brew "zathura-pdf-poppler"
brew "zathura-ps"
