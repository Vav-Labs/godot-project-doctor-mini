@tool
extends SceneTree

const ProjectScanner = preload("res://addons/project_doctor_mini/scanner/project_scanner.gd")
const MarkdownReportWriter = preload("res://addons/project_doctor_mini/report/markdown_report_writer.gd")
const JsonReportWriter = preload("res://addons/project_doctor_mini/report/json_report_writer.gd")
const REPORTS_DIR := "res://reports"
const MARKDOWN_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.md"
const JSON_REPORT_PATH := REPORTS_DIR + "/project-doctor-report.json"
const SETTINGS_FILE_PATH := "res://project_doctor_settings.cfg"
const BASELINE_FILE_PATH := "res://project_doctor_baseline.json"
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
const EXPECTED_FAKE_DOC_PATHS := [
    "res://assets/textures/example.png",
    "res://export_presets.cfg",
    "res://tests/fixtures/scanner/missing_from_code_block.png"
]
const EXPECTED_FIXTURE_REFERENCED_RESOURCE := "res://tests/fixtures/scanner/linked_data.tres"
const EXPECTED_FIXTURE_DIRECTORY := "res://tests/fixtures/scanner"
const EXPECTED_IGNORED_FIXTURE_FINDING_PATH := "res://tests/fixtures/scanner/ignored_area/broken_scene.tscn"
const EXPECTED_UNUSED_FIXTURE_RESOURCE := "res://tests/fixtures/scanner/unused_probe.tres"
const DEFAULT_IGNORED_PATH_PATTERNS := ["res://reports", "res://sandbox_screenshot", "res://docs/examples", "res://tests/fixtures/**"]
const ACTIVE_FIXTURE_SCAN_PATTERNS := ["res://reports", "res://sandbox_screenshot", "res://docs/examples"]

func _init() -> void:
    var scanner := ProjectScanner.new()
    var report: Dictionary = scanner.scan()
    var failures: Array[String] = []

    _validate_report(report, failures)
    _validate_scanner_behavior(report, failures)
    _validate_scanner_controls(failures)

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

func _validate_scanner_behavior(report: Dictionary, failures: Array[String]) -> void:
    var findings: Array = report.get("findings", [])

    for fake_path in EXPECTED_FAKE_DOC_PATHS:
        if _has_finding(findings, "broken_resource_path", fake_path):
            failures.append("False positive broken_resource_path detected for example content: %s" % fake_path)

    if _has_finding(findings, "possibly_unused_file", EXPECTED_UNUSED_FIXTURE_RESOURCE):
        failures.append("Unused-file detection should be disabled by default: %s" % EXPECTED_UNUSED_FIXTURE_RESOURCE)

func _validate_scanner_controls(failures: Array[String]) -> void:
    var original_settings := _read_optional_text(SETTINGS_FILE_PATH)
    var original_baseline := _read_optional_text(BASELINE_FILE_PATH)

    _write_settings(DEFAULT_IGNORED_PATH_PATTERNS, [], "", false)
    _write_baseline([])

    var fixture_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], "", false)
    if _has_finding(fixture_report.get("findings", []), "possibly_unused_file", EXPECTED_FIXTURE_REFERENCED_RESOURCE):
        failures.append("Markdown-linked fixture resource was reported as unused: %s" % EXPECTED_FIXTURE_REFERENCED_RESOURCE)
    if _has_finding(fixture_report.get("findings", []), "broken_resource_path", EXPECTED_FIXTURE_DIRECTORY):
        failures.append("Existing fixture directory was reported as broken: %s" % EXPECTED_FIXTURE_DIRECTORY)

    var ignored_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS + ["res://tests/fixtures/scanner/ignored_area/**"], [], "", false)
    if _has_finding(ignored_report.get("findings", []), "missing_script", EXPECTED_IGNORED_FIXTURE_FINDING_PATH):
        failures.append("Ignored folder fixture still produced finding: %s" % EXPECTED_IGNORED_FIXTURE_FINDING_PATH)

    var ignored_id_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, ["export_presets_missing"], "", false)
    if _has_finding(ignored_id_report.get("findings", []), "export_presets_missing", "res://export_presets.cfg"):
        failures.append("Ignored finding ID did not suppress export_presets_missing.")

    var baseline_entries := [ {
        "id": "export_presets_missing",
        "path": "res://export_presets.cfg"
    }]
    var baseline_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], BASELINE_FILE_PATH, false, baseline_entries)
    if _has_finding(baseline_report.get("findings", []), "export_presets_missing", "res://export_presets.cfg"):
        failures.append("Baseline did not suppress accepted finding export_presets_missing.")

    var experimental_unused_report := _scan_with_settings(ACTIVE_FIXTURE_SCAN_PATTERNS, [], "", true)
    if not _has_finding(experimental_unused_report.get("findings", []), "possibly_unused_file", EXPECTED_UNUSED_FIXTURE_RESOURCE):
        failures.append("Experimental unused-file check did not flag the known unused fixture.")
    elif not _finding_message_contains(experimental_unused_report.get("findings", []), "possibly_unused_file", EXPECTED_UNUSED_FIXTURE_RESOURCE, "Experimental check"):
        failures.append("Experimental unused-file finding is missing the expected advisory wording.")

    _restore_optional_text(SETTINGS_FILE_PATH, original_settings)
    _restore_optional_text(BASELINE_FILE_PATH, original_baseline)

func _has_finding(findings: Array, finding_id: String, path: String) -> bool:
    for finding_variant in findings:
        if typeof(finding_variant) != TYPE_DICTIONARY:
            continue

        var finding: Dictionary = finding_variant
        if str(finding.get("id", "")) == finding_id and str(finding.get("path", "")) == path:
            return true

    return false

func _finding_message_contains(findings: Array, finding_id: String, path: String, fragment: String) -> bool:
    for finding_variant in findings:
        if typeof(finding_variant) != TYPE_DICTIONARY:
            continue

        var finding: Dictionary = finding_variant
        if str(finding.get("id", "")) == finding_id and str(finding.get("path", "")) == path:
            return str(finding.get("message", "")).contains(fragment)

    return false

func _scan_with_settings(ignored_path_patterns: Array, ignored_finding_ids: Array, baseline_file: String, enable_experimental_unused_files: bool, accepted_findings: Array = []) -> Dictionary:
    _write_settings(ignored_path_patterns, ignored_finding_ids, baseline_file, enable_experimental_unused_files)
    _write_baseline(accepted_findings)
    return ProjectScanner.new().scan()

func _write_settings(ignored_path_patterns: Array, ignored_finding_ids: Array, baseline_file: String, enable_experimental_unused_files: bool) -> void:
    var config := ConfigFile.new()
    config.set_value("scanner", "large_texture_threshold", 2048)
    config.set_value("scanner", "scene_node_count_threshold", 250)
    config.set_value("scanner", "ignored_path_patterns", PackedStringArray(ignored_path_patterns))
    config.set_value("scanner", "ignored_finding_ids", PackedStringArray(ignored_finding_ids))
    config.set_value("scanner", "baseline_file", baseline_file)
    config.set_value("scanner", "enable_experimental_unused_files", enable_experimental_unused_files)
    config.save(SETTINGS_FILE_PATH)

func _write_baseline(accepted_findings: Array) -> void:
    var file := FileAccess.open(BASELINE_FILE_PATH, FileAccess.WRITE)
    if file == null:
        return

    file.store_string(JSON.stringify({"accepted_findings": accepted_findings}, "  "))

func _read_optional_text(path: String) -> Variant:
    if not FileAccess.file_exists(path):
        return null

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null

    return file.get_as_text()

func _restore_optional_text(path: String, content: Variant) -> void:
    if content == null:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        return

    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return

    file.store_string(str(content))
    file.flush()
