@tool
extends SceneTree

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const MarkdownReportWriter = preload("res://addons/project_doctor_mini/report/markdown_report_writer.gd")
const JsonReportWriter = preload("res://addons/project_doctor_mini/report/json_report_writer.gd")

func _initialize() -> void:
    var scanner := ProjectScanner.new()
    var report: Dictionary = scanner.scan()

    MarkdownReportWriter.new().write(report, "res://project-doctor-report.md")
    JsonReportWriter.new().write(report, "res://project-doctor-report.json")

    var summary: Dictionary = report.get("summary", {})
    print("Project Doctor scan complete: %d errors, %d warnings, %d info" % [
        summary.get("errors", 0),
        summary.get("warnings", 0),
        summary.get("info", 0)
    ])

    quit(0)
