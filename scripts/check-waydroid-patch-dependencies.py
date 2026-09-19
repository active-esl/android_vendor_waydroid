#!/usr/bin/env python3
"""Validate SDK 36 patch dependencies against a manifest and source checkout."""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import xml.etree.ElementTree as ET


def requirements_from(path: pathlib.Path) -> dict[str, str]:
    required: dict[str, str] = {}
    for line_number, raw_line in enumerate(path.read_text().splitlines(), 1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 2 or not all(fields):
            raise ValueError(f"invalid requirement at {path}:{line_number}")
        project, revision = fields
        if project in required:
            raise ValueError(f"duplicate required project: {project}")
        required[project] = revision
    if not required:
        raise ValueError(f"no patch dependencies declared in {path}")
    return required


def manifest_projects(path: pathlib.Path) -> dict[str, ET.Element]:
    projects: dict[str, ET.Element] = {}
    for project in ET.parse(path).getroot().findall("project"):
        project_path = project.get("path") or project.get("name")
        if project_path in projects:
            raise ValueError(f"duplicate manifest project path: {project_path}")
        projects[project_path] = project
    return projects


def git(project: pathlib.Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(project), *args],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise ValueError(f"required patch dependency is not a Git checkout: {project}")
    return result.stdout.strip()


def validate(
    manifest: pathlib.Path,
    requirements: pathlib.Path,
    source_root: pathlib.Path | None,
) -> None:
    required = requirements_from(requirements)
    projects = manifest_projects(manifest)
    for project_path, required_revision in required.items():
        project = projects.get(project_path)
        if project is None:
            raise ValueError(f"required project is absent from manifest: {project_path}")
        manifest_revision = project.get("revision", "")
        if manifest_revision != required_revision:
            raise ValueError(
                f"manifest revision mismatch: {project_path} is {manifest_revision}, "
                f"expected {required_revision}"
            )
        if source_root is None:
            continue
        checkout = source_root / project_path
        actual_revision = git(checkout, "rev-parse", "HEAD")
        if actual_revision != required_revision:
            raise ValueError(
                f"checkout revision mismatch: {project_path} is {actual_revision}, "
                f"expected {required_revision}"
            )
        if git(checkout, "status", "--porcelain=v1", "--untracked-files=all"):
            raise ValueError(f"required patch dependency is dirty: {project_path}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=pathlib.Path, required=True)
    parser.add_argument("--requirements", type=pathlib.Path, required=True)
    parser.add_argument("--source-root", type=pathlib.Path)
    args = parser.parse_args()
    try:
        validate(args.manifest, args.requirements, args.source_root)
    except (OSError, ValueError, ET.ParseError) as error:
        parser.exit(1, f"{error}\n")
    print("Waydroid patch dependencies valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
