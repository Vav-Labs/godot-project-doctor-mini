@tool
extends SceneTree

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const MarkdownReportWriter = preload("res://addons/project_doctor_mini/report/markdown_report_writer.gd")
const JsonReportWriter = preload("res://addons/project_doctor_mini/report/json_report_writer.gd")
const REPORTS_DIR := "res://reports"
const MARKDOWN_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.md"
const JSON_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.json"
const REQUIRED_REPORT_KEYS := [
    "tool",
    "tool_version",
    "generated_at",
    "project_root",
    "scan_duration_ms",
    "summary",
    "findings"
]
const REQUIRED_FINDING_KEYS := [
    "id",
    "severity",
    "title",
    "path",
    "message",
    "recommendation"
]
const ALLOWED_SEVERITIES := ["error", "warning", "info"]

func _initialize() -> void:
    var scanner := ProjectScanner.new()
    var report: Dictionary = scanner.scan()
    var failures: Array[String] = []

    _validate_report(report, failures)

    var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORTS_DIR))
    if dir_error != OK:
        failures.append("Could not create reports directory: %s" % REPORTS_DIR)

    var markdown_ok := MarkdownReportWriter.new().write(report, MARKDOWN_REPORT_PATH)
    var json_ok := JsonReportWriter.new().write(report, JSON_REPORT_PATH)
    if not markdown_ok:
        failures.append("Markdown report writer returned false.")
    if not json_ok:
        failures.append("JSON report writer returned false.")

    if not FileAccess.file_exists(MARKDOWN_REPORT_PATH):
        failures.append("Markdown report was not written: %s" % MARKDOWN_REPORT_PATH)
    if not FileAccess.file_exists(JSON_REPORT_PATH):
        failures.append("JSON report was not written: %s" % JSON_REPORT_PATH)

    if failures.is_empty():
        print("Project Doctor smoke test passed.")
        quit(0)
        return

    for failure in failures:
        printerr(failure)
    quit(1)

func _validate_report(report: Dictionary, failures: Array[String]) -> void:
    for key: String in REQUIRED_REPORT_KEYS:
        if not report.has(key):
            failures.append("Report is missing required key: %s" % key)

    var summary := report.get("summary", {})
    if typeof(summary) != TYPE_DICTIONARY:
        failures.append("Report summary is not a dictionary.")
    else:
        for key: String in ["errors", "warnings", "info"]:
            if not summary.has(key):
                failures.append("Summary is missing required key: %s" % key)
            elif not _is_number(summary.get(key)):
                failures.append("Summary value is not numeric for key: %s" % key)

    if not _is_number(report.get("scan_duration_ms", null)):
        failures.append("scan_duration_ms is missing or not numeric.")

    var findings := report.get("findings", [])
    if typeof(findings) != TYPE_ARRAY:
        failures.append("Report findings is not an array.")
        return

    for finding_variant in findings:
        if typeof(finding_variant) != TYPE_DICTIONARY:
            failures.append("Finding entry is not a dictionary.")
            continue

        var finding: Dictionary = finding_variant
        for key: String in REQUIRED_FINDING_KEYS:
            if not finding.has(key):
                failures.append("Finding is missing required key: %s" % key)

        var severity := str(finding.get("severity", ""))
        if severity not in ALLOWED_SEVERITIES:
            failures.append("Finding has invalid severity: %s" % severity)

func _is_number(value: Variant) -> bool:
    var value_type := typeof(value)
    return value_type == TYPE_INT or value_type == TYPE_FLOAT
