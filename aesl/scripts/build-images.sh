#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
# shellcheck disable=SC1091
source "${script_dir}/common.sh"

export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(git -C "${repo_root}" show -s --format=%ct HEAD)}"

require_command repo
require_command git
require_command sha256sum
require_command python3

lock_file="${SOURCE_LOCK:-${repo_root}/aesl/manifests/lineage-20-lock.xml}"
[[ -s "${lock_file}" ]] || die "reviewed source lock missing: ${lock_file}"

android_dir="${ANDROID_WORKSPACE:-${repo_root}/.android-workspace}"
output_dir="${OUTPUT_DIR:-${repo_root}/out-aesl}"
mkdir -p "${android_dir}" "${output_dir}"

# LineageOS 20 still invokes `python` in a few host tools. The runner provides
# Python 3 as `python3`; provide a workspace-local compatibility name without
# changing the runner's system Python configuration.
if ! command -v python >/dev/null 2>&1; then
    python_shim_dir="${android_dir}/.aesl-bin"
    mkdir -p "${python_shim_dir}"
    ln -sf "$(command -v python3)" "${python_shim_dir}/python"
    export PATH="${python_shim_dir}:${PATH}"
fi
cd "${android_dir}"

# The reviewed lock is already a complete flattened manifest. Present it to
# repo through a local Git checkout: standalone XML mode leaves .repo/manifests
# without Git metadata, causing repo to emit recovery errors on every run.
manifest_dir="${android_dir}/.aesl-manifest"
rm -rf "${manifest_dir}"
git init --quiet "${manifest_dir}"
git -C "${manifest_dir}" config user.name "AESL CI"
git -C "${manifest_dir}" config user.email "ci@active-esl.local"
install -m 0644 "${lock_file}" "${manifest_dir}/default.xml"
git -C "${manifest_dir}" add default.xml
git -C "${manifest_dir}" commit --quiet -m "AESL reviewed source lock"

if [[ -d .repo ]]; then
    # Reset only manifest metadata; retain project objects and checked-out
    # sources in the persistent workspace.
    rm -rf .repo/local_manifests .repo/manifests .repo/manifests.git
    rm -f .repo/manifest.xml
fi
repo init -u "file://${manifest_dir}" -m default.xml --git-lfs
GIT_CONFIG_COUNT=1 \
    GIT_CONFIG_KEY_0=http.version \
    GIT_CONFIG_VALUE_0=HTTP/1.1 \
    repo sync -c --no-tags --force-checkout -j"${JOBS:-8}"

# Android's generated environment and its lunch/m helpers read optional shell
# variables without defaults. Keep nounset disabled for their complete lifecycle.
# shellcheck disable=SC1091
set +u
source build/envsetup.sh

# This CI lane proves the reproducible vanilla LineageOS system image and the
# paired Waydroid vendor image.  The upstream patch stack changes framework and
# core Android sources; it is intentionally opt-in until it has been rebased
# and runtime-tested against this exact source lock.
if [[ "${AESL_APPLY_WAYDROID_PATCHES:-false}" == "true" ]]; then
    apply-waydroid-patches
fi
export TARGET_USE_MESA=true
lunch "${AESL_LUNCH_TARGET}"
m -j"${JOBS:-8}" systemimage vendorimage

install -m 0644 "${OUT}/system.img" "${output_dir}/system.img"
install -m 0644 "${OUT}/vendor.img" "${output_dir}/vendor.img"
cp "${lock_file}" "${output_dir}/source-manifest.xml"
(
    cd "${output_dir}"
    sha256sum system.img vendor.img source-manifest.xml > SHA256SUMS
)

python3 "${script_dir}/write-build-info.py" \
    --output "${output_dir}/build-info.json" \
    --source-lock "${output_dir}/source-manifest.xml" \
    --target "${AESL_LUNCH_TARGET}"

# Preserve Android's generated licence/provenance inputs where available.
find "${OUT}" -maxdepth 2 -type f \
    \( -name '*license*' -o -name 'installed-files*.txt' \) \
    -exec cp -t "${output_dir}" {} + 2>/dev/null || true
