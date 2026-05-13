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

func _init() -> void:
    name = "Project Doctor"

func _ready() -> void:
    _build_ui()

func _build_ui() -> void:
    var title := Label.new()
    title.text = "Godot Project Doctor Mini"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(title)

    scan_button = Button.new()
    scan_button.text = "Scan Project"
    scan_button.pressed.connect(_scan_project)
    add_child(scan_button)

    status_label = Label.new()
    status_label.text = "Ready."
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
    results.hide_root = true
    results.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(results)

func _scan_project() -> void:
    scan_button.disabled = true
    status_label.text = "Scanning..."
    results.clear()

    var scanner := ProjectScanner.new()
    var report: Dictionary = scanner.scan()

    _ensure_reports_dir()
    MarkdownReportWriter.new().write(report, MARKDOWN_REPORT_PATH)
    JsonReportWriter.new().write(report, JSON_REPORT_PATH)

    _render_report(report)
    status_label.text = "Scan complete. Reports exported to reports/."
    scan_button.disabled = false

func _ensure_reports_dir() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORTS_DIR))

func _render_report(report: Dictionary) -> void:
    var summary: Dictionary = report.get("summary", {})
    summary_label.text = "Errors: %d | Warnings: %d | Info: %d" % [
        summary.get("errors", 0),
        summary.get("warnings", 0),
        summary.get("info", 0)
    ]

    var root := results.create_item()
    for finding: Dictionary in report.get("findings", []):
        var item := results.create_item(root)
        item.set_text(0, str(finding.get("severity", "info")))
        item.set_text(1, str(finding.get("id", "unknown")))
        item.set_text(2, str(finding.get("path", "")))
        item.set_text(3, str(finding.get("message", "")))
