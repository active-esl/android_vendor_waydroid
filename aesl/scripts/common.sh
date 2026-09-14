#!/usr/bin/env bash
set -euo pipefail

# Consumed by scripts which source this file.
# shellcheck disable=SC2034
readonly AESL_LINEAGE_BRANCH="lineage-20.0"
# shellcheck disable=SC2034
readonly AESL_MEMORY_PROFILE="${AESL_MEMORY_PROFILE:-standard}"
case "${AESL_MEMORY_PROFILE}" in
    standard) default_lunch_target=lineage_waydroid_arm64-userdebug ;;
    2gb) default_lunch_target=lineage_waydroid_aesl_2gb_arm64_only-userdebug ;;
    *) echo "error: AESL_MEMORY_PROFILE must be standard or 2gb" >&2; exit 1 ;;
esac
# shellcheck disable=SC2034
readonly AESL_LUNCH_TARGET="${AESL_LUNCH_TARGET:-${default_lunch_target}}"

die() {
    echo "error: $*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}
