#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

command -v stow >/dev/null 2>&1 || {
    printf 'dotfiles: GNU Stow is required but is not installed; install it from CachyOS first\n' >&2
    exit 1
}

backup_conflict() {
    local source=$1 target=$2 backup suffix=0

    # A previous Stow run may have linked a parent directory instead of the
    # individual file. Treat that as managed too, or moving TARGET would move
    # the repository file through the linked directory.
    if [[ -e $target ]] &&
        [[ $(readlink -f -- "$target") == $(readlink -f -- "$source") ]]; then
        return
    fi
    [[ -e $target || -L $target ]] || return 0

    backup=$target.bak
    while [[ -e $backup || -L $backup ]]; do
        suffix=$((suffix + 1))
        backup=$target.bak.$suffix
    done
    printf 'dotfiles: backing up %s -> %s\n' "$target" "$backup"
    mv -- "$target" "$backup"
}

for package in "$@"; do
    package_root=$repo_root/packages/$package
    [[ -d $package_root ]] || {
        printf 'dotfiles: package does not exist: %s\n' "$package" >&2
        exit 1
    }
    while IFS= read -r -d '' source; do
        relative=${source#"$package_root/"}
        backup_conflict "$source" "$HOME/$relative"
    done < <(find "$package_root" -type f ! -iname 'README' ! -iname 'README.*' -print0)
done

stow --restow --no-folding \
    --dir="$repo_root/packages" \
    --target="$HOME" \
    --ignore='(^|/)(README\.md|README)$' \
    "$@"

# Only after the new package is linked, remove legacy links owned by us.
# Never touch unrelated Rofi settings or user files.
if [[ " $* " == *" fuzzel "* ]]; then
    for relative in config.rasi themes/adwaita-dark.rasi \
        scripts/common scripts/launcher scripts/power-menu scripts/screenshot \
        scripts/clipboard scripts/clipboard-history scripts/bluetooth scripts/wifi; do
        target=$HOME/.config/rofi/$relative
        if [[ -L $target ]] &&
            [[ $(readlink -m -- "$target") == "$repo_root/packages/rofi/.config/rofi/$relative" ]]; then
            printf 'dotfiles: removing old managed Rofi link %s\n' "$target"
            rm -- "$target"
        fi
    done
fi

# Fedora's ~/.virc is not read by Vim on Arch. Remove only the old link
# installed by this repository; never delete an independent user's file.
if [[ " $* " == *" vi "* ]]; then
    target=$HOME/.virc
    if [[ -L $target ]] &&
        [[ $(readlink -m -- "$target") == "$repo_root/packages/vi/.virc" ]]; then
        printf 'dotfiles: removing old managed vi link %s\n' "$target"
        rm -- "$target"
    fi
fi
