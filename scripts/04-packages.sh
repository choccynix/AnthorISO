#!/usr/bin/env bash
# 04-packages.sh — Chroot into rootfs and emerge packages
set -euo pipefail

WORK_DIR="${WORK_DIR:-/build/anthoros}"
ROOTFS="${WORK_DIR}/rootfs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

PACKAGE_LIST="${CONFIG_DIR}/package.list"

if [[ ! -f "${PACKAGE_LIST}" ]]; then
  echo "[04-packages] ERROR: package.list not found at ${PACKAGE_LIST}"
  exit 1
fi

# Read packages, strip comments and blank lines
PACKAGES=$(grep -v '^\s*#' "${PACKAGE_LIST}" | grep -v '^\s*$' | tr '\n' ' ')

echo "[04-packages] Packages to install: ${PACKAGES}"

chroot "${ROOTFS}" /bin/bash -euo pipefail << CHROOT_EOF
  echo "[chroot] Syncing Portage..."
  emerge-webrsync -q

  echo "[chroot] Updating @world..."
  emerge --update --deep --newuse @world -q --nospinner

  echo "[chroot] Installing packages: ${PACKAGES}"
  emerge --nospinner -q ${PACKAGES}

  echo "[chroot] Setting root password to locked (no login by default)..."
  passwd -l root

  echo "[chroot] Enabling OpenRC services..."
  rc-update add sshd default 2>/dev/null || true

  echo "[chroot] Cleaning up distfiles and build artifacts..."
  rm -rf /var/cache/distfiles/*
  rm -rf /var/tmp/portage/*

  echo "[chroot] Done."
CHROOT_EOF

echo "[04-packages] Package installation complete."
echo "[04-packages] Done."
