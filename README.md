# Godot Project Doctor Mini

A small Godot 4 editor plugin that scans the current project and generates a simple diagnostic report.

## Current MVP

The plugin adds a dock named `Project Doctor` inside the Godot editor. The dock has a `Scan Project` button that runs basic project checks and exports:

- `project-doctor-report.md`
- `project-doctor-report.json`

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
  - `neikeq.godot-csharp-vscode`
  - `ms-dotnettools.csdevkit`
  - `github.copilot-chat`

## VS Code Setup

Workspace settings point to the local Godot executable:

```text
C:\Users\Stratos\Godot Projects\Godot_v4.6.2-stable_mono_win64\Godot_v4.6.2-stable_mono_win64.exe
```

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

## AI Workflow

This project uses GitHub Copilot as the main VS Code coding agent, with ChatGPT/Codex for planning and review, and MCP as an optional shared tool/context layer.

See [MULTI_AGENT_ORCHESTRATION.md](MULTI_AGENT_ORCHESTRATION.md) for the current orchestration plan.

## Plugin Files

```text
addons/project_doctor_mini/
  plugin.cfg
  project_doctor_plugin.gd
  project_doctor_dock.gd
  scanner/project_scanner.gd
  report/markdown_report_writer.gd
  report/json_report_writer.gd
```

## Notes

This project intentionally starts as a compact GDScript-first editor plugin. C# support can be added later after the Godot/VS Code/AI/MCP workflow is proven.
