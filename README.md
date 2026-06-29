# AnthorOS

Minimal rolling Linux distro built on Gentoo (musl + llvm + openrc).  
Automated weekly builds via GitHub Actions using Catalyst.

---

## Downloads

Latest release: [Releases](../../releases/latest)

| File | Description |
|---|---|
| `anthoros-amd64-YYYYMMDD.iso` | Bootable live ISO (BIOS + UEFI) |
| `anthoros-stage3-amd64-YYYYMMDD.tar.xz` | Rootfs tarball |
| `*.sha256` | Checksums |

```bash
# Verify
sha256sum -c anthoros-amd64-YYYYMMDD.iso.sha256

# Write to USB
dd if=anthoros-amd64-YYYYMMDD.iso of=/dev/sdX bs=4M status=progress && sync
```

---

## Stack

- **Libc:** musl
- **Toolchain:** LLVM/Clang
- **Init:** OpenRC
- **Bootloader:** systemd-boot (installed to disk), GRUB (ISO only)
- **Kernel:** gentoo-kernel-bin

---

## Build

Builds run every Sunday at 03:00 UTC, or manually via Actions → Run workflow.

```
catalyst/
├── catalyst.conf          # Catalyst settings
├── specs/
│   ├── livecd-stage1.spec # Package installation
│   └── livecd-stage2.spec # Kernel + ISO assembly
└── portage/
    ├── make.conf
    ├── package.use/
    └── package.accept_keywords/
```

---

## Status

Early development. Things will break.
