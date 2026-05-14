# Feature Roadmap

Focused plan for the next Project Doctor Mini features after the initial public release.

## Goal

Make the plugin safer to run on real projects, easier to trust in CI, and more useful before export or release.

Keep the roadmap small and milestone-based so each step can ship independently.

## Milestone 1 - Finding Control

Status: Implemented.

Give users a way to manage noisy findings without weakening the scanner.

### Scope

- Add a baseline file for accepted findings.
- Add ignore patterns for folders, files, and finding IDs.
- Disable unused-file detection by default or clearly mark it as experimental.
- Keep unused-file results out of blocking CI until confidence improves.

### Proposed Files

- `project_doctor_baseline.json`
- `project_doctor_settings.cfg`

### Done Criteria

- A finding already present in the baseline can be hidden or marked accepted.
- Ignored paths are skipped consistently in editor and headless scans.
- Unused-file findings are visibly labeled `experimental` or disabled by default.
- README explains baseline and ignore behavior briefly.

## Milestone 2 - Editor UX And Reports

Status: Implemented.

Make the everyday editor workflow smoother and make reports look good in GitHub.

### Scope

- Add a plugin settings panel for thresholds, ignore patterns, and experimental checks.
- Add one-click open for generated Markdown and JSON reports.
- Improve Markdown report rendering with a summary table at the top.
- Group Markdown findings by severity.
- Use collapsible `<details>` sections for long finding lists.

### Done Criteria

- Users can change common scanner settings without editing source code.
- The dock can open the generated report file directly.
- Markdown reports render cleanly when viewed on GitHub.
- Large reports remain readable because each severity group can be collapsed.

## Milestone 3 - CI And PR Automation

Status: Implemented.

Make Project Doctor useful in pull requests, not only inside the editor.

### Scope

- Add a GitHub Action wrapper around the headless scanner.
- Upload Markdown and JSON reports as workflow artifacts.
- Add optional PR comment summary.
- Keep CI behavior configurable: report-only, warn, or fail on errors.

### Done Criteria

- A repository can enable the action with a short workflow snippet.
- PRs receive a compact summary with error, warning, and info counts.
- Full reports remain available as artifacts.
- The action can run without requiring the editor UI.

## Milestone 4 - Export And Asset Readiness

Status: Implemented.

Expand checks from general project hygiene into release readiness.

### Scope

- Add export profile readiness checks per platform.
- Detect missing export presets.
- Validate obvious platform export fields where possible.
- Add Godot import settings analysis.
- Flag risky import settings for textures/audio where practical.

### Done Criteria

- The scanner can explain whether export profiles exist and look complete.
- Findings mention the affected platform when relevant.
- Import setting warnings include a clear recommendation.
- Checks stay conservative to avoid noisy false positives.

## Milestone 5 - Fixtures, Tests, And Performance Signal

Status: Implemented.

Strengthen confidence in the scanner with real test projects and quality signals.

### Scope

- Add a sample/demo Godot project under `examples/`.
- Include intentional issues such as broken script references and an oversized texture.
- Use the sample project as an integration-test fixture.
- Add real scanner tests beyond the smoke test.
- Add a README performance note such as: `Scans a 500-file project in ~X seconds.`

### Done Criteria

- Users can try the plugin on the demo project before using it on their own project.
- Tests verify expected findings from known fixture projects.
- Scanner tests cover baseline, ignore patterns, broken paths, export presets, and experimental unused files.
- README includes a measured scan time from a realistic local or CI run.

## Suggested Order

1. Milestone 1 - Finding Control
2. Milestone 2 - Editor UX And Reports
3. Milestone 5 - Fixtures, Tests, And Performance Signal
4. Milestone 3 - CI And PR Automation
5. Milestone 4 - Export And Asset Readiness

This order reduces false positives first, then improves usability, then adds stronger automation and deeper checks.

## Current State

Milestones 1 through 5 are now implemented in the current release candidate. Future roadmap work can move to deeper dependency analysis, broader import heuristics, Asset Library packaging, and additional release-quality checks once the `0.2.0` line is tagged.

## Notes

- Treat `possibly_unused_file` as experimental until fixtures prove it is dependable.
- Keep settings shared between dock scans and headless scans.
- Keep the JSON schema stable so CI and PR comments can rely on it.
- Prefer small checks with clear recommendations over broad analysis that creates noisy reports.
