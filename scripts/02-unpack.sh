#!/usr/bin/env bash
# 02-unpack.sh — Extract stage3 tarball and set up chroot environment
set -euo pipefail

WORK_DIR="${WORK_DIR:-/build/anthoros}"
ROOTFS="${WORK_DIR}/rootfs"

TARBALL_PATH=$(cat "${WORK_DIR}/.tarball_path")

if [[ ! -f "${TARBALL_PATH}" ]]; then
  echo "[02-unpack] ERROR: Tarball not found at ${TARBALL_PATH}"
  exit 1
fi

echo "[02-unpack] Cleaning and creating rootfs at ${ROOTFS}..."
rm -rf "${ROOTFS}"
mkdir -p "${ROOTFS}"

echo "[02-unpack] Extracting stage3..."
tar xpf "${TARBALL_PATH}" \
  --xattrs-include='*.*' \
  --numeric-owner \
  -C "${ROOTFS}"

echo "[02-unpack] Mounting proc/sys/dev for chroot..."
mount --types proc /proc "${ROOTFS}/proc"
mount --rbind /sys "${ROOTFS}/sys"
mount --make-rslave "${ROOTFS}/sys"
mount --rbind /dev "${ROOTFS}/dev"
mount --make-rslave "${ROOTFS}/dev"
mount --bind /run "${ROOTFS}/run"
mount --make-slave "${ROOTFS}/run"

echo "[02-unpack] Copying resolv.conf..."
cp /etc/resolv.conf "${ROOTFS}/etc/resolv.conf"

echo "[02-unpack] Setting up Portage make.conf..."
cat > "${ROOTFS}/etc/portage/make.conf" << 'EOF'
# AnthorOS build configuration
COMMON_FLAGS="-O2 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

MAKEOPTS="-j$(nproc)"
EMERGE_DEFAULT_OPTS="--jobs=$(nproc) --load-average=$(nproc)"

USE="musl -systemd -pam -nls"
ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="amd64"

# musl+llvm toolchain
CC="clang"
CXX="clang++"
AR="llvm-ar"
NM="llvm-nm"
RANLIB="llvm-ranlib"

GENTOO_MIRRORS="https://distfiles.gentoo.org"
EOF

echo "[02-unpack] Rootfs ready at ${ROOTFS}"
echo "[02-unpack] Done."
