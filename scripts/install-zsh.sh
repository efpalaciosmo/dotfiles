#!/usr/bin/env bash
# Install Oh My Zsh and the two Zsh plugins used by ~/.zshrc, entirely under $HOME.
# No package manager is involved, so it works on immutable Fedora (no rpm-ostree layering).
#
# Every repository is pinned to a commit: this code runs in every interactive shell, so
# it must not change underneath you. To update, bump the SHAs below and run `make`.
set -Eeuo pipefail

omz_dir=${ZSH:-$HOME/.oh-my-zsh}
custom_dir=${ZSH_CUSTOM:-$omz_dir/custom}

omz_url=${DOTFILES_OMZ_URL:-https://github.com/ohmyzsh/ohmyzsh.git}
omz_sha=${DOTFILES_OMZ_SHA:-c0140703a53eb0d22be44f7bac318d0baacc927c}
autosuggestions_url=${DOTFILES_AUTOSUGGESTIONS_URL:-https://github.com/zsh-users/zsh-autosuggestions.git}
autosuggestions_sha=${DOTFILES_AUTOSUGGESTIONS_SHA:-85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5}
highlighting_url=${DOTFILES_HIGHLIGHTING_URL:-https://github.com/zsh-users/zsh-syntax-highlighting.git}
highlighting_sha=${DOTFILES_HIGHLIGHTING_SHA:-e6683f20e5c38d3e5447f45845d04ddda75d0f23}

command -v git >/dev/null 2>&1 || {
    printf 'install-zsh: git is required to fetch Oh My Zsh\n' >&2
    exit 1
}

# Clone URL at an exact commit into DIR, or move an existing clean checkout to it.
# Never touches a directory that is not a Git checkout or has local changes.
sync_repo() {
    local name=$1 url=$2 sha=$3 dir=$4 tmp

    if [[ -e $dir && ! -d $dir/.git ]]; then
        printf 'install-zsh: %s exists but is not a Git checkout; leaving it alone\n' "$dir" >&2
        return 1
    fi

    if [[ -d $dir/.git ]]; then
        if [[ $(git -C "$dir" rev-parse HEAD 2>/dev/null) == "$sha" ]]; then
            printf 'OK   %s already at %.12s\n' "$name" "$sha"
            return 0
        fi
        # Untracked files (the plugins live inside Oh My Zsh's tree) do not count as edits.
        if [[ -n $(git -C "$dir" status --porcelain --untracked-files=no 2>/dev/null) ]]; then
            printf 'install-zsh: %s has local changes; not moving it to %.12s\n' "$dir" "$sha" >&2
            return 1
        fi
        git -C "$dir" fetch --quiet --depth 1 origin "$sha"
        git -C "$dir" -c advice.detachedHead=false checkout --quiet FETCH_HEAD
        printf 'OK   %s updated to %.12s\n' "$name" "$sha"
        return 0
    fi

    mkdir -p -- "${dir%/*}"
    # Build beside the destination and move into place: a failed or interrupted
    # download must not leave a half-populated directory that looks installed.
    tmp=$(mktemp -d "$dir.tmp.XXXXXX")
    if git -C "$tmp" init --quiet &&
        git -C "$tmp" remote add origin "$url" &&
        git -C "$tmp" fetch --quiet --depth 1 origin "$sha" &&
        git -C "$tmp" -c advice.detachedHead=false checkout --quiet FETCH_HEAD; then
        chmod 755 -- "$tmp"
        mv -- "$tmp" "$dir"
        printf 'OK   %s installed at %.12s\n' "$name" "$sha"
    else
        rm -rf -- "$tmp"
        printf 'install-zsh: could not download %s (%s at %.12s)\n' "$name" "$url" "$sha" >&2
        return 1
    fi
}

failures=0
sync_repo oh-my-zsh "$omz_url" "$omz_sha" "$omz_dir" || failures=$((failures + 1))

# The plugins live inside Oh My Zsh's custom directory; without it there is nowhere to put them.
if [[ -f $omz_dir/oh-my-zsh.sh ]]; then
    sync_repo zsh-autosuggestions "$autosuggestions_url" "$autosuggestions_sha" \
        "$custom_dir/plugins/zsh-autosuggestions" || failures=$((failures + 1))
    sync_repo zsh-syntax-highlighting "$highlighting_url" "$highlighting_sha" \
        "$custom_dir/plugins/zsh-syntax-highlighting" || failures=$((failures + 1))
fi

((failures == 0)) || {
    printf 'install-zsh: %d component(s) not installed; rerun make when online\n' "$failures" >&2
    exit 1
}
