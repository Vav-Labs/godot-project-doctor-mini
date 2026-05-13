# Godot Project Doctor Mini

A small Godot 4 editor plugin that scans the current project and generates a simple diagnostic report.

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

## AI Workflow

This project uses GitHub Copilot as the main VS Code coding agent, with ChatGPT/Codex for planning and review, and MCP as an optional shared tool/context layer.

See [docs/MULTI_AGENT_ORCHESTRATION.md](docs/MULTI_AGENT_ORCHESTRATION.md) for the current orchestration plan.

If you are new to Godot or opening this repository for the first time, start with [docs/NEW_GODOT_DEV_README.md](docs/NEW_GODOT_DEV_README.md).

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

## Notes

This project intentionally starts as a compact GDScript-first editor plugin. C# support can be added later after the Godot/VS Code/AI/MCP workflow is proven.
