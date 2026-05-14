# Demo Project

This small Godot project is a public example and integration-test fixture for Godot Project Doctor Mini.

It demonstrates a few intentional, safe findings:

- `missing_script` from a scene that references a script path that does not exist
- `large_texture` from a committed oversized texture asset
- `export_preset_missing_export_path` from an intentionally incomplete export preset

How to try it manually:

1. Copy `../../addons/project_doctor_mini` into `addons/project_doctor_mini` inside this demo project.
2. Open `examples/demo_project` in Godot.
3. Enable `Godot Project Doctor Mini` from `Project > Project Settings > Plugins`.
4. Run a scan from the `Project Doctor` dock or with the headless scan script.

The repository integration test copies the plugin into this demo project temporarily before running the scan, then cleans the copied addon and generated cache folders afterward.
