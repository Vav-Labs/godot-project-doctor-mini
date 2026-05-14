# Public Release Checklist

Checklist for preparing `Vav-Labs/godot-project-doctor-mini` for the `0.2.4` public release and Asset Library review.

## Repository About

Already recommended:

- Description: `A small Godot 4 editor plugin that scans projects and generates Markdown/JSON diagnostic reports.`
- Website: `https://github.com/Vav-Labs/godot-project-doctor-mini`
- Topics:
  - `godot`
  - `godot-engine`
  - `godot4`
  - `gdscript`
  - `editor-plugin`
  - `game-development`
  - `diagnostics`
  - `static-analysis`
  - `project-health`
  - `markdown`
  - `json`

## Files To Include

- `README.md`
- `LICENSE`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `.github/workflows/smoke-test.yml`
- `.github/workflows/project-doctor.yml`
- `docs/TESTING.md`
- `docs/ARCHITECTURE.md`
- `examples/demo_project/`
- `docs/NEW_GODOT_DEV_README.md`

## AI Agent / Planning Scratch Files

Do not keep agent-specific instructions, planning scratchpads, or prompt files in the public repository.

Before release, make sure files or folders like these are removed from Git when they are only internal workflow material:

- `AGENTS.md`
- `agent*.md`
- `copilot-instructions.md`
- `codex*.md`
- `cline*.md`
- `cursor*.md`
- `PLAN.md`
- `PLANNING.md`
- `TASKS.md`
- `PROMPT.md`
- `prompts/`
- `notes/`
- `scratch/`
- `ai/`
- `.cursor/`
- `.cline/`
- `.codex/`
- `.github/copilot-instructions.md`
- `.github/instructions/`
- `.github/prompts/`

Keep this cleanup limited to the current working tree and currently tracked files. If sensitive content may already exist in Git history, handle that separately instead of rewriting history as part of normal release prep.

## Screenshot

Add:

```text
docs/assets/project-doctor-dock.png
```

Recommended screenshot contents:

- Godot editor visible.
- `Project Doctor` dock open.
- `Scan Project` and `Open Reports Folder` visible.
- Severity filters visible.
- Summary visible.
- At least one finding visible.

Then replace the placeholder section in `README.md` with:

```markdown
![Project Doctor dock](docs/assets/project-doctor-dock.png)
```

## Local Validation

Run before tagging:

```text
godot --headless --path . --quit
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_smoke_test.gd
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_scanner_test.gd
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_integration_test.gd
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_benchmark.gd
python .github/scripts/project_doctor_summary.py --report reports/project-doctor-report.json --mode warn --artifact-name project-doctor-reports
```

Expected root project result:

```text
Project Doctor smoke test passed.
Project Doctor scanner test passed.
Project Doctor integration test passed.
Project Doctor scan complete: 0 errors, 1 warnings, 0 info
Project Doctor benchmark complete: 500 generated files, 590 total files scanned, about 493 ms, Godot 4.6.2
```

The root scan should stay clean because the demo project fixtures are ignored by the release scan config.

The demo project is intentionally excluded from the root scan so its sample issues only appear in the dedicated integration test.

## Release Tag

After committing and pushing the public-ready files:

```text
git tag -a v0.2.4 -m "Release v0.2.4"
git push origin v0.2.4
```

Then create a GitHub release from the tag using the `CHANGELOG.md` `0.2.4` notes.

## Suggested Release Title

```text
Godot Project Doctor Mini v0.2.4
```

## Suggested Release Summary

```text
Public release for Godot Project Doctor Mini: a Godot 4 editor plugin with shared settings, CI automation, export/import readiness checks, a standalone demo project, integration coverage, benchmark notes, and Asset Library packaging polish.
```

## Before Marking The Repo Ready

- README badge is visible.
- GitHub Actions smoke test is green.
- Reusable Project Doctor workflow is green.
- License appears in GitHub sidebar.
- Topics appear in GitHub sidebar.
- Screenshot is added or README clearly says it is coming soon.
- Demo project README explains the expected findings.
- Benchmark note in README matches a real measured run.
- `CHANGELOG.md` has `0.2.4`.
- Release tag `v0.2.4` exists.
