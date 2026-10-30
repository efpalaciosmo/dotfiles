#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

((EUID != 0)) || {
    printf 'dotfiles: run as your normal user, not root\n' >&2
    exit 1
}

(($#)) || { printf 'dotfiles: select at least one Stow package\n' >&2; exit 1; }
for package in "$@"; do
    [[ $package =~ ^[a-zA-Z0-9_-]+$ && -d $repo_root/packages/$package ]] || {
        printf 'dotfiles: invalid or missing package: %s\n' "$package" >&2
        exit 1
    }
done

bash "$repo_root/scripts/validate-configs.sh" "$@"

command -v stow >/dev/null 2>&1 || {
    printf 'dotfiles: GNU Stow is required but is not installed; provide it in the distribution first\n' >&2
    exit 1
}

backup_conflict() {
    local source=$1 target=$2 backup suffix=0

    # A previous Stow run may have linked a parent directory instead of the
    # individual file. Treat that as managed too, or moving TARGET would move
    # the repository file through the linked directory.
    if [[ -e $target ]] &&
        [[ $(readlink -f -- "$target") == $(readlink -f -- "$source") ]]; then
        # Stow does not recognize absolute links, even when they point to us.
        if [[ -L $target && $(readlink -- "$target") == /* ]]; then
            ln -sfn -- "$(realpath --relative-to="$(dirname -- "$target")" -- "$source")" "$target"
        fi
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

# Never back up a file THROUGH an unmanaged directory symlink: that would
# move somebody else's file outside HOME. Back up the parent link instead.
prepare_parents() {
    local package_root=$1 relative=$2 component child parent=$HOME source_parent
    local -a components
    source_parent=$package_root
    IFS=/ read -r -a components <<< "${relative%/*}"
    [[ $relative == */* ]] || return 0
    for component in "${components[@]}"; do
        parent+=/$component
        source_parent+=/$component
        if [[ -L $parent ]] &&
            [[ $(readlink -f -- "$parent") == $(readlink -f -- "$source_parent") ]]; then
            # Unfold old directory links ourselves, including absolute ones
            # which Stow would otherwise reject. Preserve every child entry.
            rm -- "$parent"
            mkdir -- "$parent"
            while IFS= read -r -d '' child; do
                ln -s -- "$(realpath --relative-to="$parent" -- "$child")" "$parent/${child##*/}"
            done < <(find "$source_parent" -mindepth 1 -maxdepth 1 -print0)
            continue
        fi
        if [[ -L $parent || ( -e $parent && ! -d $parent ) ]]; then
            backup_conflict "$source_parent" "$parent"
        fi
        mkdir -p -- "$parent"
    done
}

package_files() {
    find "$1" -type d -name __pycache__ -prune -o \
        -type f ! -iname 'README' ! -iname 'README.*' \
        ! -name '*.pyc' ! -name '*.pyo' -print0
}

for package in "$@"; do
    package_root=$repo_root/packages/$package
    while IFS= read -r -d '' source; do
        relative=${source#"$package_root/"}
        prepare_parents "$package_root" "$relative"
        backup_conflict "$source" "$HOME/$relative"
    done < <(package_files "$package_root")
done

stow --restow --no-folding \
    --dir="$repo_root/packages" \
    --target="$HOME" \
    --ignore='(^|/)(README(\..*)?|__pycache__|[^/]*\.py[co])$' \
    "$@"

# A successful command must mean the requested configuration really is linked.
for package in "$@"; do
    while IFS= read -r -d '' source; do
        relative=${source#"$repo_root/packages/$package/"}
        target=$HOME/$relative
        if [[ ! -L $target || ! -e $target ]] ||
            [[ $(readlink -f -- "$target") != $(readlink -f -- "$source") ]]; then
            printf 'dotfiles: expected managed symlink was not created: %s\n' "$target" >&2
            exit 1
        fi
    done < <(package_files "$repo_root/packages/$package")
done

# Validate the actual auto-loaded files as well as the repository configuration.
# An explicit --config-file alone can hide errors in the default entry points.
if [[ " $* " == *" ghostty "* ]]; then
    ghostty +validate-config
fi

if [[ " $* " == *" desktop "* ]]; then
    "$repo_root/packages/desktop/.local/bin/dotfiles-appearance"
fi

# GNOME's settings are separate from Niri. Also reapplied at GNOME login.
if [[ " $* " == *" gnome "* ]]; then
    "$repo_root/packages/gnome/.local/bin/dotfiles-gnome"
fi

# Retire only old Kitty links from this clone after Ghostty is safely linked.
# Independent Kitty files, other clones and installed software are preserved.
if [[ " $* " == *" ghostty "* ]]; then
    for relative in .config/kitty .config/kitty/kitty.conf; do
        target=$HOME/$relative
        if [[ -L $target ]] &&
            [[ $(readlink -m -- "$target") == "$repo_root/packages/kitty/$relative" ]]; then
            printf 'dotfiles: removing old managed Kitty link %s\n' "$target"
            rm -- "$target"
        fi
    done
fi

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

# Vim uses ~/.vimrc instead of the former ~/.virc. Remove only the old link
# installed by this repository; never delete an independent user's file.
if [[ " $* " == *" vi "* ]]; then
    target=$HOME/.virc
    if [[ -L $target ]] &&
        [[ $(readlink -m -- "$target") == "$repo_root/packages/vi/.virc" ]]; then
        printf 'dotfiles: removing old managed vi link %s\n' "$target"
        rm -- "$target"
    fi
fi
