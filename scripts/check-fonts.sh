#!/usr/bin/env bash
# Read-only check: fontconfig otherwise silently substitutes a different family.
set -euo pipefail

if ! command -v fc-match >/dev/null 2>&1; then
    printf 'MISS fontconfig fc-match (required to verify JetBrains fonts)\n' >&2
    exit 1
fi

family='JetBrainsMono Nerd Font'
matched=$(fc-match --format='%{family}\n' "$family")
if [[ ! ",$matched," == *",$family,"* ]]; then
    printf 'MISS font %s (fontconfig substitutes %s); install JetBrains Mono Nerd Font through your distribution\n' \
        "$family" "${matched:-an unknown font}" >&2
    exit 1
fi
printf 'OK   font %s\n' "$family"
