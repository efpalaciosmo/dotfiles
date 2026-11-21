#!/usr/bin/env bash
# Read-only check: fontconfig otherwise silently substitutes a different family.
set -euo pipefail

if ! command -v fc-match >/dev/null 2>&1; then
    printf 'MISS fontconfig fc-match (required to verify the managed fonts)\n' >&2
    exit 1
fi

status=0
# Adwaita Sans: desktop UI text. JetBrainsMono Nerd Font: terminal, bar, launcher.
for family in 'Adwaita Sans' 'JetBrainsMono Nerd Font'; do
    matched=$(fc-match --format='%{family}\n' "$family")
    if [[ ! ",$matched," == *",$family,"* ]]; then
        printf 'MISS font %s (fontconfig substitutes %s); install it through your distribution\n' \
            "$family" "${matched:-an unknown font}" >&2
        status=1
        continue
    fi
    printf 'OK   font %s\n' "$family"
done
exit "$status"
