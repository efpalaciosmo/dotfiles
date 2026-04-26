#!/usr/bin/env bash
# scripts/vm/fonts.sh
# Install Nerd Fonts inside the Distrobox container in $HOME/.local/share/fonts.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"
# shellcheck source=../lib/nerd-fonts.sh
source "$SCRIPT_DIR/../lib/nerd-fonts.sh"

main() {
  log "Instalando Nerd Fonts (vm) en \$HOME/.local/share/fonts/nerd-fonts"

  install_nerd_fonts

  summary_note "Your terminal emulator must be configured manually to use the fonts:"
  summary_note "  Principal: 'JetBrainsMono Nerd Font'"
  summary_note "  Alternativa: 'IBMPlexMono Nerd Font'"
  summary_note "Verifica con: fc-match 'JetBrainsMono Nerd Font'"

  print_summary "Fonts (vm)" || true
}

main "$@"
