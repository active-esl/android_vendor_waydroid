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
require_command zip
require_command meson
require_command ninja
require_command glslangValidator
require_command bison
require_command flex

# Mesa's generated sources use these modules through the runner's host Python.
# Check them up front instead of discovering missing modules during Meson setup.
if ! python3 -c 'import mako, pycparser' >/dev/null 2>&1; then
    die 'Python Mako and pycparser modules are required by locked Mesa (install python3-mako python3-pycparser)'
fi

# The locked Mesa source requires Meson >= 1.4.  Debian 12's stock package is
# older, so reject it before the hour-long Android build reaches Mesa.
if ! python3 - "$(meson --version)" <<'PY'
import sys

try:
    version = tuple(int(part) for part in sys.argv[1].split(".")[:2])
except ValueError:
    raise SystemExit(1)
raise SystemExit(0 if version >= (1, 4) else 1)
PY
then
    die "Meson >= 1.4 is required by the locked Mesa source"
fi

if ! python3 - "$(glslangValidator --version)" <<'PY'
import re
import sys

match = re.search(r"Glslang Version:\s*\d+:(\d+)\.(\d+)", sys.argv[1])
if match is None:
    raise SystemExit(1)
version = tuple(int(part) for part in match.groups())
raise SystemExit(0 if version >= (12, 2) else 1)
PY
then
    die "glslangValidator >= 12.2 is required by the locked Mesa source"
fi

# Android 13's pinned host Clang is linked against the legacy ncurses ABI.
# Check it before source sync/build rather than failing deep in Ninja.
if ! ldconfig -p 2>/dev/null | grep -q 'libncurses\.so\.5'; then
    die 'libncurses.so.5 is required; install the libncurses5 compatibility package'
fi

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

apply_checked_patch() {
    local project_dir="$1"
    local patch_file="$2"
    local description="$3"

    [[ -s "${patch_file}" ]] || die "${description} patch missing: ${patch_file}"
    # Some ordered Waydroid patches add source files which remain untracked in
    # the persistent checkout after repo sync. Use the working tree rather
    # than Git's index when checking/applying: the next patch can then be
    # recognised as already applied on a repeat CI run.
    if git -C "${project_dir}" apply --no-index --check "${patch_file}"; then
        git -C "${project_dir}" apply --no-index "${patch_file}"
    elif git -C "${project_dir}" apply --no-index --reverse --check "${patch_file}"; then
        echo "${description} patch already applied"
    else
        die "${description} source does not match the reviewed patch"
    fi
}

# Mesa 26 is built with Waydroid's pinned host helpers.  This upstream,
# build-tools-only patch exposes the already locked prebuilts/mesa-tools
# binaries to the Android build PATH.  It does not alter the vanilla Android
# framework/core source lane.
apply_checked_patch \
    prebuilts/build-tools \
    "${repo_root}/waydroid-patches/base-patches-33/prebuilts/build-tools/0001-Add-prebuilt-mesa-tools-to-PATH.patch" \
    "Waydroid Mesa build-tools"

mesa_tools_path="${android_dir}/prebuilts/build-tools/path/linux-x86"
for mesa_tool in mesa_clc vtn_bindgen2 asahi_clc panfrost_compile; do
    [[ -x "${mesa_tools_path}/${mesa_tool}" ]] || \
        die "locked Waydroid Mesa helper missing or not executable: ${mesa_tool}"
done
# Make the build-tool path explicit.  The patched symlinks are provided by the
# locked source tree; exporting this here also makes nested Meson invocations
# deterministic instead of relying on an ambient runner PATH.
export PATH="${mesa_tools_path}:${PATH}"

# Waydroid's legacy gatekeeper HAL is vendor hardware code. Android 13 keeps
# SizedBuffer ownership private, so apply the reviewed HAL-only adaptation
# after each force-checkout. The locked LineageOS framework remains untouched.
apply_checked_patch \
    hardware/waydroid \
    "${repo_root}/aesl/patches/0001-waydroid-gatekeeper-android13-sizedbuffer.patch" \
    "Waydroid gatekeeper compatibility"
apply_checked_patch \
    external/wayland-protocols \
    "${repo_root}/waydroid-patches/base-patches-33/external/wayland-protocols/0001-staging-Add-fractional-scale.patch" \
    "Waydroid fractional-scale protocol"

# The Waydroid vendor init services use its dynamic `host` UID. Android 13's
# init verifier shares DecodeUid with init itself, so this minimal upstream
# system/core patch is required for both a valid image and verification of its
# vendor init script. Keep the rest of Waydroid's framework/core stack opt-in.
apply_checked_patch \
    system/core \
    "${repo_root}/waydroid-patches/base-patches-33/system/core/0005-init-Define-host-user.patch" \
    "Waydroid init host UID"
apply_checked_patch \
    system/core \
    "${repo_root}/waydroid-patches/base-patches-33/system/core/0004-libsync-Add-sw_sync-symbols-to-map.patch" \
    "Waydroid libsync ABI"
apply_checked_patch \
    lineage-sdk \
    "${repo_root}/waydroid-patches/base-patches-33/lineage-sdk/0001-sdk-Introduce-WayDroid-Service.patch" \
    "Waydroid Lineage SDK service"
apply_checked_patch \
    lineage-sdk \
    "${repo_root}/waydroid-patches/base-patches-33/lineage-sdk/0002-WayDroidHardware-Support-64-bit-timestamps-in-upgrad.patch" \
    "Waydroid Lineage SDK timestamp API"

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
