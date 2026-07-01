#!/usr/bin/env bash
set -Eeuo pipefail

install=1
if [[ "${1:-}" == "--no-install" ]]; then
  install=0
  shift
fi

if (($# == 0)); then
  printf '[homebrew] ERROR: missing command\n' >&2
  exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if ((install == 1)); then
  brew_path="$("$script_dir/ensure-homebrew.sh" --path)"
else
  brew_path="$("$script_dir/ensure-homebrew.sh" --no-install --path)"
fi

if [[ "$brew_path" == *$'\n'* || ! -x "$brew_path" ]]; then
  printf '[homebrew] ERROR: invalid brew path from ensure-homebrew.sh: %q\n' "$brew_path" >&2
  exit 1
fi

eval "$("$brew_path" shellenv)"
brew_prefix="$("$brew_path" --prefix)"

for extra_path in \
  "$brew_prefix/opt/make/libexec/gnubin" \
  "$brew_prefix/opt/gnu-tar/libexec/gnubin" \
  "$brew_prefix/opt/llvm/bin" \
  "$brew_prefix/opt/ffmpeg-full/bin" \
  "$brew_prefix/opt/imagemagick-full/bin" \
  /Library/TeX/texbin; do
  if [[ -d "$extra_path" ]]; then
    export PATH="$extra_path:$PATH"
  fi
done

exec "$@"
