#!/usr/bin/env bash
set -Eeuo pipefail

version=v3.4.0
cache_root=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/fonts
font_root=${XDG_DATA_HOME:-$HOME/.local/share}/fonts
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-fonts.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

require() { command -v "$1" >/dev/null 2>&1 || { printf 'fonts: missing command: %s\n' "$1" >&2; exit 1; }; }
require curl
require tar
require unzip
require find
require fc-cache
mkdir -p "$cache_root" "$font_root"

install_archive() {
    local name=$1 url=$2 archive=$3 extract_dir="$work_dir/$name"
    mkdir -p "$extract_dir"
    if [[ ! -f "$cache_root/$archive" ]]; then
        printf 'fonts: downloading %s\n' "$name"
        curl --fail --location --retry 3 --output "$cache_root/$archive.part" "$url"
        mv "$cache_root/$archive.part" "$cache_root/$archive"
    fi
    case "$archive" in
        *.tar.xz) tar -xJf "$cache_root/$archive" -C "$extract_dir" ;;
        *.zip) unzip -q "$cache_root/$archive" -d "$extract_dir" ;;
        *) printf 'fonts: unsupported archive: %s\n' "$archive" >&2; exit 1 ;;
    esac
    while IFS= read -r -d '' font; do
        install -m 0644 "$font" "$font_root/$(basename "$font")"
    done < <(find "$extract_dir" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \) -print0)
}

install_archive IBMPlexMono \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/$version/IBMPlexMono.tar.xz" \
    IBMPlexMono-$version.tar.xz
install_archive JetBrainsMono \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/$version/JetBrainsMono.tar.xz" \
    JetBrainsMono-$version.tar.xz
install_archive Inter \
    "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip" \
    Inter-4.1.zip

fc-cache -f "$font_root"
printf 'fonts: installed in %s\n' "$font_root"
