# Testing

Small repeatable test guide for Godot Project Doctor Mini.

## Goal

The purpose of this test flow is to verify that:

- the editor plugin loads,
- the dock scan works,
- the dock settings panel can save and reload shared scanner settings,
- the headless scan works,
- the reusable CI workflow can evaluate scan summaries in different modes,
- export preset readiness checks stay conservative and deterministic,
- import settings analysis catches obviously broken `.import` files,
- the report schema stays stable,
- the generated report files are written to `reports/`,
- finding control settings stay deterministic,
- Markdown reports keep the summary table and collapsible severity groups.

## Fastest Checks

Use these headless commands first:

Recommended order:

1. Run `godot --headless --path . --quit`.
2. Run `godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd`.
3. Run `godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_smoke_test.gd`.
4. Run `python .github/scripts/project_doctor_summary.py --report reports/project-doctor-report.json --mode report-only --artifact-name project-doctor-reports`.

## What Each Task Confirms

### Headless Project Validation

Confirms that the project opens headlessly without immediate startup errors.

### Headless Project Doctor Scan

Confirms that the scanner runs and writes:

- `reports/project-doctor-report.md`
- `reports/project-doctor-report.json`

It should fail only for tool/report write problems, not for normal warning or info findings.

### Project Doctor Smoke Test

Confirms that:

- the scanner returns the expected top-level report keys,
- summary keys exist,
- finding entries keep the expected schema,
- severities remain valid,
- both report writers successfully write output files,
- Markdown reports keep the summary table and ordered collapsible severity groups,
- markdown example docs do not produce broken-resource false positives,
- ignore patterns, ignored finding IDs, and baseline entries suppress findings deterministically,
- missing and malformed export preset files are handled conservatively,
- malformed and suspicious `.import` fixtures produce stable findings,
- experimental unused-file behavior stays opt-in.

### Project Doctor CI Summary Helper

Confirms that:

- the generated JSON report can be parsed outside Godot,
- CI mode evaluation stays deterministic for `report-only`, `warn`, and `fail-on-errors`,
- GitHub summary/comment markdown can be produced from the JSON report.

## Finding Control Checks

The default project config is stored in:

- `project_doctor_settings.cfg`
- `project_doctor_baseline.json`

Key behavior to verify:

- `ignored_path_patterns` skip folders and files consistently in dock and headless scans
- `ignored_finding_ids` remove matching findings from the visible report
- baseline entries suppress accepted findings before summary counts are calculated
- `possibly_unused_file` is disabled unless `enable_experimental_unused_files=true`

## Manual Editor Test

Use this when you want to verify the actual plugin UI.

1. Open the project in the Godot editor.
2. Go to `Project > Project Settings > Plugins`.
3. Confirm `Godot Project Doctor Mini` is enabled.
4. Open the `Project Doctor` dock on the right side.
5. Expand `Settings`.
6. Change one threshold value and add a temporary ignore pattern or finding ID.
7. Click `Save Settings`.
8. Click `Reload Settings` and confirm the saved values are restored from `project_doctor_settings.cfg`.
9. Click `Scan Project`.
10. Confirm the status text updates.
11. Confirm the summary values match the findings list.
12. Click `Open Reports Folder`.
13. Confirm the reports exist in `reports/`.
14. Click `Open Markdown Report` and `Open JSON Report`.
15. Confirm each button opens the generated report file directly.

## Manual Finding Checks

These are controlled checks for the main finding types.

### Missing Script

1. Add a temporary broken script reference in a test scene or resource.
2. Run a scan.
3. Confirm an `error` finding appears.
4. Restore the original file/reference.

### `_process()` Usage

1. Add a temporary `_process()` method to a script.
2. Run a scan.
3. Confirm an `info` finding appears.
4. Revert the test change.

### Large Texture

1. Add a texture larger than the current threshold.
2. Run a scan.
3. Confirm a `warning` finding appears.
4. Remove the temporary test asset.

### Export Presets Missing

1. Temporarily remove or rename `export_presets.cfg` if it exists.
2. Run a scan.
3. Confirm the export presets warning appears.
4. Restore the file.

### Export Preset Readiness

1. Create or edit a preset in `export_presets.cfg` with an obvious missing field such as an empty export path.
2. Run a scan.
3. Confirm the finding mentions the affected preset/platform in the message.
4. Restore a valid preset entry after the check.

### Import Settings Analysis

1. Temporarily break a `.import` file in a test area or create one that references a missing source asset.
2. Run a scan.
3. Confirm Project Doctor reports a focused import-settings warning instead of a generic parse failure only.
4. Reimport or restore the asset after the check.

### Documentation Asset Reference

1. Confirm the README references `docs/assets/project-doctor-dock.png`.
2. Run a scan.
3. Confirm the screenshot asset is not reported as `possibly_unused_file`.

### Baseline And Ignore Behavior

1. Add an entry to `project_doctor_baseline.json` matching a known finding by `id` and `path`.
2. Run a scan.
3. Confirm the accepted finding no longer appears and summary counts drop with it.
4. Add a temporary ignore path pattern such as `res://tests/fixtures/**` to `project_doctor_settings.cfg`.
5. Run a scan again.
6. Confirm findings from that path no longer appear.

## Report Checks

After a scan, inspect both output files.

Check JSON:

- `tool`
- `tool_version`
- `generated_at`
- `project_root`
- `scan_duration_ms`
- `summary`
- `findings`

CI summary helper spot-check:

1. Run `python .github/scripts/project_doctor_summary.py --report reports/project-doctor-report.json --mode warn --artifact-name project-doctor-reports`.
2. Confirm the command exits successfully.
3. Confirm the reported status matches the JSON summary counts.
4. Repeat with `--mode fail-on-errors` after introducing or simulating an error finding if you need to verify failure behavior in CI.

Check Markdown:

- title header exists,
- `Generated By` section exists,
- summary table is readable,
- findings are grouped in `Errors`, `Warnings`, then `Info`,
- groups render as collapsible `<details>` sections,
- table cells stay readable when text contains pipes, newlines, or backticks.

Check export/import readiness findings when relevant:

- export preset findings mention the affected platform or preset,
- import settings findings recommend reimporting or repairing the asset metadata,
- large texture import warnings are distinct from the base `large_texture` size warning.

## Command-Line Shape

Equivalent headless commands:

```text
godot --headless --path . --quit
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_smoke_test.gd
python .github/scripts/project_doctor_summary.py --report reports/project-doctor-report.json --mode warn --artifact-name project-doctor-reports
```

## CI Workflow Review

The reusable workflow lives at `.github/workflows/project-doctor.yml`.

Review points:

- it still runs `godot --headless --path . --quit`,
- it runs `res://addons/project_doctor_mini/tools/run_project_scan.gd`,
- it uploads the Markdown and JSON reports as `project-doctor-reports`,
- it writes a GitHub job summary,
- it comments on PRs only when `comment-on-pr` is enabled and PR context exists,
- it only fails on normal findings when `mode` requires it.

## Done Criteria For Testing Phase

Phase 5 is in a good state when:

- headless validation passes,
- headless scan passes,
- smoke test passes,
- reports are created in `reports/`,
- the dock works inside the Godot editor,
- manual spot-checks are repeatable.
