#!/usr/bin/env bash
# build.sh — AnthorOS build orchestrator (Catalyst-based)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALYST_DIR="/var/tmp/catalyst"
BUILDS_DIR="${CATALYST_DIR}/builds/anthoros"
OUTPUT_DIR="${REPO_DIR}/output"
SPECS_DIR="${REPO_DIR}/catalyst/specs"
CATALYST_CONF="${REPO_DIR}/catalyst/catalyst.conf"
VERSION="${VERSION:-$(date +%Y%m%d)}"
MIRROR="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-musl-llvm-openrc"

mkdir -p "${BUILDS_DIR}" "${OUTPUT_DIR}"

log() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $*"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

fill_spec() {
  local src="$1" dst="$2"
  sed \
    -e "s|@VERSION@|${VERSION}|g" \
    -e "s|@TREEISH@|${TREEISH}|g" \
    -e "s|@REPO_DIR@|${REPO_DIR}|g" \
    "${src}" > "${dst}"
}

# ── Step 1: Fetch stage3 seed ─────────────────────────────────────────────────
log "Fetching stage3 seed"

FILELIST="/tmp/latest-stage3.txt"
curl -fsSL --connect-timeout 30 --max-time 60 \
  -o "${FILELIST}" \
  "${MIRROR}/latest-stage3-amd64-musl-llvm-openrc.txt"

# Parse without pipelines to avoid SIGPIPE under GHA pipefail
LATEST=''
while IFS= read -r line; do
  [[ -z "${line}" ]]          && continue
  [[ "${line}" == '#'*  ]]    && continue
  [[ "${line}" == '-----'* ]] && continue
  [[ "${line}" == 'Hash:'* ]] && continue
  [[ "${line}" != *'.tar.xz'* ]] && continue
  LATEST="${line%% *}"
  break
done < "${FILELIST}"

if [[ -z "${LATEST}" ]]; then
  echo "ERROR: Could not parse stage3 filename from file list:"
  cat "${FILELIST}"
  exit 1
fi

TARBALL_NAME=$(basename "${LATEST}")
STAGE3_DEST="${BUILDS_DIR}/stage3-amd64-musl-llvm-openrc-${VERSION}.tar.xz"

if [[ ! -f "${STAGE3_DEST}" ]]; then
  echo "Downloading ${TARBALL_NAME}..."
  curl -fsSL --connect-timeout 30 --max-time 1800 --progress-bar \
    -o "${STAGE3_DEST}" "${MIRROR}/${TARBALL_NAME}"
else
  echo "Stage3 already present, skipping download."
fi

# ── Step 2: Portage snapshot ──────────────────────────────────────────────────
log "Creating Portage snapshot"
catalyst --configs "${CATALYST_CONF}" -s stable

# Find snapshot treeish without pipelines
TREEISH=''
for f in "${CATALYST_DIR}/snapshots/"*.sqfs; do
  [[ -f "${f}" ]] || continue
  base=$(basename "${f}")
  TREEISH="${base#gentoo-}"
  TREEISH="${TREEISH%.sqfs}"
  break
done

if [[ -z "${TREEISH}" ]]; then
  echo "ERROR: Could not find Portage snapshot in ${CATALYST_DIR}/snapshots/"
  ls -la "${CATALYST_DIR}/snapshots/" || true
  exit 1
fi
echo "Portage snapshot: ${TREEISH}"

# ── Step 3: livecd-stage1 ────────────────────────────────────────────────────
log "Running livecd-stage1"
fill_spec "${SPECS_DIR}/livecd-stage1.spec" "/tmp/anthoros-stage1.spec"
catalyst --configs "${CATALYST_CONF}" -f /tmp/anthoros-stage1.spec

# ── Step 4: livecd-stage2 ────────────────────────────────────────────────────
log "Running livecd-stage2 (kernel + ISO)"
fill_spec "${SPECS_DIR}/livecd-stage2.spec" "/tmp/anthoros-stage2.spec"
catalyst --configs "${CATALYST_CONF}" -f /tmp/anthoros-stage2.spec

# ── Step 5: Collect outputs ───────────────────────────────────────────────────
log "Collecting outputs"

ISO_SRC="${CATALYST_DIR}/builds/anthoros/anthoros-amd64-${VERSION}.iso"
ISO_OUT="${OUTPUT_DIR}/anthoros-amd64-${VERSION}.iso"
TARBALL_OUT="${OUTPUT_DIR}/anthoros-stage3-amd64-${VERSION}.tar.xz"

cp "${ISO_SRC}" "${ISO_OUT}"
cp "${STAGE3_DEST}" "${TARBALL_OUT}"

pushd "${OUTPUT_DIR}" > /dev/null
sha256sum "$(basename "${ISO_OUT}")"     > "$(basename "${ISO_OUT}").sha256"
sha256sum "$(basename "${TARBALL_OUT}")" > "$(basename "${TARBALL_OUT}").sha256"
popd > /dev/null

echo ""
echo "Build complete. Outputs:"
ls -lh "${OUTPUT_DIR}/"
