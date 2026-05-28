#!/usr/bin/env bash
# 04-packages.sh — Chroot into rootfs and emerge packages
set -euo pipefail
trap "" PIPE

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

  # ── installkernel USE flags ─────────────────────────────────────────────────
  # grub  = run grub-mkconfig after kernel install
  # dracut = build initramfs (required for musl — gentoo-kernel-bin's prebuilt
  #          initramfs is glibc/systemd based and won't boot on musl+openrc)
  mkdir -p /etc/portage/package.use
  cat > /etc/portage/package.use/anthoros << 'EOF'
sys-kernel/installkernel grub dracut -ugrd -ukify -generic-uki
sys-kernel/gentoo-kernel-bin -generic-uki
sys-apps/dracut -systemd
EOF

  # ── package.accept_keywords for dracut on musl ─────────────────────────────
  mkdir -p /etc/portage/package.accept_keywords
  cat > /etc/portage/package.accept_keywords/anthoros << 'EOF'
sys-apps/dracut ~amd64
EOF

  echo "[chroot] Syncing Portage..."
  emerge-webrsync -q

  echo "[chroot] Updating @world..."
  emerge --update --deep --newuse @world -q --nospinner

  echo "[chroot] Installing dracut first (needed before kernel)..."
  emerge --nospinner -q sys-apps/dracut

  echo "[chroot] Installing kernel (dracut will build initramfs automatically)..."
  emerge --nospinner -q sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware

  echo "[chroot] Installing remaining packages..."
  emerge --nospinner -q ${PACKAGES}

  echo "[chroot] Setting root password to locked (no login by default)..."
  passwd -l root

  echo "[chroot] Enabling OpenRC services..."
  rc-update add sshd default 2>/dev/null || true

  echo "[chroot] Verifying kernel + initramfs exist in /boot..."
  ls -lh /boot/vmlinuz-* /boot/initramfs-* 2>/dev/null \
    || { echo "[chroot] ERROR: No kernel/initramfs found in /boot!"; exit 1; }

  echo "[chroot] Cleaning up distfiles and build artifacts..."
  rm -rf /var/cache/distfiles/*
  rm -rf /var/tmp/portage/*

  echo "[chroot] Done."
CHROOT_EOF

echo "[04-packages] Package installation complete."
echo "[04-packages] Done."
