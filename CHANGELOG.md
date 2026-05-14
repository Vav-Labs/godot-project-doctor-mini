# Changelog

All notable changes to Godot Project Doctor Mini will be documented here.

This project follows a simple release-candidate versioning style while the plugin evolves toward broader public use.

## [Unreleased]

### Added

- No unreleased changes yet.

## [0.2.0] - 2026-05-14

### Added

- Shared scanner finding-control settings, baseline suppression, and experimental unused-file opt-in behavior.
- Dock settings UI, direct Markdown/JSON report buttons, and grouped GitHub-friendly Markdown reports.
- Reusable GitHub Actions automation with artifacts, CI modes, and optional PR comment summaries.
- Conservative export preset readiness checks and `.import` settings analysis.
- A standalone demo project plus dedicated scanner regression, integration, and benchmark scripts.

### Changed

- Smoke-test CI now runs smoke, scanner regression, demo integration, benchmark, and the canonical scan flow.
- Public release documentation now covers the demo project, reusable workflow, benchmark note, and release-candidate validation steps.

## [0.1.0] - 2026-05-13

### Initial Release

- Godot editor plugin registration.
- `Project Doctor` editor dock.
- One-click project scan.
- Markdown report writer.
- JSON report writer.
- Headless scan script.
- Smoke test script for report schema and writer validation.
- Basic checks for missing scripts, broken resource paths, large textures, scene node count, `_process()` usage, empty folders, possibly unused files, and missing export presets.

[Unreleased]: https://github.com/Vav-Labs/godot-project-doctor-mini/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Vav-Labs/godot-project-doctor-mini/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Vav-Labs/godot-project-doctor-mini/releases/tag/v0.1.0
