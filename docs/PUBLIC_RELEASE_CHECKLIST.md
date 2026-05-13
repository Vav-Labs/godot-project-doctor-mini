# Public Release Checklist

Checklist for preparing `Vav-Labs/godot-project-doctor-mini` for a clean public MVP release.

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
- `docs/TESTING.md`
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

## Demo GIF

Add:

```text
docs/assets/project-doctor-demo.gif
```

Recommended flow:

1. Open `Project Doctor` dock.
2. Click `Scan Project`.
3. Show summary update.
4. Toggle one severity filter.
5. Click `Open Reports Folder`.

Keep the GIF short, ideally under 10 seconds.

## Local Validation

Run before tagging:

```text
godot --headless --path . --quit
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_smoke_test.gd
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
```

Expected MVP result:

```text
Project Doctor smoke test passed.
Project Doctor scan complete: 0 errors, 1 warnings, 0 info
```

The missing export presets warning is expected until `export_presets.cfg` exists.

## First Release Tag

After committing and pushing the public-ready files:

```text
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

Then create a GitHub release from the tag using the `CHANGELOG.md` `0.1.0` notes.

## Suggested Release Title

```text
Godot Project Doctor Mini v0.1.0
```

## Suggested Release Summary

```text
First MVP release of Godot Project Doctor Mini: a Godot 4 editor plugin that scans a project and generates Markdown/JSON diagnostic reports.
```

## Before Marking The Repo Ready

- README badge is visible.
- GitHub Actions smoke test is green.
- License appears in GitHub sidebar.
- Topics appear in GitHub sidebar.
- Screenshot is added or README clearly says it is coming soon.
- `CHANGELOG.md` has `0.1.0`.
- Release tag `v0.1.0` exists.
