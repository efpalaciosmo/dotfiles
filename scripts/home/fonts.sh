#!/usr/bin/env bash
# scripts/home/fonts.sh
# Install Nerd Fonts in $HOME/.local/share/fonts on the Fedora Silverblue host.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
# shellcheck source=../lib/nerd-fonts.sh
source "$SCRIPT_DIR/../lib/nerd-fonts.sh"

main() {
  log "Instalando Nerd Fonts (host) en \$HOME/.local/share/fonts/nerd-fonts"

  install_nerd_fonts

  print_summary "Fonts (host)" || true
}

main "$@"
