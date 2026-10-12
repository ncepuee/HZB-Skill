# Contributing to HZB-Skill

Thanks for helping improve the skills collection. Public visibility does not grant permission to copy, adapt, or redistribute project-authored content; see [LICENSE](LICENSE). Contributions must be your own work or submitted with permission from the relevant rights holder. Third-party materials remain under their original terms.

## Propose a change

1. Search existing Issues and open an issue for a substantial change.
2. Create a short-lived branch from `main`, such as `feat/<name>`, `fix/<name>`, `docs/<name>`, or `chore/<name>`.
3. Keep the diff focused. Do not include credentials, personal paths, private network details, logs, or unrelated generated files.
4. Run `python scripts/repository_check.py` and review the full diff.
5. Open a pull request to `main`, explain the purpose and verification, and complete the checklist.
6. Merge with squash after CI passes and review is complete.

Do not edit a published release tag. User-visible changes should be recorded under `Unreleased` in [CHANGELOG.md](CHANGELOG.md); a maintainer handles versioning and releases separately.

## Skill content requirements

- Keep each skill self-contained, actionable, and explicit about safety boundaries.
- Remove personal absolute paths, real credentials, private hostnames/IP addresses, and user-specific logs.
- Cite authoritative documentation where claims depend on product behavior or standards.
- Preserve third-party license and attribution requirements; do not imply that this repository relicenses third-party material.
- Keep the directory name and README skill catalog entry synchronized.
