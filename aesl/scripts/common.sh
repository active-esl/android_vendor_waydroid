#!/usr/bin/env bash
set -euo pipefail

# Consumed by scripts which source this file.
# shellcheck disable=SC2034
readonly AESL_LINEAGE_BRANCH="lineage-20.0"
# shellcheck disable=SC2034
readonly AESL_LUNCH_TARGET="lineage_waydroid_arm64-userdebug"

die() {
    echo "error: $*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}
