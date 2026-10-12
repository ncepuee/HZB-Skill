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
README_ZH = ROOT / "README.zh-CN.md"
VERSION = ROOT / "VERSION"
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
readme_zh = README_ZH.read_text(encoding="utf-8")
version = VERSION.read_text(encoding="utf-8").strip()
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    fail("VERSION must contain one semantic version such as 1.7.0")

release_match = re.search(r"Current released version:\s*\[`v([^`]+)`\]", readme)
release_match_zh = re.search(r"当前发布版本：\[`v([^`]+)`\]", readme_zh)
if (
    not release_match
    or release_match.group(1) != version
    or not release_match_zh
    or release_match_zh.group(1) != version
):
    fail("README current released version does not match VERSION in both languages")
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
if "actions/workflows/ci.yml/badge.svg" not in readme_zh:
    fail("Chinese README CI badge does not point to the repository CI workflow")
if "GPT--6-Agent_used%40GPT--6--Luna" not in readme or "GPT--6-Agent_used%40GPT--6--Luna" not in readme_zh:
    fail("README model attribution badge must identify GPT-6-Luna in both languages")
if "logo=openai" not in readme or "logo=openai" not in readme_zh:
    fail("README GPT model badge must use the OpenAI logo in both languages")
codex_badge_urls = re.findall(r"https://img\.shields\.io/badge/Codex-[^\"\s]+", readme + readme_zh)
if len(codex_badge_urls) != 2 or any("data:image/svg%2bxml;base64," not in url for url in codex_badge_urls):
    fail("Both README Codex badges must use the Codex brand icon, not the OpenAI logo")

skill_dirs = {
    path.name
    for path in ROOT.iterdir()
    if path.is_dir() and (path / "SKILL.md").is_file()
}
catalog_match = re.search(
    r"^## Skills \(\d+\)\s*\n(?P<table>.*?)(?=^## )",
    readme,
    flags=re.MULTILINE | re.DOTALL,
)
if not catalog_match:
    fail("README skill catalog section is missing")
catalog_names = set(
    re.findall(r"^\| `([^`]+)` \|", catalog_match.group("table"), flags=re.MULTILINE)
)
catalog_match_zh = re.search(
    r"^## 技能目录（\d+ 项）\s*\n(?P<table>.*?)(?=^## )",
    readme_zh,
    flags=re.MULTILINE | re.DOTALL,
)
if not catalog_match_zh:
    fail("Chinese README skill catalog section is missing")
catalog_names_zh = set(
    re.findall(r"^\| `([^`]+)` \|", catalog_match_zh.group("table"), flags=re.MULTILINE)
)
if skill_dirs != catalog_names or skill_dirs != catalog_names_zh:
    fail(
        "README skill catalogs differ from skill directories; "
        f"English missing={sorted(skill_dirs - catalog_names)}, "
        f"English stale={sorted(catalog_names - skill_dirs)}, "
        f"Chinese missing={sorted(skill_dirs - catalog_names_zh)}, "
        f"Chinese stale={sorted(catalog_names_zh - skill_dirs)}"
    )

count_match = re.search(r"^## Skills \((\d+)\)", readme, flags=re.MULTILINE)
count_match_zh = re.search(r"^## 技能目录（(\d+) 项）", readme_zh, flags=re.MULTILINE)
if (
    not count_match
    or int(count_match.group(1)) != len(skill_dirs)
    or not count_match_zh
    or int(count_match_zh.group(1)) != len(skill_dirs)
):
    fail("English and Chinese README skill counts must match the discovered skill directories")

for language_readme, language_name, language_link in (
    (readme, "English", "README.zh-CN.md"),
    (readme_zh, "中文", "README.md"),
):
    if language_link not in language_readme or language_name not in language_readme:
        fail(f"README language switch is missing from {language_link}")
    if re.search(r"^## (?:Simulink Connection Integrity|Upgrade Legacy Simulink Models)$", language_readme, re.MULTILINE):
        fail("Individual skill deep-dives belong in their skill directories, not the root README")

home_directory_segment = "Us" + "ers"
private_patterns = (
    rf"(?i)\b[A-Z]:\\{home_directory_segment}\\[^\\\s<>\"']+",
    r"\b(?:10\.(?:\d{1,3}\.){2}\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.(?:\d{1,3}\.)\d{1,3}|192\.168\.(?:\d{1,3}\.)\d{1,3})\b",
    r"(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.(?!example\.com\b|test\.invalid\b)[A-Z]{2,}\b",
    r"\bgh[pousr]_[A-Za-z0-9_]{30,}\b",
    r"\bsk-[A-Za-z0-9_-]{24,}\b",
    r"\bAKIA[0-9A-Z]{16}\b",
    r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b",
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

    # Try strict UTF-8 decoding for every resource, independent of extension. Binary resources
    # naturally fail decoding (or contain NUL bytes) and are skipped.
    for resource in (ROOT / skill_dir).rglob("*"):
        if not resource.is_file():
            continue
        try:
            with resource.open("rb") as stream:
                resource_bytes = stream.read()
            if b"\0" in resource_bytes:
                continue
            resource_text = resource_bytes.decode("utf-8")
        except UnicodeDecodeError:
            continue
        except OSError as error:
            fail(f"Could not read {resource.relative_to(ROOT)}: {error}")
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
