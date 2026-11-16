#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
files=(bootstrap-dotfiles.sh scripts/*.sh tests/*.sh)
for file in "${files[@]}"; do "$BASH" -n "$file"; done
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x -P SCRIPTDIR "${files[@]}"
else printf 'SKIP ShellCheck: not installed (setup installs it).\n'; fi
old='an''sible|st''own|zyp''per|d''nf|a''pt|pac''man|rpm-ost''ree'
if grep -R -n -I -i -E "(^|[^[:alnum:]_-])($old)([^[:alnum:]_-]|$)" \
  Makefile bootstrap-dotfiles.sh scripts; then
  printf 'Obsolete provisioning/package-manager references in executable configuration.\n' >&2
  exit 1
fi
printf 'Syntax/lint: OK\n'
