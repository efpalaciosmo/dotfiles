#!/usr/bin/env bash
# Desktop notification (Mako) when Claude Code needs attention: a permission
# prompt or a long idle wait. Honors do-not-disturb (Super+Shift+Z).
set -u

command -v notify-send >/dev/null 2>&1 || exit 0

input=$(cat)
message=$(jq -r '.message // empty' <<<"$input" 2>/dev/null)
[[ -n $message ]] || message="Claude Code needs your attention"

project=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
title="Claude Code"
[[ -n $project ]] && title+=" · ${project##*/}"

notify-send -a "Claude Code" -u normal -- "$title" "$message" || true
exit 0
