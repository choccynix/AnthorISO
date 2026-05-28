#!/usr/bin/env bash
# build.sh — AnthorOS build orchestrator
# Usage: ./build.sh [step]
#   step: fetch | unpack | rebrand | packages | iso | all (default: all)
set -euo pipefail
trap "" PIPE

export WORK_DIR="${WORK_DIR:-/build/anthoros}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEP="${1:-all}"

run_step() {
  local script="${SCRIPT_DIR}/${1}"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Running: ${1}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "${script}"
}

cleanup_mounts() {
  local rootfs="${WORK_DIR}/rootfs"
  [[ ! -d "${rootfs}" ]] && return 0
  local did_umount=false
  for mnt in proc sys dev run; do
    if mountpoint -q "${rootfs}/${mnt}" 2>/dev/null; then
      did_umount=true
      umount -R "${rootfs}/${mnt}" 2>/dev/null || true
    fi
  done
  ${did_umount} && echo "[build] Mounts cleaned up."
}

trap cleanup_mounts EXIT

mkdir -p "${WORK_DIR}"

case "${STEP}" in
  fetch)    run_step 01-fetch.sh ;;
  unpack)   run_step 02-unpack.sh ;;
  rebrand)  run_step 03-rebrand.sh ;;
  packages) run_step 04-packages.sh ;;
  iso)      run_step 05-iso.sh ;;
  all)
    run_step 01-fetch.sh
    run_step 02-unpack.sh
    run_step 03-rebrand.sh
    run_step 04-packages.sh
    run_step 05-iso.sh
    ;;
  *)
    echo "Usage: $0 [fetch|unpack|rebrand|packages|iso|all]"
    exit 1
    ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  AnthorOS build complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
