#!/usr/bin/env python3
"""Inventory Waydroid SELinux bypass patches and gate production use."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


BLOCKING_SUBJECT = re.compile(
    r"(?i)(disable.*selinux|without selinux|ignore selinux|skip selinux|"
    r"drop selinux|never set.*security_ctx|suppress selinux|"
    r"remove conflicting selinux labels)"
)


def detected_patches(root: Path) -> set[str]:
    detected: set[str] = set()
    patch_root = root / "waydroid-patches" / "base-patches-36"
    for path in sorted(patch_root.rglob("*.patch")):
        subject = ""
        with path.open(encoding="utf-8", errors="replace") as source:
            for line in source:
                if line.startswith("Subject:"):
                    subject = line
                    break
        if BLOCKING_SUBJECT.search(subject):
            detected.add(path.relative_to(root).as_posix())
    return detected


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--production", action="store_true", help="also require an accepted risk decision"
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    decision_path = root / "security" / "selinux-runtime-exception.json"
    decision = json.loads(decision_path.read_text(encoding="utf-8"))

    detected = detected_patches(root)
    inventoried = set(decision.get("patches", []))
    missing = sorted(detected - inventoried)
    stale = sorted(inventoried - detected)
    if missing or stale:
        if missing:
            print("Uninventoried SELinux bypass patches:", *missing, sep="\n  ", file=sys.stderr)
        if stale:
            print("Stale SELinux exception entries:", *stale, sep="\n  ", file=sys.stderr)
        return 1

    if not detected:
        print("PASS: no runtime SELinux bypass patch subjects detected")
        return 0

    print(f"INVENTORIED: {len(detected)} runtime SELinux bypass/suppression patches")
    if not args.production:
        return 0

    required = ("risk_id", "owner", "approved_by", "approved_at", "review_by")
    if decision.get("status") != "accepted" or any(not decision.get(key) for key in required):
        print(
            "BLOCKED: runtime SELinux is bypassed and the exception has not been formally accepted",
            file=sys.stderr,
        )
        return 1
    controls = decision.get("compensating_controls", [])
    if len(controls) < 3:
        print("BLOCKED: at least three documented compensating controls are required", file=sys.stderr)
        return 1
    print(f"PASS: accepted runtime SELinux exception {decision['risk_id']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
