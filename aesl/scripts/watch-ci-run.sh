#!/usr/bin/env bash
# Watch one GitHub Actions run without streaming build logs.
#
# Usage: aesl/scripts/watch-ci-run.sh RUN_ID [INTERVAL_SECONDS]
# The command exits with the run's terminal status.
set -euo pipefail

readonly REPOSITORY="${AESL_GITHUB_REPOSITORY:-active-esl/android_vendor_waydroid}"
readonly RUN_ID="${1:?usage: $0 RUN_ID [INTERVAL_SECONDS]}"
readonly INTERVAL_SECONDS="${2:-300}"

if ! [[ "$INTERVAL_SECONDS" =~ ^[0-9]+$ ]] || (( INTERVAL_SECONDS < 300 )); then
    echo "error: interval must be an integer of at least 300 seconds" >&2
    exit 2
fi

command -v gh >/dev/null 2>&1 || {
    echo "error: GitHub CLI (gh) is required" >&2
    exit 127
}

exec gh run watch "$RUN_ID" \
    --repo "$REPOSITORY" \
    --interval "$INTERVAL_SECONDS" \
    --exit-status
