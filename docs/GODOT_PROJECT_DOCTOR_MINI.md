# Godot Project Doctor Mini

One-click project scan + Markdown/JSON diagnostic report for Godot projects.

## Purpose

Godot Project Doctor Mini is a small Godot editor plugin used as the first test project for a VS Code + Copilot + ChatGPT/Codex + MCP workflow.

The plugin scans the current Godot project and produces a simple diagnostic report that helps catch common project hygiene, performance, and export-readiness issues early.

## Why This Project

This is a good first project because it touches the exact workflow we want to validate:

- Godot editor plugin structure
- GDScript scripting
- VS Code editing and navigation
- Git/GitHub workflow
- Copilot-assisted implementation
- ChatGPT/Codex-assisted planning and review
- MCP filesystem/Git/GitHub context later
- UI dock/panel inside the Godot editor
- Project filesystem scanning
- Markdown and JSON report generation
- Possible C# expansion later

## MVP Goal

Create a Godot editor dock with one main button:

```text
Scan Project
```

When clicked, the plugin scans the project and shows a diagnostic summary in the dock. It also exports two report files:

```text
reports/project-doctor-report.md
reports/project-doctor-report.json
```

## MVP Checks

| Check | Why It Is Useful |
| --- | --- |
| Missing scripts | Practical in every Godot project; catches broken scene references. |
| Broken resource paths | Common after file moves, renames, and refactors. |
| Large textures over threshold | Useful for mobile/export readiness and asset discipline. |
| Scenes with too many nodes | Simple performance and maintainability smell. |
| Nodes using `_process()` | Quick runtime-risk indicator for unnecessary per-frame logic. |
| Empty folders | Keeps project structure clean. |
| Unused files | Helps detect old assets and forgotten experiments. |
| Export presets missing | Practical pre-build readiness check. |

## Initial Thresholds

These defaults can be exposed in plugin settings later.

| Setting | Default |
| --- | --- |
| Large texture threshold | 2048 px width or height |
| Scene node-count warning | 250 nodes |
| Scan root | `res://` |
| Report output folder | project root |

## Suggested Plugin Structure

```text
addons/
  project_doctor_mini/
    plugin.cfg
    project_doctor_plugin.gd
    project_doctor_dock.gd
    project_doctor_dock.tscn
    scanner/
      project_scanner.gd
      checks/
        missing_scripts_check.gd
        broken_paths_check.gd
        large_textures_check.gd
        scene_node_count_check.gd
        process_usage_check.gd
        empty_folders_check.gd
        unused_files_check.gd
        export_presets_check.gd
    report/
      report_writer.gd
      markdown_report_writer.gd
      json_report_writer.gd
```

## Dock UI Draft

The editor dock should stay simple for MVP.

```text
Godot Project Doctor Mini

[ Scan Project ]

Summary
- Errors: 0
- Warnings: 0
- Info: 0

Results
[scrollable list/table of findings]

[ Export Markdown ] [ Export JSON ]
```

For the first version, exporting can happen automatically after each scan. Manual export buttons can come next.

## Finding Model

Each diagnostic finding should have a stable shape so it can be rendered in the UI and exported to JSON/Markdown.

```json
{
  "id": "large_texture",
  "severity": "warning",
  "title": "Large texture detected",
  "path": "res://assets/textures/example.png",
  "message": "Texture is 4096x4096, above the 2048px threshold.",
  "recommendation": "Resize, compress, or move to platform-specific import settings."
}
```

## Severity Levels

| Severity | Meaning |
| --- | --- |
| `error` | Likely broken project behavior or missing required file. |
| `warning` | Potential performance, export, or maintenance issue. |
| `info` | Hygiene suggestion or helpful observation. |

## Report Output

### Markdown Report

The Markdown report should be human-readable and GitHub-friendly.

Suggested layout:

```markdown
# Godot Project Doctor Report

Generated: 2026-05-13 00:00
Project: res://

## Summary

| Severity | Count |
| --- | ---: |
| Error | 0 |
| Warning | 3 |
| Info | 2 |

## Findings

### Warning: Large texture detected

- Path: res://assets/textures/example.png
- Check: large_texture
- Message: Texture is 4096x4096, above the 2048px threshold.
- Recommendation: Resize, compress, or move to platform-specific import settings.
```

### JSON Report

The JSON report should be machine-readable for future automation.

```json
{
  "tool": "Godot Project Doctor Mini",
  "generated_at": "2026-05-13T00:00:00",
  "project_root": "res://",
  "summary": {
    "errors": 0,
    "warnings": 3,
    "info": 2
  },
  "findings": []
}
```

## Implementation Phases

### Phase 1 - Plugin Skeleton

- Create `addons/project_doctor_mini/plugin.cfg`.
- Create `EditorPlugin` script.
- Add a dock panel to the Godot editor.
- Add `Scan Project` button.
- Show placeholder scan output.

### Phase 2 - Scanner Core

- Walk project files under `res://`.
- Collect `.tscn`, `.gd`, `.png`, `.jpg`, `.jpeg`, `.webp`, `.tres`, `.res`, and config files.
- Return findings using one common data model.

### Phase 3 - MVP Checks

- Missing scripts.
- Broken resource paths.
- Large textures over threshold.
- Scenes with too many nodes.
- Nodes using `_process()`.
- Empty folders.
- Unused files.
- Export presets missing.

### Phase 4 - Reports

- Generate `reports/project-doctor-report.md`.
- Generate `reports/project-doctor-report.json`.
- Show report file paths in the dock after scan.

### Phase 5 - Polish

- Add progress/status text.
- Add severity filters.
- Add setting fields for thresholds.
- Add README screenshots later.
- Add small sample project for testing.

## Testing Plan

Manual MVP tests:

- Enable plugin in Godot Project Settings.
- Open dock and click `Scan Project`.
- Confirm findings appear in the dock.
- Confirm Markdown report is created.
- Confirm JSON report is created.
- Rename/move a resource and confirm broken path detection.
- Add a large texture and confirm warning.
- Add a scene with many nodes and confirm warning.
- Add `_process()` to a script and confirm detection.
- Remove export presets and confirm warning.

## Future Ideas

- C# scanner helpers for heavier parsing.
- Godot import settings analysis.
- Asset Library packaging checklist.
- GitHub Action that runs the scanner in headless mode.
- Baseline file so known warnings can be ignored.
- Export profile readiness checks per platform.
- Scene dependency graph.
- Plugin settings panel.
- One-click open generated report.

## Working Title

Godot Project Doctor Mini

## Short Description

A small Godot editor plugin that scans your project for common hygiene, asset, scene, script, and export readiness issues, then generates Markdown and JSON reports.
