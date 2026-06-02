#!/usr/bin/env bash
set -Eeuo pipefail

install_args=()
if [[ "${1:-}" == "--no-install" ]]; then
  install_args+=(--no-install)
  shift
fi

if (($# == 0)); then
  printf '[homebrew] ERROR: missing command\n' >&2
  exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
brew_path="$("$script_dir/ensure-homebrew.sh" "${install_args[@]}" --path)"

eval "$("$brew_path" shellenv)"
brew_prefix="$("$brew_path" --prefix)"

for extra_path in \
  "$brew_prefix/opt/make/libexec/gnubin" \
  "$brew_prefix/opt/llvm/bin" \
  "$brew_prefix/opt/openjdk/bin"; do
  if [[ -d "$extra_path" ]]; then
    export PATH="$extra_path:$PATH"
  fi
done

exec "$@"
