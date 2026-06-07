<div align="center">

```
  █████╗ ███╗   ██╗████████╗██╗  ██╗ ██████╗ ██████╗  ██████╗ ███████╗
 ██╔══██╗████╗  ██║╚══██╔══╝██║  ██║██╔═══██╗██╔══██╗██╔═══██╗██╔════╝
 ███████║██╔██╗ ██║   ██║   ███████║██║   ██║██████╔╝██║   ██║███████╗
 ██╔══██║██║╚██╗██║   ██║   ██╔══██║██║   ██║██╔══██╗██║   ██║╚════██║
 ██║  ██║██║ ╚████║   ██║   ██║  ██║╚██████╔╝██║  ██║╚██████╔╝███████║
 ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
```

**A minimal, rolling-release Linux distribution built on Gentoo.**  
`musl` · `llvm` · `openrc` · `amd64`

![Build Status](https://github.com/your-org/anthoros/actions/workflows/build.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue)

</div>

---

## What is AnthorOS?

AnthorOS is a minimal Linux distribution assembled from a Gentoo `stage3-amd64-musl-llvm-openrc` base. It uses musl libc instead of glibc for a leaner footprint, LLVM/Clang as the toolchain, and OpenRC for init — no systemd. Builds are fully automated via GitHub Actions and published weekly as a bootable ISO and rootfs tarball.

The goal right now is a clean, minimal base to build on top of. Package selection and configuration will grow over time.

---

## Downloads

Grab the latest release from the [Releases page](../../releases/latest).

| File | Description |
|---|---|
| `anthoros-amd64-YYYYMMDD.iso` | Bootable ISO — BIOS and UEFI |
| `anthoros-stage3-amd64-YYYYMMDD.tar.xz` | Rootfs tarball for chroot/container use |
| `*.sha256` | SHA-256 checksums |

**Verify your download:**
```bash
sha256sum -c anthoros-amd64-YYYYMMDD.iso.sha256
sha256sum -c anthoros-stage3-amd64-YYYYMMDD.tar.xz.sha256
```

---

## Booting the ISO

**BIOS:** Write the ISO to a USB drive with `dd` and boot.
```bash
dd if=anthoros-amd64-YYYYMMDD.iso of=/dev/sdX bs=4M status=progress && sync
```

**UEFI:** Same process — the ISO is a hybrid image that works with both firmware types.

**QEMU (quick test):**
```bash
# BIOS
qemu-system-x86_64 -cdrom anthoros-amd64-YYYYMMDD.iso -m 2G

# UEFI (requires OVMF)
qemu-system-x86_64 -cdrom anthoros-amd64-YYYYMMDD.iso -m 2G \
  -bios /usr/share/ovmf/OVMF.fd
```

---

## Using the Tarball

The rootfs tarball can be used as a base for a chroot environment or container.

```bash
# Extract to a directory
mkdir anthoros-root
tar xpf anthoros-stage3-amd64-YYYYMMDD.tar.xz \
  --xattrs-include='*.*' \
  --numeric-owner \
  -C anthoros-root/

# Chroot in
mount --bind /proc anthoros-root/proc
mount --bind /sys  anthoros-root/sys
mount --bind /dev  anthoros-root/dev
chroot anthoros-root /bin/bash
```

---

## Build System

Builds run automatically every Sunday at 03:00 UTC. You can also trigger a build manually from the Actions tab.

### Project Structure

```
anthoros/
├── scripts/
│   ├── 01-fetch.sh       # Download latest Gentoo stage3 tarball
│   ├── 02-unpack.sh      # Extract + set up chroot environment
│   ├── 03-rebrand.sh     # Apply AnthorOS identity
│   ├── 04-packages.sh    # Emerge packages from package.list
│   ├── 05-iso.sh         # Build ISO + rootfs tarball
│   └── build.sh          # Orchestrator
├── config/
│   ├── os-release        # OS identity (NAME, VERSION, etc.)
│   ├── motd              # Login message
│   └── package.list      # Packages to emerge
└── .github/
    └── workflows/
        └── build.yml     # GitHub Actions workflow
```

### Running Locally

You'll need a privileged environment (root or a privileged container) and the following host tools:

- `squashfs-tools` — for `mksquashfs`
- `xorriso` — for ISO assembly
- `grub` — for `grub-mkimage` and boot images

```bash
# Full build
WORK_DIR=/build/anthoros ./scripts/build.sh all

# Individual steps
WORK_DIR=/build/anthoros ./scripts/build.sh fetch
WORK_DIR=/build/anthoros ./scripts/build.sh unpack
WORK_DIR=/build/anthoros ./scripts/build.sh rebrand
WORK_DIR=/build/anthoros ./scripts/build.sh packages
WORK_DIR=/build/anthoros ./scripts/build.sh iso
```

Running inside the official Gentoo container image is recommended:
```bash
docker run --privileged -it \
  -v "$(pwd)":/anthoros \
  -e WORK_DIR=/build/anthoros \
  gentoo/stage3:musl-llvm \
  bash /anthoros/scripts/build.sh all
```

### Adding Packages

Edit `config/package.list`. Lines starting with `#` are comments.

```
# My new package
app-misc/something
```

Portage snapshots are cached in CI keyed to the package list, so a change there will bust the cache and trigger a fresh sync.

### Customizing Branding

| File | What it controls |
|---|---|
| `config/os-release` | Fields shown by `os-release`, `hostnamectl`, etc. |
| `config/motd` | Printed at login |
| `scripts/03-rebrand.sh` | Hostname, `/etc/hosts`, `/etc/issue` |

---

## CI / Releases

| Trigger | What happens |
|---|---|
| Push to `main` (scripts or config changed) | Build runs, ISO + tarball uploaded as artifacts |
| Weekly schedule (Sunday 03:00 UTC) | Full build + published as a GitHub Release |
| Manual dispatch | Full build; optionally publish as a release |

Releases are tagged `rolling-YYYYMMDD`. The previous rolling release is replaced each week so the Releases page stays clean.

Artifacts from non-release builds are retained for 14 days.

---

## Roadmap

- [ ] Custom kernel configuration
- [ ] Installer script
- [ ] Expanded package sets (desktop, server, minimal)
- [ ] arm64 support
- [ ] Reproducible builds

---

## License

MIT — do whatever you want with it.
