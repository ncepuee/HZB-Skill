#!/usr/bin/env python3
"""Validate the HZB-Skill catalog and public-repository privacy baseline."""

from __future__ import annotations

import os
import re
import sys
from html.parser import HTMLParser
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
README = ROOT / "README.md"
VERSION = ROOT / "VERSION"
TEXT_SUFFIXES = {
    ".html",
    ".js",
    ".json",
    ".m",
    ".md",
    ".ps1",
    ".py",
    ".sh",
    ".toml",
    ".txt",
    ".ts",
    ".xml",
    ".yaml",
    ".yml",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


class BadgeParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.image_alts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() == "img":
            attributes = dict(attrs)
            if attributes.get("src", "").startswith(("https://img.shields.io/", "https://github.com/")):
                self.image_alts.append(attributes.get("alt") or "")


readme = README.read_text(encoding="utf-8")
version = VERSION.read_text(encoding="utf-8").strip()
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    fail("VERSION must contain one semantic version such as 1.7.0")

release_match = re.search(r"Current released version:\s*\[`v([^`]+)`\]", readme)
if not release_match or release_match.group(1) != version:
    fail("README current released version does not match VERSION")
if re.search(r"Agent_used%40v[^-/&\"]+", readme):
    version_badge = re.search(r"Agent_used%40v([^-/&\"]+)", readme)
    if not version_badge or version_badge.group(1) != version:
        fail("README agent attribution badge version does not match VERSION")

git_ref = os.environ.get("GITHUB_REF", "")
if git_ref.startswith("refs/tags/v") and git_ref.removeprefix("refs/tags/v") != version:
    fail("Git tag version does not match VERSION")

changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
if not re.search(rf"^## \[{re.escape(version)}\]", changelog, flags=re.MULTILINE):
    fail("CHANGELOG has no section for VERSION")

badges = BadgeParser()
badges.feed(readme.split("## Skills", 1)[0])
if len(badges.image_alts) < 5 or any(not alt.strip() for alt in badges.image_alts):
    fail("README must include the source trio and at least two factual status badges")
if "github/stars/ncepuee/HZB-Skill" not in readme:
    fail("Public repository GitHub Stars badge is missing or targets another repository")
if "github/v/release/ncepuee/HZB-Skill" not in readme:
    fail("README release badge is missing")
if "actions/workflows/ci.yml/badge.svg" not in readme:
    fail("README CI badge does not point to the repository CI workflow")

skill_dirs = {
    path.name
    for path in ROOT.iterdir()
    if path.is_dir() and (path / "SKILL.md").is_file()
}
catalog_match = re.search(
    r"^## Skills \([^\n]+\)\s*\n(?P<table>.*?)(?=^## )",
    readme,
    flags=re.MULTILINE | re.DOTALL,
)
if not catalog_match:
    fail("README skill catalog section is missing")
catalog_names = set(
    re.findall(r"^\| `([^`]+)` \|", catalog_match.group("table"), flags=re.MULTILINE)
)
if skill_dirs != catalog_names:
    fail(
        "README skill catalog differs from skill directories; "
        f"missing={sorted(skill_dirs - catalog_names)}, "
        f"stale={sorted(catalog_names - skill_dirs)}"
    )

count_match = re.search(r"^## Skills \((\d+) 个\)", readme, flags=re.MULTILINE)
if not count_match or int(count_match.group(1)) != len(skill_dirs):
    fail("README skill count does not match the discovered skill directories")

private_patterns = (
    r"(?i)\b[A-Z]:\\Users\\(?:hzb|hzblaptop)(?:\\|$)",
    r"(?i)\bG:\\(?:Obnotes|RTWorkspace_24|Project_HZB|PythonProject|HZB-Skill)(?:\\|$)",
    r"\b192\.168\.1\.(?:12|101|102)\b",
    r"(?i)\bzhenbin_huang@163\.com\b",
    r"\bgh[pousr]_[A-Za-z0-9_]{30,}\b",
    r"\bsk-[A-Za-z0-9_-]{24,}\b",
)

for skill_dir in sorted(skill_dirs):
    skill_file = ROOT / skill_dir / "SKILL.md"
    content = skill_file.read_text(encoding="utf-8")
    if not content.startswith("---\n"):
        fail(f"{skill_file.relative_to(ROOT)} has no YAML front matter")
    sections = content.split("---\n", 2)
    if len(sections) < 3:
        fail(f"{skill_file.relative_to(ROOT)} has unterminated YAML front matter")
    front_matter = sections[1]
    if not re.search(r"^name:\s*[^\s]+\s*$", front_matter, flags=re.MULTILINE):
        fail(f"{skill_file.relative_to(ROOT)} has no front-matter name")

    # Scan all text-based skill resources, not just the entrypoint. Generic examples remain valid.
    for resource in (ROOT / skill_dir).rglob("*"):
        if not resource.is_file() or resource.suffix.lower() not in TEXT_SUFFIXES:
            continue
        try:
            resource_text = resource.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for pattern in private_patterns:
            if re.search(pattern, resource_text):
                fail(
                    "Possible private path, identifier, or credential in "
                    f"{resource.relative_to(ROOT)}"
                )

if not (ROOT / "LICENSE").is_file():
    fail("LICENSE is missing")
if not (ROOT / ".github" / "workflows" / "ci.yml").is_file():
    fail("GitHub Actions CI workflow is missing")
if not (ROOT / "CHANGELOG.md").is_file():
    fail("CHANGELOG.md is missing")

print(f"OK: {len(skill_dirs)} skills, version {version}, README catalog, metadata, and privacy patterns")
