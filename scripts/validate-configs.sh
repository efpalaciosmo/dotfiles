#!/usr/bin/env bash
# Validate the repository configuration before linking it.
set -Eeuo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for package in "$@"; do
    case $package in
        niri) niri validate --config "$repo_root/packages/niri/.config/niri/config.kdl" ;;
        fuzzel) fuzzel --check-config --log-no-syslog --config="$repo_root/packages/fuzzel/.config/fuzzel/fuzzel.ini" ;;
        fastfetch)
            # A config error makes fastfetch exit non-zero and print "JsonConfig Error".
            fastfetch --config "$repo_root/packages/fastfetch/.config/fastfetch/config.jsonc" \
                --format json >/dev/null
            ;;
        vi)
            # The colorscheme must load without messages (silent! would hide mistakes).
            output=$(mktemp)
            vim -Nu NONE --cmd "set rtp^=$repo_root/packages/vi/.vim" -i NONE -es -n \
                -c 'set termguicolors' -c "redir! > $output" -c 'colorscheme adwaita-orange' \
                -c 'messages' -c 'redir END' -c 'qa!' </dev/null >/dev/null 2>&1 || true
            if grep -Eiq 'error|E[0-9]+:' "$output"; then
                cat "$output" >&2; rm -f -- "$output"; exit 1
            fi
            rm -f -- "$output"
            ;;
        ghostty)
            # Resolve the bundled theme before it has been linked into HOME.
            XDG_CONFIG_HOME="$repo_root/packages/ghostty/.config" \
                ghostty +validate-config --config-file="$repo_root/packages/ghostty/.config/ghostty/config.ghostty"
            ;;
    esac
done
