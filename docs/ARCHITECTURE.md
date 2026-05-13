# Architecture

High-level architecture notes for Godot Project Doctor Mini.

## Overview

Godot Project Doctor Mini is a Godot editor plugin that scans the current project, builds one shared report dictionary, and exports that report to Markdown and JSON.

The main execution flow is:

1. User opens the `Project Doctor` dock in the Godot editor.
2. User clicks `Scan Project`.
3. The dock calls the scanner.
4. The scanner returns a report dictionary.
5. The dock renders summary/findings in the UI.
6. The report writers export the same data to `reports/`.

The same scan/export path is also available through headless scripts for local validation and CI.

## Editor Plugin Layer

Main files:

- `addons/project_doctor_mini/plugin.cfg`
- `addons/project_doctor_mini/project_doctor_plugin.gd`

Responsibilities:

- register the plugin with the Godot editor,
- create the dock instance,
- attach the dock to the editor UI,
- clean up the dock when the plugin exits.

`project_doctor_plugin.gd` is intentionally small. It only wires the dock into Godot's editor plugin API.

## Dock UI

Main file:

- `addons/project_doctor_mini/project_doctor_dock.gd`

Responsibilities:

- build the dock UI,
- trigger scans,
- show status text,
- show summary counts,
- filter findings by severity,
- open the reports folder,
- export Markdown and JSON after each scan.

The dock is responsible for presentation and user interaction, not for scanner logic.

## Scanner Layer

Main file:

- `addons/project_doctor_mini/scanner/project_scanner.gd`

Responsibilities:

- walk the project tree under `res://`,
- collect file and folder lists,
- collect references from Godot resources, GDScript loads, and Markdown links,
- execute the current checks,
- sort findings,
- build the final report dictionary.

The scanner currently keeps a single public API:

```text
scan() -> Dictionary
```

This keeps the external contract simple while allowing future extraction of checks into smaller modules.

## Report Writers

Main files:

- `addons/project_doctor_mini/report/markdown_report_writer.gd`
- `addons/project_doctor_mini/report/json_report_writer.gd`

Responsibilities:

- accept the shared report dictionary,
- serialize it to Markdown or JSON,
- write files into `reports/`,
- keep the exported output stable enough for review and automation.

The writers do not perform scanning. They only transform already computed report data.

## Headless Scripts

Main files:

- `addons/project_doctor_mini/tools/run_project_scan.gd`
- `addons/project_doctor_mini/tools/run_project_doctor_smoke_test.gd`

Responsibilities:

- run the scanner without opening the editor dock,
- export the same report files as the dock flow,
- provide repeatable checks for local development and CI.

Typical command shape:

```text
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
```

Smoke test shape:

```text
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_smoke_test.gd
```

## Report Schema

The shared report dictionary keeps the plugin, dock, writers, and headless scripts aligned.

Current top-level shape:

```json
{
  "tool": "Godot Project Doctor Mini",
  "tool_version": "0.1.0",
  "generated_at": "2026-05-13T00:00:00",
  "project_root": "res://",
  "scan_duration_ms": 18,
  "summary": {
    "errors": 0,
    "warnings": 0,
    "info": 0
  },
  "findings": []
}
```

Each finding keeps a stable shape:

```json
{
  "id": "large_texture",
  "severity": "warning",
  "title": "Large Texture",
  "path": "res://assets/textures/example.png",
  "message": "Texture is 4096x4096, above the 2048px threshold.",
  "recommendation": "Resize, compress, or use platform-specific import settings."
}
```

## Known Tradeoffs

- The scanner is still intentionally conservative and does not implement a full dependency graph.
- Dynamic loads may not always be detected.
- The scanner remains mostly monolithic for now to keep the MVP easy to reason about.
- Some docs include illustrative `res://` paths, so scanner reference handling must stay careful to avoid noisy false positives.

## Future Modular Check Structure

One good next refactor is to extract a few low-risk checks into separate files while keeping the scanner API stable.

Suggested future shape:

```text
addons/project_doctor_mini/scanner/
  project_scanner.gd
  checks/
    export_presets_check.gd
    process_usage_check.gd
    scene_node_count_check.gd
```

That would improve extensibility without changing how the dock or headless scripts call the scanner.
