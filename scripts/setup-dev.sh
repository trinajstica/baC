#!/usr/bin/env bash
# helper script to install development dependencies for baConverter on common distros
# Usage: sudo ./scripts/setup-dev.sh  OR ./scripts/setup-dev.sh --print (to only print commands)

set -euo pipefail

PRINT_ONLY=0
if [ "${1:-}" = "--print" ] || [ "${1:-}" = "-n" ]; then
  PRINT_ONLY=1
fi

cmd() {
  if [ "$PRINT_ONLY" -eq 1 ]; then
    echo "+ $*"
  else
    echo "+ $*"; bash -c "$*"
  fi
}

if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "Cannot detect distribution (no /etc/os-release). Exiting." >&2
  exit 1
fi

# Common packages variable intentionally removed; distro-specific lists are used below

# Map package names per distribution where they differ
case "${ID_LIKE:-}${ID:-}" in
  *debian*|*ubuntu*|debian|ubuntu)
    echo "Detected Debian/Ubuntu"
    # Debian / Ubuntu use package names like foo-dev and ninja-build, libadwaita-1-dev
    pkgs_debian=(
      build-essential
      meson
      ninja-build
      pkg-config
      libjson-glib-dev
      libgtk-4-dev
      libadwaita-1-dev
      ffmpeg
    )
    install_cmds=(
      "apt update"
      "apt install -y ${pkgs_debian[*]}"
    )
    pkg_manager_cmd="apt"
    ;;
  *fedora*|fedora)
    echo "Detected Fedora"
    install_cmds=(
      # Use pkgconf on Fedora for pkg-config functionality
      "dnf install -y meson ninja-build @development-tools pkgconf libadwaita-devel gtk4-devel json-glib-devel ffmpeg"
    )
    pkg_manager_cmd="dnf"
    ;;
  *arch*|arch|manjaro)
    echo "Detected Arch/Manjaro"
    install_cmds=(
      "pacman -Syu --noconfirm meson ninja base-devel pkgconf libadwaita gtk4 json-glib ffmpeg"
    )
    pkg_manager_cmd="pacman"
    ;;
  *solus*|solus)
    echo "Detected Solus"
    # Solus uses eopkg; package names may vary between repo versions
    install_cmds=(
      "eopkg update-repo"
      "eopkg install -y meson ninja gcc pkgconf libjson-glib-devel ffmpeg libgtk-4-devel libadwaita-devel"
    )
    pkg_manager_cmd="eopkg"
    ;;
  *suse*|opensuse)
    echo "Detected openSUSE"
    install_cmds=(
      "zypper refresh"
      "zypper install -y meson ninja gcc pkg-config libadwaita-devel gtk4-devel libjson-glib-devel ffmpeg"
    )
    pkg_manager_cmd="zypper"
    ;;
  *)
    echo "Unknown or unsupported distribution: $ID. I'll show generic instructions instead." >&2
    install_cmds=(
      "# Generic: install Meson, Ninja, a C compiler, pkg-config and development headers for libadwaita/gtk4/json-glib and ffmpeg"
      "# Debian-like: sudo apt install -y build-essential meson ninja-build pkg-config libadwaita-1-dev libgtk-4-dev libjson-glib-dev ffmpeg"
      "# Fedora: sudo dnf install -y meson ninja-build @development-tools pkgconfig libadwaita-devel gtk4-devel json-glib-devel ffmpeg"
      "# Arch: sudo pacman -Syu meson ninja base-devel pkgconf libadwaita gtk4 json-glib ffmpeg"
      "# Solus: sudo eopkg update-repo && sudo eopkg install -y meson ninja gcc pkgconf libjson-glib-devel ffmpeg libgtk-4-devel libadwaita-devel"
    )
    pkg_manager_cmd=""
    ;;
esac

printf "\n== About to run/install the following (run as root or with sudo) ==\n"
for c in "${install_cmds[@]}"; do
  echo "$c"
done

if [ "$PRINT_ONLY" -eq 1 ]; then
  printf "\n-- printed commands only (--print) --\n"; exit 0
fi

printf "\n== Running install commands ==\n"
if [ -n "${pkg_manager_cmd:-}" ] && ! command -v "$pkg_manager_cmd" >/dev/null 2>&1; then
  echo "Package manager '$pkg_manager_cmd' not found. Please ensure it's available or run the installation manually." >&2
  exit 1
fi

for c in "${install_cmds[@]}"; do
  if [[ "$c" =~ ^# ]]; then
    echo "$c"; continue
  fi
  if [ "$(id -u)" -eq 0 ]; then
    # Already root; run command directly
    cmd "$c"
  elif command -v sudo >/dev/null 2>&1; then
    cmd "sudo $c"
  else
    echo "This script requires root privileges to install packages. Please run as root or install sudo." >&2
    exit 1
  fi
done

printf "\nDone. Verify Meson with: meson --version\n"
