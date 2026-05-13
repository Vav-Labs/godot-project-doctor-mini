@tool
extends VBoxContainer

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const MarkdownReportWriter = preload("res://addons/project_doctor_mini/report/markdown_report_writer.gd")
const JsonReportWriter = preload("res://addons/project_doctor_mini/report/json_report_writer.gd")
const REPORTS_DIR := "res://reports"
const MARKDOWN_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.md"
const JSON_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.json"

var status_label: Label
var summary_label: Label
var results: Tree
var scan_button: Button
var open_reports_button: Button
var errors_filter: CheckBox
var warnings_filter: CheckBox
var info_filter: CheckBox
var latest_report: Dictionary = {}

func _init() -> void:
    name = "Project Doctor"

func _ready() -> void:
    _build_ui()

func _build_ui() -> void:
    var title := Label.new()
    title.text = "Godot Project Doctor Mini"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(title)

    var actions_row := HBoxContainer.new()
    actions_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(actions_row)

    scan_button = Button.new()
    scan_button.text = "Scan Project"
    scan_button.tooltip_text = "Run the project scan and export Markdown/JSON reports."
    scan_button.pressed.connect(_scan_project)
    actions_row.add_child(scan_button)

    open_reports_button = Button.new()
    open_reports_button.text = "Open Reports Folder"
    open_reports_button.tooltip_text = "Open the generated reports directory on disk."
    open_reports_button.pressed.connect(_open_reports_folder)
    actions_row.add_child(open_reports_button)

    var filters_row := HBoxContainer.new()
    filters_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(filters_row)

    var filters_label := Label.new()
    filters_label.text = "Show:"
    filters_row.add_child(filters_label)

    errors_filter = _create_filter_toggle("Errors", "Show error findings.")
    filters_row.add_child(errors_filter)

    warnings_filter = _create_filter_toggle("Warnings", "Show warning findings.")
    filters_row.add_child(warnings_filter)

    info_filter = _create_filter_toggle("Info", "Show informational findings.")
    filters_row.add_child(info_filter)

    status_label = Label.new()
    status_label.text = "Ready."
    status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(status_label)

    summary_label = Label.new()
    summary_label.text = "Errors: 0 | Warnings: 0 | Info: 0"
    add_child(summary_label)

    results = Tree.new()
    results.columns = 4
    results.set_column_title(0, "Severity")
    results.set_column_title(1, "Check")
    results.set_column_title(2, "Path")
    results.set_column_title(3, "Message")
    results.set_column_titles_visible(true)
    results.set_column_expand(0, false)
    results.set_column_expand(1, false)
    results.set_column_expand_ratio(2, 2)
    results.set_column_expand_ratio(3, 3)
    results.hide_root = true
    results.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(results)

func _scan_project() -> void:
    _set_scan_controls_enabled(false)
    status_label.text = "Scanning project..."
    latest_report.clear()
    results.clear()

    var scanner := ProjectScanner.new()
    var report: Dictionary = scanner.scan()
    latest_report = report

    var reports_dir_ready := _ensure_reports_dir()
    var markdown_ok := false
    var json_ok := false
    if reports_dir_ready:
        markdown_ok = MarkdownReportWriter.new().write(report, MARKDOWN_REPORT_PATH)
        json_ok = JsonReportWriter.new().write(report, JSON_REPORT_PATH)

    _render_report(report)
    if not reports_dir_ready:
        status_label.text = "Scan complete, but the reports folder could not be created."
    elif markdown_ok and json_ok:
        status_label.text = "Scan complete. Reports: %s | %s" % [MARKDOWN_REPORT_PATH, JSON_REPORT_PATH]
    else:
        status_label.text = "Scan complete with export issues. Check the Output/Debugger panel."
    _set_scan_controls_enabled(true)

func _ensure_reports_dir() -> bool:
    return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORTS_DIR)) == OK

func _render_report(report: Dictionary) -> void:
    latest_report = report

    var summary: Dictionary = report.get("summary", {})
    summary_label.text = "Errors: %d | Warnings: %d | Info: %d" % [
        summary.get("errors", 0),
        summary.get("warnings", 0),
        summary.get("info", 0)
    ]

    _refresh_results()

func _refresh_results() -> void:
    results.clear()
    if latest_report.is_empty():
        return

    var root := results.create_item()
    var visible_count := 0
    for finding: Dictionary in latest_report.get("findings", []):
        if not _is_finding_visible(finding):
            continue

        var item := results.create_item(root)
        item.set_text(0, str(finding.get("severity", "info")))
        item.set_text(1, str(finding.get("id", "unknown")))
        item.set_text(2, str(finding.get("path", "")))
        item.set_text(3, str(finding.get("message", "")))
        visible_count += 1

    if visible_count == 0:
        var empty_item := results.create_item(root)
        empty_item.set_text(3, "No findings match the active filters.")

func _create_filter_toggle(text: String, tooltip: String) -> CheckBox:
    var toggle := CheckBox.new()
    toggle.text = text
    toggle.button_pressed = true
    toggle.tooltip_text = tooltip
    toggle.toggled.connect(_on_filter_toggled)
    return toggle

func _on_filter_toggled(_enabled: bool) -> void:
    _refresh_results()

func _is_finding_visible(finding: Dictionary) -> bool:
    match str(finding.get("severity", "info")):
        "error":
            return errors_filter.button_pressed
        "warning":
            return warnings_filter.button_pressed
        _:
            return info_filter.button_pressed

func _open_reports_folder() -> void:
    if not _ensure_reports_dir():
        status_label.text = "Could not create reports folder: %s" % REPORTS_DIR
        return

    var open_error := OS.shell_open(ProjectSettings.globalize_path(REPORTS_DIR))
    if open_error == OK:
        status_label.text = "Opened reports folder: %s" % REPORTS_DIR
    else:
        status_label.text = "Could not open reports folder: %s" % REPORTS_DIR

func _set_scan_controls_enabled(enabled: bool) -> void:
    scan_button.disabled = not enabled
    open_reports_button.disabled = not enabled
