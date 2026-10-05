#!/usr/bin/env bash
# Install Ansible into an isolated, user-owned Python virtual environment.
set -Eeuo pipefail

die() { printf 'setup: ERROR: %s\n' "$*" >&2; return 1; }

is_cachyos() {
    [[ -r /etc/os-release ]] && grep -Eq '^ID="?cachyos"?$' /etc/os-release
}

main() {
    local mode=${1:-local}
    local project_root
    project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
    local venv=${ANSIBLE_VENV:-$project_root/.venv}
    local requirements=$project_root/requirements-ansible.txt

    ((EUID != 0)) || { die 'run make setup as your normal user, not root'; return 1; }
    [[ $mode == local || $mode == system ]] || { die "unknown setup mode: $mode"; return 1; }
    if [[ $mode == system ]]; then
        is_cachyos || { die 'system package installation is only supported on CachyOS; use make local otherwise'; return 1; }
        command -v pacman >/dev/null 2>&1 || { die 'pacman is required'; return 1; }
        command -v sudo >/dev/null 2>&1 || { die 'sudo is required'; return 1; }
    fi
    [[ $venv == /* ]] || { die "ANSIBLE_VENV must be an absolute path: $venv"; return 1; }

    command -v python3 >/dev/null 2>&1 || {
        die 'python3 is required to create the Ansible virtual environment'
        return 1
    }
    if [[ -x $venv/bin/ansible-playbook ]] \
        && "$venv/bin/ansible-playbook" --version >/dev/null 2>&1 \
        && "$venv/bin/ansible-doc" -t module community.general.pacman >/dev/null 2>&1; then
        return 0
    fi
    if [[ -x $venv/bin/python ]]; then
        printf 'setup: refreshing Python virtual environment at %s\n' "$venv"
        python3 -m venv --upgrade "$venv"
    else
        printf 'setup: creating Python virtual environment at %s\n' "$venv"
        python3 -m venv "$venv"
    fi
    "$venv/bin/python" -m pip --version >/dev/null 2>&1 || {
        die 'pip is unavailable in the virtual environment; install Python venv/ensurepip support'
        return 1
    }
    printf 'setup: installing Ansible and its required collections into %s (no system package changes)\n' "$venv"
    "$venv/bin/python" -m pip install --disable-pip-version-check --upgrade -r "$requirements"
    [[ -x $venv/bin/ansible-playbook ]] && "$venv/bin/ansible-playbook" --version >/dev/null 2>&1 || {
        die 'ansible-playbook is not functional in the virtual environment'
        return 1
    }
    "$venv/bin/ansible-doc" -t module community.general.pacman >/dev/null 2>&1 || {
        die 'the community.general.pacman module is unavailable after installing Ansible'
        return 1
    }
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
