# New Godot Dev README

Small onboarding notes for a developer who is new to Godot and opening this repository for the first time.

## What This Project Is

This repository is mainly a Godot editor plugin, not a normal game UI project.

The plugin is called `Godot Project Doctor Mini` and it adds a dock inside the Godot editor that scans the current project and writes reports to:

- `reports/project-doctor-report.md`
- `reports/project-doctor-report.json`

## What To Open

Open the project folder in Godot.

You can use any code editor for GDScript files. The plugin UI itself is used from inside the Godot editor.

## Important Difference: Editor Plugin vs Run Project

If you press `Run Project`, Godot launches the main runtime scene.
That is not where the Project Doctor UI appears.

The Project Doctor UI appears only inside the Godot editor as a dock panel.

So if you run the game window and do not see the scanner UI, that is expected behavior.

## How To See The Plugin UI

1. Open the project in the Godot editor.
2. Go to `Project > Project Settings > Plugins`.
3. Make sure `Godot Project Doctor Mini` is enabled.
4. Look at the right-side dock area in the editor.
5. Open the `Project Doctor` dock.

Inside that dock you should see:

- `Scan Project`
- `Open Reports Folder`
- Severity filters
- Findings list

## Basic First Run

1. Open the dock.
2. Click `Scan Project`.
3. Wait for the status message to finish.
4. Review the findings list in the dock.
5. Open the generated files in `reports/`.

## Useful Headless Commands

From a terminal you can run:

```text
godot --headless --path . --quit
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_scan.gd
godot --headless --path . --script res://addons/project_doctor_mini/tools/run_project_doctor_smoke_test.gd
```

Practical meaning:

- The first command opens and closes the project as a quick sanity check.
- The second command runs the scanner without opening the dock.
- The third command validates the report schema and report writers.

## Files Worth Knowing First

- `addons/project_doctor_mini/project_doctor_plugin.gd`: registers the editor plugin.
- `addons/project_doctor_mini/project_doctor_dock.gd`: builds the dock UI.
- `addons/project_doctor_mini/scanner/project_scanner.gd`: runs the checks.
- `addons/project_doctor_mini/tools/run_project_scan.gd`: headless scan entrypoint.
- `reports/`: generated output after each scan.

## Common First-Time Confusions

### I ran the project and only saw a blank/simple scene

That is normal. The runtime scene is separate from the editor plugin.

### I do not see the dock

Check that the plugin is enabled in `Project Settings > Plugins` and that you are looking inside the Godot editor, not the running game window.

### I do not see reports yet

Run a scan first. The `reports/` folder is created when the scanner writes output.

## Recommended First Developer Loop

1. Open the project in Godot.
2. Enable the plugin if needed.
3. Run one scan from the dock.
4. Inspect `reports/`.
5. Edit code in your preferred editor.
6. Run the headless validation command after changes.

## Next Docs

- [GODOT_PROJECT_DOCTOR_MINI.md](GODOT_PROJECT_DOCTOR_MINI.md)
- [GODOT_PROJECT_DOCTOR_MINI_IMPLEMENTATION_PLAN.md](GODOT_PROJECT_DOCTOR_MINI_IMPLEMENTATION_PLAN.md)
- [TESTING.md](TESTING.md)
