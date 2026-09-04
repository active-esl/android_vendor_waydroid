#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
# shellcheck disable=SC1091
source "${script_dir}/common.sh"

require_command repo
require_command git

android_dir="${ANDROID_WORKSPACE:-${repo_root}/.android-workspace}"
mkdir -p "${android_dir}"
cd "${android_dir}"

repo init -u https://github.com/LineageOS/android.git \
    -b "${AESL_LINEAGE_BRANCH}" --git-lfs
repo sync -c --no-tags build/make

rm -rf .repo/local_manifests
mkdir -p .repo/local_manifests
cp "${repo_root}"/manifest_scripts/manifests-33/*.xml .repo/local_manifests/

# The fork is the authoritative vendor/extra project for AESL releases.
sed -i \
    -e 's#name="WayDroid/android_vendor_waydroid"#name="active-esl/android_vendor_waydroid"#' \
    -e "s#path=\"vendor/extra\" name=\"active-esl/android_vendor_waydroid\" remote=\"ghub\" revision=\"refs/heads/lineage-20\"#path=\"vendor/extra\" name=\"active-esl/android_vendor_waydroid\" remote=\"ghub\" revision=\"${AESL_VENDOR_REVISION:?set AESL_VENDOR_REVISION to the reviewed fork commit}\"#" \
    .repo/local_manifests/02-waydroid.xml

repo sync -c --no-tags -j"${JOBS:-8}"
repo manifest -r -o "${LOCK_OUTPUT:-${repo_root}/source-manifest.xml}"
