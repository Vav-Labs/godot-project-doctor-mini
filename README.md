# Godot Project Doctor Mini

A small Godot 4 editor plugin that scans the current project and generates a simple diagnostic report.

## Getting Started

This repository is primarily a Godot editor plugin project, not a runtime game UI project.

If you are opening it for the first time:

1. Open the repository in Godot.
2. Open the same folder in VS Code.
3. Make sure the plugin is enabled.
4. Open the `Project Doctor` dock in the Godot editor.
5. Run one scan and inspect the generated reports in `reports/`.

If you are new to Godot or new to this repository, start with [docs/NEW_GODOT_DEV_README.md](docs/NEW_GODOT_DEV_README.md).

## Current MVP

The plugin adds a dock named `Project Doctor` inside the Godot editor. The dock has a `Scan Project` button that runs basic project checks and exports:

- `reports/project-doctor-report.md`
- `reports/project-doctor-report.json`

## Checks

- Missing scripts
- Broken resource paths
- Large textures over threshold
- Scenes with too many nodes
- Scripts using `_process()`
- Empty folders
- Possibly unused files
- Missing export presets

## Requirements

- Godot 4.6.2 Mono
- VS Code
- VS Code extensions:
  - `geequlim.godot-tools`
  - `github.copilot-chat`

The MVP is GDScript-first. C# support may be added later after a real `.csproj` / `.sln` exists.

## Enable The Plugin

The Project Doctor UI appears inside the Godot editor, not in the running game window.

To enable it:

1. Open the project in the Godot editor.
2. Go to `Project > Project Settings > Plugins`.
3. Enable `Godot Project Doctor Mini`.
4. Open the `Project Doctor` dock on the right side of the editor.

If you press `Run Project`, Godot launches the main runtime scene. That is separate from the editor plugin UI.

## Basic Usage

Once the plugin is enabled:

1. Open the `Project Doctor` dock.
2. Click `Scan Project`.
3. Review the status message and summary counts.
4. Filter findings by severity if needed.
5. Use `Open Reports Folder` to inspect the generated files.

The dock shows findings directly in the editor and writes the same scan results to Markdown and JSON.

## VS Code Setup

Workspace settings keep the local Godot executable path in one place:

```text
godotTools.editorPath.godot4
```

Tasks and launch configurations reference that setting instead of repeating the executable path.

The GDScript language server is expected at:

```text
127.0.0.1:6008
```

If VS Code shows `Couldn't connect to the GDScript language server at 127.0.0.1:6008`, open this project in the Godot editor and run the VS Code command `Godot Tools: Start the GDScript Language Server for this workspace`.

## Useful Tasks

From VS Code, run:

- `Godot: Open Editor`
- `Godot: Run Project`
- `Godot: Validate Project Headless`
- `Godot: Scan Project Headless`
- `Godot: Smoke Test Project Doctor`

`Godot: Validate Project Headless` opens and closes the project as a sanity check. `Godot: Scan Project Headless` runs the Project Doctor scanner and exports the Markdown/JSON reports into `reports/`. `Godot: Smoke Test Project Doctor` validates the report schema and confirms the generated report files can be written.

For the full manual and headless testing flow, see [docs/TESTING.md](docs/TESTING.md).

Equivalent command shape:

```text
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
```

## Generated Reports

Each scan writes:

- `reports/project-doctor-report.md`
- `reports/project-doctor-report.json`

The Markdown report is meant for quick reading in GitHub, VS Code, or a text editor.
The JSON report is meant for stable machine-readable output and automation.

## Troubleshooting

### I ran the project and do not see the plugin UI

That is expected if you used `Run Project`. The plugin UI appears only inside the Godot editor dock.

### I do not see the `Project Doctor` dock

Check `Project > Project Settings > Plugins` and confirm that `Godot Project Doctor Mini` is enabled.

### VS Code cannot connect to the GDScript language server

Open the project in Godot first, then run:

`Godot Tools: Start the GDScript Language Server for this workspace`

### Reports do not appear yet

Run a scan first. The `reports/` folder is created when a scan writes output.

### I want a quick health check before editing more code

Run `Godot: Validate Project Headless`, then `Godot: Scan Project Headless`, then `Godot: Smoke Test Project Doctor`.

## AI Workflow

This project uses GitHub Copilot as the main VS Code coding agent, with ChatGPT/Codex for planning and review, and MCP as an optional shared tool/context layer.

See [docs/MULTI_AGENT_ORCHESTRATION.md](docs/MULTI_AGENT_ORCHESTRATION.md) for the current orchestration plan.

## Plugin Files

```text
addons/project_doctor_mini/
  plugin.cfg
  project_doctor_plugin.gd
  project_doctor_dock.gd
  tools/run_project_scan.gd
  scanner/project_scanner.gd
  report/markdown_report_writer.gd
  report/json_report_writer.gd
```

## Known Limitations

- Dynamic resource loads may not always be detected by the scanner.
- `Possibly unused file` findings should be manually confirmed before deleting anything.
- The plugin UI is editor-only and is not part of the runtime game scene.
- Thresholds are currently simple defaults and are not yet exposed as plugin settings.

## Notes

This project intentionally starts as a compact GDScript-first editor plugin. C# support can be added later after the Godot/VS Code/AI/MCP workflow is proven.
