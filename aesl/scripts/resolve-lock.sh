#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
# shellcheck disable=SC1091
source "${script_dir}/common.sh"

require_command repo
require_command git

repo_sync_with_retries() {
    local attempt
    local max_attempts=4
    local sync_jobs="${JOBS:-8}"

    for attempt in $(seq 1 "${max_attempts}"); do
        echo "repo sync attempt ${attempt}/${max_attempts} with ${sync_jobs} network jobs"

        # Android source sync fans out into hundreds of Git fetches.  Force the
        # child Git processes to HTTP/1.1 because long-lived HTTP/2 streams have
        # repeatedly been reset by the source hosts on CT101.  Keep this config
        # scoped to the sync process rather than changing the runner account.
        if GIT_CONFIG_COUNT=1 \
            GIT_CONFIG_KEY_0=http.version \
            GIT_CONFIG_VALUE_0=HTTP/1.1 \
            repo sync -c --no-tags --fail-fast -j"${sync_jobs}" "$@"; then
            return 0
        fi

        if [ "${attempt}" -eq "${max_attempts}" ]; then
            echo "repo sync failed after ${max_attempts} attempts" >&2
            return 1
        fi

        if [ "${sync_jobs}" -gt 1 ]; then
            sync_jobs=$((sync_jobs / 2))
        fi

        echo "repo sync attempt ${attempt}/${max_attempts} failed; retaining downloaded objects and retrying with ${sync_jobs} network jobs" >&2
        sleep $((attempt * 15))
    done
}

android_dir="${ANDROID_WORKSPACE:-${repo_root}/.android-workspace}"
mkdir -p "${android_dir}"
cd "${android_dir}"

repo init -u https://github.com/LineageOS/android.git \
    -b "${AESL_LINEAGE_BRANCH}" --git-lfs
repo_sync_with_retries build/make

rm -rf .repo/local_manifests
mkdir -p .repo/local_manifests
cp "${repo_root}"/manifest_scripts/manifests-33/*.xml .repo/local_manifests/

# The fork is the authoritative vendor/extra project for AESL releases.
sed -i \
    -e 's#name="WayDroid/android_vendor_waydroid"#name="active-esl/android_vendor_waydroid"#' \
    -e "s#path=\"vendor/extra\" name=\"active-esl/android_vendor_waydroid\" remote=\"ghub\" revision=\"refs/heads/lineage-20\"#path=\"vendor/extra\" name=\"active-esl/android_vendor_waydroid\" remote=\"ghub\" revision=\"${AESL_VENDOR_REVISION:?set AESL_VENDOR_REVISION to the reviewed fork commit}\"#" \
    .repo/local_manifests/02-waydroid.xml

repo_sync_with_retries
repo manifest -r -o "${LOCK_OUTPUT:-${repo_root}/source-manifest.xml}"
