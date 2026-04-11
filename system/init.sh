#!/bin/sh -e

if [ -t 1 ]; then
    RC='\033[0m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
else
    RC=''
    RED=''
    YELLOW=''
    CYAN=''
    GREEN=''
fi

is_command_available() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif is_command_available sudo; then
        sudo "$@"
    else
        printf "%b\n" "${RED}Error: sudo is required for package installation${RC}"
        exit 1
    fi
}

get_package_manager() {
    printf "pacman"
}

ensure_package_manager_available() {
    package_manager="$(get_package_manager)"
    if ! is_command_available "$package_manager"; then
        printf "%b\n" "${RED}Error: '$package_manager' is not available on this system${RC}"
        exit 1
    fi
}

install_packages() {
    package_manager="$(get_package_manager)"
    packages="$*"

    if [ -z "$packages" ]; then
        return 0
    fi

    printf "%b\n" "${CYAN}Installing packages with ${package_manager}...${RC}"

    run_as_root pacman -S --noconfirm --needed $packages
}

verify_script_permissions() {
    script_dir="$(dirname "$(realpath "$0")")"
    if [ ! -w "$script_dir" ]; then
        printf "%b\n" "${RED}Error: Cannot write to directory $script_dir${RC}"
        printf "%b\n" "${YELLOW}Please ensure you have write permissions${RC}"
        exit 1
    fi
}

checkEnv() {
    ensure_package_manager_available
    verify_script_permissions
}
