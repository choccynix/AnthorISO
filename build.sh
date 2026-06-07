#!/usr/bin/env bash
# build.sh — AnthorOS build orchestrator (Catalyst-based)
set -euo pipefail
trap "" PIPE

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATALYST_DIR="/var/tmp/catalyst"
BUILDS_DIR="${CATALYST_DIR}/builds/anthoros"
OUTPUT_DIR="${REPO_DIR}/output"
SPECS_DIR="${REPO_DIR}/catalyst/specs"

VERSION="${VERSION:-$(date +%Y%m%d)}"
MIRROR="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-musl-llvm-openrc"

mkdir -p "${BUILDS_DIR}" "${OUTPUT_DIR}"

# ── Helpers ────────────────────────────────────────────────────────────────────
log() { echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "  $*"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

fill_spec() {
  local src="$1" dst="$2"
  sed \
    -e "s|@VERSION@|${VERSION}|g" \
    -e "s|@TREEISH@|${TREEISH}|g" \
    -e "s|@REPO_DIR@|${REPO_DIR}|g" \
    "${src}" > "${dst}"
}

# ── Step 1: Fetch stage3 seed ──────────────────────────────────────────────────
log "Fetching stage3 seed"

FILELIST="/tmp/latest-stage3.txt"
curl -fsSL --connect-timeout 30 --max-time 60 -o "${FILELIST}" \
  "${MIRROR}/latest-stage3-amd64-musl-llvm-openrc.txt"

LATEST=$(grep -v '^#' "${FILELIST}" | awk 'NF {print $1}' | head -n1)
TARBALL_NAME=$(basename "${LATEST}")
TARBALL_URL="${MIRROR}/${TARBALL_NAME}"

if [[ ! -f "${BUILDS_DIR}/${TARBALL_NAME}" ]]; then
  echo "Downloading ${TARBALL_NAME}..."
  curl -fsSL --connect-timeout 30 --max-time 1800 --progress-bar \
    -o "${BUILDS_DIR}/${TARBALL_NAME}" "${TARBALL_URL}"

  echo "Verifying checksum..."
  curl -fsSL --connect-timeout 30 --max-time 60 \
    -o "${BUILDS_DIR}/${TARBALL_NAME}.sha256" "${TARBALL_URL}.sha256"
  pushd "${BUILDS_DIR}" > /dev/null
  sha256sum -c "${TARBALL_NAME}.sha256" --ignore-missing
  popd > /dev/null
else
  echo "Stage3 already present, skipping download."
fi

# Rename to the path catalyst expects: rel_type/stage3-...-VERSION
STAGE3_DEST="${BUILDS_DIR}/stage3-amd64-musl-llvm-openrc-${VERSION}.tar.xz"
[[ -f "${STAGE3_DEST}" ]] || cp "${BUILDS_DIR}/${TARBALL_NAME}" "${STAGE3_DEST}"

# ── Step 2: Portage snapshot ───────────────────────────────────────────────────
log "Creating Portage snapshot"
catalyst -s stable
TREEISH=$(catalyst -s stable 2>&1 | grep -oP '(?<=snapshot )\w+' | head -n1)
# Fallback: find the most recent snapshot squashfs
if [[ -z "${TREEISH}" ]]; then
  TREEISH=$(ls -t "${CATALYST_DIR}/snapshots/"*.sqfs 2>/dev/null | head -n1 | xargs basename | sed 's/gentoo-//;s/\.sqfs//')
fi
echo "Portage snapshot: ${TREEISH}"

# ── Step 3: livecd-stage1 ─────────────────────────────────────────────────────
log "Running livecd-stage1"
fill_spec "${SPECS_DIR}/livecd-stage1.spec" "/tmp/anthoros-stage1.spec"
catalyst -f /tmp/anthoros-stage1.spec

# ── Step 4: livecd-stage2 (kernel + ISO) ──────────────────────────────────────
log "Running livecd-stage2 (kernel + ISO)"
fill_spec "${SPECS_DIR}/livecd-stage2.spec" "/tmp/anthoros-stage2.spec"
catalyst -f /tmp/anthoros-stage2.spec

# ── Step 5: Collect outputs ────────────────────────────────────────────────────
log "Collecting outputs"

ISO_SRC="${CATALYST_DIR}/builds/anthoros/anthoros-amd64-${VERSION}.iso"
TARBALL_SRC="${BUILDS_DIR}/stage3-amd64-musl-llvm-openrc-${VERSION}.tar.xz"
ISO_OUT="${OUTPUT_DIR}/anthoros-amd64-${VERSION}.iso"
TARBALL_OUT="${OUTPUT_DIR}/anthoros-stage3-amd64-${VERSION}.tar.xz"

cp "${ISO_SRC}" "${ISO_OUT}"
cp "${TARBALL_SRC}" "${TARBALL_OUT}"

pushd "${OUTPUT_DIR}" > /dev/null
sha256sum "$(basename "${ISO_OUT}")"     > "$(basename "${ISO_OUT}").sha256"
sha256sum "$(basename "${TARBALL_OUT}")" > "$(basename "${TARBALL_OUT}").sha256"
popd > /dev/null

echo ""
echo "Build complete. Outputs:"
ls -lh "${OUTPUT_DIR}/"
