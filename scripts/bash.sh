#!/bin/bash
# Deliberately Bash 3.2 compatible: no installation, even during dry runs.
set -eu
if [ "$(uname -s)" = Darwin ]; then
  [ "$(uname -m)" = arm64 ] || {
    echo "Run in a native Apple Silicon terminal, not Rosetta." >&2; exit 1;
  }
  [ -x /opt/homebrew/bin/brew ] || {
    echo "Install Homebrew deliberately: https://docs.brew.sh/Installation" >&2; exit 1;
  }
  eval "$(/opt/homebrew/bin/brew shellenv)"
  bash_path="$(/opt/homebrew/bin/brew --prefix)/bin/bash"
else
  # Linux is supported for offline verification only; setup still guards Darwin.
  bash_path="$(command -v bash)"
fi
[ -x "$bash_path" ] || { echo "Install modern Bash with: brew install bash" >&2; exit 1; }
"$bash_path" -c '((BASH_VERSINFO[0] >= 5))' || {
  echo "Automation requires Bash 5+ (brew install bash)." >&2; exit 1;
}
exec "$bash_path" "$@"
