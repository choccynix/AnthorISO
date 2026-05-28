# AnthorOS

A minimal, rolling-release Linux distribution built on Gentoo (musl + llvm + openrc).

## Build System

Modular shell scripts, designed to run inside a Gentoo container via GitHub Actions.

### Scripts

| Script | Purpose |
|---|---|
| `01-fetch.sh` | Download latest stage3 tarball from Gentoo mirrors |
| `02-unpack.sh` | Extract tarball, mount chroot environment |
| `03-rebrand.sh` | Apply AnthorOS identity (os-release, motd, hostname) |
| `04-packages.sh` | Emerge packages from `config/package.list` |
| `05-iso.sh` | Build bootable ISO (BIOS + UEFI) via xorriso |
| `build.sh` | Orchestrator — run one step or all |

### Usage

```bash
# Run full build
WORK_DIR=/build/anthoros ./scripts/build.sh all

# Run a specific step
WORK_DIR=/build/anthoros ./scripts/build.sh packages
```

### Requirements (host)

- `squashfs-tools` (mksquashfs)
- `xorriso`
- `grub` (for grub-mkimage and boot_hybrid.img)
- Privileged container or root (for chroot mounts)

## Configuration

| File | Purpose |
|---|---|
| `config/os-release` | OS identity fields |
| `config/motd` | Message of the day |
| `config/package.list` | Packages to emerge (comments with `#`) |

## ISO

- Supports BIOS (El Torito + hybrid MBR) and UEFI (GPT + EFI partition)
- Rootfs is squashfs-compressed (xz)
- Volume label: `ANTHOROS`

## GitHub Actions

Build triggers on push to `main` or manually via workflow dispatch.
ISO is uploaded as a build artifact (7 day retention).
Tagged releases automatically attach the ISO.
