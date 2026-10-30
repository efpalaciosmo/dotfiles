#!/usr/bin/env bash
# Validate the repository configuration before linking it.
set -Eeuo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for package in "$@"; do
    case $package in
        niri) niri validate --config "$repo_root/packages/niri/.config/niri/config.kdl" ;;
        fuzzel) fuzzel --check-config --log-no-syslog --config="$repo_root/packages/fuzzel/.config/fuzzel/fuzzel.ini" ;;
        ghostty)
            # Resolve the bundled theme before it has been linked into HOME.
            XDG_CONFIG_HOME="$repo_root/packages/ghostty/.config" \
                ghostty +validate-config --config-file="$repo_root/packages/ghostty/.config/ghostty/config"
            ;;
    esac
done
