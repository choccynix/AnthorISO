#!/usr/bin/env bash
# 05-iso.sh — Build a bootable AnthorOS ISO (BIOS + UEFI) and rootfs tarball
set -euo pipefail

WORK_DIR="${WORK_DIR:-/build/anthoros}"
ROOTFS="${WORK_DIR}/rootfs"
ISO_DIR="${WORK_DIR}/iso"
OUTPUT_DIR="${WORK_DIR}/output"
BUILD_DATE="$(date +%Y%m%d)"
ISO_NAME="anthoros-amd64-${BUILD_DATE}.iso"
TARBALL_NAME="anthoros-stage3-amd64-${BUILD_DATE}.tar.xz"

mkdir -p "${ISO_DIR}/boot/grub" "${ISO_DIR}/EFI/BOOT" "${OUTPUT_DIR}"

# ── Tarball ────────────────────────────────────────────────────────────────────
echo "[05-iso] Creating rootfs tarball..."
tar \
  --xattrs \
  --numeric-owner \
  -cJpf "${OUTPUT_DIR}/${TARBALL_NAME}" \
  --exclude="${ROOTFS}/proc/*" \
  --exclude="${ROOTFS}/sys/*" \
  --exclude="${ROOTFS}/dev/*" \
  --exclude="${ROOTFS}/run/*" \
  --exclude="${ROOTFS}/var/tmp/portage/*" \
  --exclude="${ROOTFS}/var/cache/distfiles/*" \
  -C "${ROOTFS}" .

echo "[05-iso] Tarball: ${OUTPUT_DIR}/${TARBALL_NAME} ($(du -sh "${OUTPUT_DIR}/${TARBALL_NAME}" | cut -f1))"

# ── Kernel + initramfs ─────────────────────────────────────────────────────────
echo "[05-iso] Locating kernel and initramfs..."
KERNEL=$(ls "${ROOTFS}/boot/vmlinuz-"* 2>/dev/null | head -n1)
INITRD=$(ls "${ROOTFS}/boot/initramfs-"* 2>/dev/null | head -n1)

if [[ -z "${KERNEL}" || -z "${INITRD}" ]]; then
  echo "[05-iso] ERROR: No kernel or initramfs found in rootfs/boot/"
  echo "         Make sure 'sys-kernel/gentoo-kernel-bin' is in your package.list"
  exit 1
fi

cp "${KERNEL}" "${ISO_DIR}/boot/vmlinuz"
cp "${INITRD}" "${ISO_DIR}/boot/initramfs.img"

# ── Squashfs ───────────────────────────────────────────────────────────────────
echo "[05-iso] Creating squashfs rootfs..."
mksquashfs "${ROOTFS}" "${ISO_DIR}/anthoros.squashfs" \
  -comp xz \
  -Xbcj x86 \
  -b 1M \
  -noappend \
  -e "${ROOTFS}/proc" \
  -e "${ROOTFS}/sys" \
  -e "${ROOTFS}/dev" \
  -e "${ROOTFS}/run"

# ── GRUB config ───────────────────────────────────────────────────────────────
echo "[05-iso] Writing GRUB config..."
cat > "${ISO_DIR}/boot/grub/grub.cfg" << 'EOF'
set default=0
set timeout=5

insmod all_video
insmod gfxterm
terminal_output gfxterm

menuentry "AnthorOS (amd64)" {
    linux  /boot/vmlinuz root=live:CDLABEL=ANTHOROS rd.live.image quiet
    initrd /boot/initramfs.img
}

menuentry "AnthorOS (amd64) - verbose" {
    linux  /boot/vmlinuz root=live:CDLABEL=ANTHOROS rd.live.image
    initrd /boot/initramfs.img
}
EOF

# ── BIOS boot image ────────────────────────────────────────────────────────────
echo "[05-iso] Building BIOS boot image..."
grub-mkimage \
  -O i386-pc \
  -o "${WORK_DIR}/core.img" \
  -p /boot/grub \
  biosdisk iso9660 normal search search_label linux echo all_video gfxterm

cat /usr/lib/grub/i386-pc/cdboot.img "${WORK_DIR}/core.img" \
  > "${ISO_DIR}/boot/grub/bios.img"

# ── UEFI boot image ────────────────────────────────────────────────────────────
echo "[05-iso] Building UEFI boot image..."
grub-mkimage \
  -O x86_64-efi \
  -o "${ISO_DIR}/EFI/BOOT/BOOTX64.EFI" \
  -p /boot/grub \
  iso9660 normal search search_label linux echo all_video gfxterm fat part_gpt

# ── ISO ────────────────────────────────────────────────────────────────────────
echo "[05-iso] Assembling ISO with xorriso..."
xorriso -as mkisofs \
  -iso-level 3 \
  -volid "ANTHOROS" \
  -full-iso9660-filenames \
  -rational-rock \
  -joliet \
  \
  -b boot/grub/bios.img \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  --grub2-boot-info \
  --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
  \
  -eltorito-alt-boot \
  -e EFI/BOOT/BOOTX64.EFI \
  -no-emul-boot \
  --efi-boot-part \
  --efi-boot-image \
  \
  -o "${OUTPUT_DIR}/${ISO_NAME}" \
  "${ISO_DIR}"

echo "[05-iso] ISO: ${OUTPUT_DIR}/${ISO_NAME} ($(du -sh "${OUTPUT_DIR}/${ISO_NAME}" | cut -f1))"

# ── Checksums ──────────────────────────────────────────────────────────────────
echo "[05-iso] Generating checksums..."
pushd "${OUTPUT_DIR}" > /dev/null
sha256sum "${ISO_NAME}" > "${ISO_NAME}.sha256"
sha256sum "${TARBALL_NAME}" > "${TARBALL_NAME}.sha256"
popd > /dev/null

echo "[05-iso] Done. Outputs:"
ls -lh "${OUTPUT_DIR}/"
