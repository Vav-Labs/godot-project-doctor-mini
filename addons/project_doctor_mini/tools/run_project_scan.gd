@tool
extends SceneTree

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const MarkdownReportWriter = preload("res://addons/project_doctor_mini/report/markdown_report_writer.gd")
const JsonReportWriter = preload("res://addons/project_doctor_mini/report/json_report_writer.gd")
const REPORTS_DIR := "res://reports"
const MARKDOWN_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.md"
const JSON_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.json"

func _initialize() -> void:
    var scanner := ProjectScanner.new()
    var report: Dictionary = scanner.scan()

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORTS_DIR))
    MarkdownReportWriter.new().write(report, MARKDOWN_REPORT_PATH)
    JsonReportWriter.new().write(report, JSON_REPORT_PATH)

    var summary: Dictionary = report.get("summary", {})
    print("Project Doctor scan complete: %d errors, %d warnings, %d info" % [
        summary.get("errors", 0),
        summary.get("warnings", 0),
        summary.get("info", 0)
    ])

    quit(0)
