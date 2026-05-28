#!/usr/bin/env bash
# 01-fetch.sh — Download the latest Gentoo stage3 musl+llvm+openrc tarball
set -euo pipefail

MIRROR="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-musl-llvm-openrc"
WORK_DIR="${WORK_DIR:-/build/anthoros}"
FETCH_DIR="${WORK_DIR}/fetch"

mkdir -p "${FETCH_DIR}"

echo "[01-fetch] Fetching latest stage3 file list..."
FILELIST="${FETCH_DIR}/latest-stage3.txt"
curl -fsSL -o "${FILELIST}" "${MIRROR}/latest-stage3-amd64-musl-llvm-openrc.txt"
LATEST_FILE=$(grep -v '^#' "${FILELIST}" | awk 'NF {print $1}' | head -n1)

if [[ -z "${LATEST_FILE}" ]]; then
  echo "[01-fetch] ERROR: Could not determine latest stage3 filename."
  exit 1
fi

TARBALL_NAME=$(basename "${LATEST_FILE}")
TARBALL_URL="${MIRROR}/${TARBALL_NAME}"
DIGEST_URL="${TARBALL_URL}.sha256"

echo "[01-fetch] Latest stage3: ${TARBALL_NAME}"
echo "[01-fetch] Downloading tarball..."
curl -fsSL --progress-bar -o "${FETCH_DIR}/${TARBALL_NAME}" "${TARBALL_URL}"

echo "[01-fetch] Downloading checksum..."
curl -fsSL -o "${FETCH_DIR}/${TARBALL_NAME}.sha256" "${DIGEST_URL}"

echo "[01-fetch] Verifying checksum..."
pushd "${FETCH_DIR}" > /dev/null
sha256sum -c "${TARBALL_NAME}.sha256" --ignore-missing
popd > /dev/null

echo "[01-fetch] Stage3 fetched and verified: ${FETCH_DIR}/${TARBALL_NAME}"

# Export for next scripts
echo "${FETCH_DIR}/${TARBALL_NAME}" > "${WORK_DIR}/.tarball_path"
echo "[01-fetch] Done."
