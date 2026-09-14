#!/usr/bin/env python3
"""Prevent Android R13 CI from being presented as an unversioned image build."""

from __future__ import annotations

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def require_labels(path: str, labels: tuple[str, ...]) -> None:
    workflow = (REPO_ROOT / path).read_text(encoding="utf-8")
    for label in labels:
        assert label in workflow, f"{path}: missing Android R13 CI identity: {label}"


def main() -> None:
    require_labels(
        ".github/workflows/build-images.yml",
        (
            "name: Build Android R13 / LineageOS 20 Waydroid images",
            "run-name: Android R13 / LineageOS 20 - ARM64",
            "name: Android R13 / LineageOS 20 - ARM64",
            "name: aesl-android-r13-lineage-20-arm64-${{ github.run_id }}",
        ),
    )
    require_labels(
        ".github/workflows/build-images-x86_64.yml",
        (
            "name: Build Android R13 / LineageOS 20 x86_64 test images",
            "run-name: Android R13 / LineageOS 20 - x86_64",
            "name: Android R13 / LineageOS 20 - x86_64 test",
            "name: aesl-android-r13-lineage-20-x86_64-${{ github.run_id }}",
        ),
    )
    require_labels(
        ".github/workflows/resolve-source-lock.yml",
        (
            "name: Resolve Android R13 / LineageOS 20 source lock",
            "run-name: Resolve Android R13 / LineageOS 20 source lock",
            "name: android-r13-lineage-20-source-lock-${{ github.sha }}",
        ),
    )
    print("Android R13 CI release labels valid")


if __name__ == "__main__":
    main()
