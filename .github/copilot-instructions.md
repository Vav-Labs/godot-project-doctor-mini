# Copilot Instructions - Godot Project Doctor Mini

This repository is a Godot 4.6 editor plugin project.

## Project Goals

- Build a small Godot editor plugin named Godot Project Doctor Mini.
- Provide one-click project diagnostics from a dock inside the Godot editor.
- Export reports as `project-doctor-report.md` and `project-doctor-report.json`.
- Keep the MVP simple, readable, and useful for testing VS Code, Copilot, ChatGPT/Codex, GitHub, and MCP workflows.

## Technical Context

- Godot version: 4.6.2 Mono.
- Primary language for MVP: GDScript.
- C# may be added later for heavier scanning or integration work.
- Plugin root: `addons/project_doctor_mini/`.
- Editor plugin entrypoint: `addons/project_doctor_mini/project_doctor_plugin.gd`.

## Coding Guidelines

- Use Godot 4 typed GDScript where practical.
- Keep editor plugin code small and explicit.
- Prefer project-relative paths using `res://`.
- Avoid destructive filesystem actions in scanner checks.
- Generated diagnostic reports should be ignored by Git.
- Do not introduce external dependencies for the MVP.
- Do not store secrets, tokens, or API keys in the repository.

## MVP Checks

The scanner should report:

- Missing scripts.
- Broken resource paths.
- Large textures over threshold.
- Scenes with too many nodes.
- Nodes using `_process()`.
- Empty folders.
- Possibly unused files.
- Missing export presets.

## Report Shape

Each finding should include:

- `id`
- `severity`
- `title`
- `path`
- `message`
- `recommendation`

Severity should be one of:

- `error`
- `warning`
- `info`
