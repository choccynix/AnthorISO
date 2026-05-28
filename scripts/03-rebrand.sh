#!/usr/bin/env bash
# 03-rebrand.sh — Apply AnthorOS identity to the rootfs
set -euo pipefail

WORK_DIR="${WORK_DIR:-/build/anthoros}"
ROOTFS="${WORK_DIR}/rootfs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

echo "[03-rebrand] Applying AnthorOS branding..."

# os-release
cp "${CONFIG_DIR}/os-release" "${ROOTFS}/etc/os-release"
ln -sf /etc/os-release "${ROOTFS}/usr/lib/os-release" 2>/dev/null || true

# hostname
echo "anthoros" > "${ROOTFS}/etc/hostname"

# hosts
cat > "${ROOTFS}/etc/hosts" << 'EOF'
127.0.0.1   localhost
127.0.1.1   anthoros
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# motd
cp "${CONFIG_DIR}/motd" "${ROOTFS}/etc/motd"

# issue (shown at login prompt)
cat > "${ROOTFS}/etc/issue" << 'EOF'
AnthorOS \r (\l)

EOF

# Machine-id placeholder (systemd-free, but good practice)
echo "" > "${ROOTFS}/etc/machine-id"

echo "[03-rebrand] Branding applied."
echo "[03-rebrand] Done."
