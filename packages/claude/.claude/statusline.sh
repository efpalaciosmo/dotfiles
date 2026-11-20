#!/usr/bin/env bash
# Claude Code status line in the desktop's Adwaita palette (24-bit colors).
# Receives the session as JSON on stdin; prints one line:
#   ~/path  branch*  Model  ctx NN%
set -u

input=$(cat)
field() { jq -r "$1 // empty" <<<"$input" 2>/dev/null; }

orange=$'\e[1;38;2;255;156;91m'   # #ff9c5b directory
purple=$'\e[38;2;220;138;221m'    # #dc8add git
blue=$'\e[38;2;153;193;241m'      # #99c1f1 model
green=$'\e[38;2;143;240;164m'     # #8ff0a4 healthy context
amber=$'\e[38;2;255;194;82m'      # #ffc252 context getting full
red=$'\e[38;2;255;147;140m'       # #ff938c context nearly full
dim=$'\e[38;2;154;153;150m'       # #9a9996 separators
reset=$'\e[0m'

dir=$(field '.workspace.current_dir')
[[ -n $dir ]] || dir=$(field '.cwd')
[[ -n $dir ]] || dir=$PWD
# /home may be a symlink (e.g. /var/home on atomic Fedora): compare real paths.
home=$(readlink -f -- "$HOME" 2>/dev/null || printf '%s' "$HOME")
real=$(readlink -f -- "$dir" 2>/dev/null || printf '%s' "$dir")
shown=${real/#"$home"/\~}

line="${orange}${shown}${reset}"

if branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null ||
    git -C "$dir" rev-parse --short HEAD 2>/dev/null); then
    mark=''
    [[ -n $(git -C "$dir" status --porcelain 2>/dev/null | head -n 1) ]] && mark='*'
    line+="  ${purple} ${branch}${mark}${reset}"
fi

model=$(field '.model.display_name')
[[ -n $model ]] && line+="  ${blue}${model}${reset}"

used=$(field '.context_window.used_percentage')
if [[ $used =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    pct=${used%.*}
    color=$green
    ((pct >= 60)) && color=$amber
    ((pct >= 85)) && color=$red
    line+="  ${dim}ctx${reset} ${color}${pct}%${reset}"
fi

printf '%s\n' "$line"
