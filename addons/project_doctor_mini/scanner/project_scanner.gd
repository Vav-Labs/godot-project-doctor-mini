@tool
extends RefCounted

const ProcessUsageCheck = preload("res://addons/project_doctor_mini/scanner/checks/process_usage_check.gd")
const ExportPresetsCheck = preload("res://addons/project_doctor_mini/scanner/checks/export_presets_check.gd")

const DEFAULT_LARGE_TEXTURE_THRESHOLD := 2048
const DEFAULT_SCENE_NODE_COUNT_THRESHOLD := 250
const DEFAULT_EXCLUDED_DIRECTORIES := ["res://reports", "res://sandbox_screenshot"]
const DEFAULT_IGNORED_FINDINGS := []
const LARGE_TEXTURE_THRESHOLD_SETTING := "project_doctor_mini/large_texture_threshold"
const SCENE_NODE_COUNT_THRESHOLD_SETTING := "project_doctor_mini/scene_node_count_threshold"
const EXCLUDED_DIRECTORIES_SETTING := "project_doctor_mini/ignored_folders"
const IGNORED_FINDINGS_SETTING := "project_doctor_mini/ignored_findings"
const TOOL_NAME := "Godot Project Doctor Mini"
const TOOL_VERSION_FALLBACK := "0.1.0"
const SEVERITY_ORDER := {
    "error": 0,
    "warning": 1,
    "info": 2
}
const RESOURCE_TEXT_EXTENSIONS := ["tscn", "tres", "cfg", "godot", "import", "md"]
const TEXTURE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
const UNUSED_CANDIDATE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "wav", "ogg", "mp3", "tres", "res", "tscn", "gdshader"]

var findings: Array[Dictionary] = []
var files: Array[String] = []
var folders: Array[String] = []
var referenced_paths: Dictionary = {}
var large_texture_threshold := DEFAULT_LARGE_TEXTURE_THRESHOLD
var scene_node_count_threshold := DEFAULT_SCENE_NODE_COUNT_THRESHOLD
var excluded_directories: Array = []
var ignored_findings: Dictionary = {}

func scan() -> Dictionary:
    var start_ticks := Time.get_ticks_msec()

    findings.clear()
    files.clear()
    folders.clear()
    referenced_paths.clear()
    large_texture_threshold = _get_int_setting(LARGE_TEXTURE_THRESHOLD_SETTING, DEFAULT_LARGE_TEXTURE_THRESHOLD)
    scene_node_count_threshold = _get_int_setting(SCENE_NODE_COUNT_THRESHOLD_SETTING, DEFAULT_SCENE_NODE_COUNT_THRESHOLD)
    excluded_directories = _get_string_array_setting(EXCLUDED_DIRECTORIES_SETTING, DEFAULT_EXCLUDED_DIRECTORIES)
    ignored_findings = _build_ignored_findings_lookup(_get_string_array_setting(IGNORED_FINDINGS_SETTING, DEFAULT_IGNORED_FINDINGS))

    _walk_directory("res://")
    _collect_references()
    _check_missing_scripts()
    _check_broken_resource_paths()
    _check_large_textures()
    _check_scene_node_counts()
    _append_findings(ProcessUsageCheck.new().run(files, Callable(self , "_read_text_file")))
    _check_empty_folders()
    _check_unused_files()
    _append_findings(ExportPresetsCheck.new().run())
    _filter_ignored_findings()
    _sort_findings()

    var tool_version := _load_tool_version()

    return {
        "tool": TOOL_NAME,
        "tool_version": tool_version,
        "generated_at": Time.get_datetime_string_from_system(true),
        "project_root": "res://",
        "scan_duration_ms": Time.get_ticks_msec() - start_ticks,
        "summary": _build_summary(),
        "findings": findings
    }

func _walk_directory(path: String) -> void:
    if _is_excluded_directory(path):
        return

    var dir := DirAccess.open(path)
    if dir == null:
        _add_finding("scan_error", "error", path, "Could not open directory.", "Check folder permissions or project state.")
        return

    folders.append(path)
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if not entry.begins_with("."):
            var child_path := path.path_join(entry)
            if dir.current_is_dir():
                _walk_directory(child_path)
            else:
                files.append(child_path)
        entry = dir.get_next()
    dir.list_dir_end()

func _collect_references() -> void:
    var markdown_regex := RegEx.new()
    markdown_regex.compile("!?\\[[^\\]]*\\]\\(([^)]+)\\)")

    for file_path in files:
        var extension := file_path.get_extension().to_lower()
        if extension != "gd" and not _has_extension(file_path, RESOURCE_TEXT_EXTENSIONS):
            continue

        var text := _read_text_file(file_path)
        if text == "":
            continue

        if extension == "md":
            _collect_markdown_references(file_path, text, markdown_regex)
            continue

        for line in text.split("\n"):
            if extension == "gd" and not _is_gdscript_resource_load_line(line):
                continue

            for resource_path in _extract_resource_paths_from_line(line):
                referenced_paths[resource_path] = true

func _check_missing_scripts() -> void:
    for file_path in files:
        if not _has_extension(file_path, ["tscn", "tres"]):
            continue

        var text := _read_text_file(file_path)
        if text == "":
            continue

        for line in text.split("\n"):
            if line.contains("type=\"Script\"") and line.contains("path=\"res://"):
                var script_path := _extract_resource_path(line)
                if script_path != "" and not FileAccess.file_exists(script_path):
                    _add_finding(
                        "missing_script",
                        "error",
                        file_path,
                        "Scene or resource references a missing script: %s" % script_path,
                        "Restore the script or remove the broken reference."
                    )

func _check_broken_resource_paths() -> void:
    for resource_path in referenced_paths.keys():
        if resource_path == "res://":
            continue
        if not _resource_path_exists(resource_path):
            _add_finding(
                "broken_resource_path",
                "error",
                resource_path,
                "Referenced resource path does not exist.",
                "Update the reference or restore the missing resource."
            )

func _check_large_textures() -> void:
    for file_path in files:
        if not _has_extension(file_path, TEXTURE_EXTENSIONS):
            continue

        var image := Image.new()
        var error := image.load(file_path)
        if error != OK:
            _add_finding("texture_load_error", "warning", file_path, "Could not read texture dimensions.", "Reimport or validate the texture file.")
            continue

        var width := image.get_width()
        var height := image.get_height()
        if width > large_texture_threshold or height > large_texture_threshold:
            _add_finding(
                "large_texture",
                "warning",
                file_path,
                "Texture is %dx%d, above the %dpx threshold." % [width, height, large_texture_threshold],
                "Resize, compress, or use platform-specific import settings."
            )

func _check_scene_node_counts() -> void:
    for file_path in files:
        if not _has_extension(file_path, ["tscn"]):
            continue

        var node_count := 0
        var text := _read_text_file(file_path)
        if text == "":
            continue

        for line in text.split("\n"):
            if line.begins_with("[node "):
                node_count += 1

        if node_count > scene_node_count_threshold:
            _add_finding(
                "scene_too_many_nodes",
                "warning",
                file_path,
                "Scene has %d nodes, above the %d node threshold." % [node_count, scene_node_count_threshold],
                "Consider splitting the scene or reviewing generated node structure."
            )

func _check_empty_folders() -> void:
    for folder_path in folders:
        if folder_path == "res://":
            continue
        if _is_folder_empty(folder_path):
            _add_finding("empty_folder", "info", folder_path, "Folder is empty.", "Remove it or add a .gdignore if it is intentionally empty.")

func _check_unused_files() -> void:
    for file_path in files:
        if file_path == "res://icon.svg":
            continue
        if not _has_extension(file_path, UNUSED_CANDIDATE_EXTENSIONS):
            continue
        if not referenced_paths.has(file_path):
            _add_finding(
                "possibly_unused_file",
                "info",
                file_path,
                "File is not referenced by scanned text resources.",
                "Verify manually before deleting. Dynamic loads may not be detected."
            )

func _build_summary() -> Dictionary:
    var summary := {"errors": 0, "warnings": 0, "info": 0}
    for finding in findings:
        match finding.get("severity", "info"):
            "error":
                summary.errors += 1
            "warning":
                summary.warnings += 1
            _:
                summary.info += 1
    return summary

func _add_finding(id: String, severity: String, path: String, message: String, recommendation: String) -> void:
    findings.append({
        "id": id,
        "severity": severity,
        "title": id.capitalize(),
        "path": path,
        "message": message,
        "recommendation": recommendation
    })

func _append_findings(new_findings: Array[Dictionary]) -> void:
    findings.append_array(new_findings)

func _has_extension(path: String, extensions: Array) -> bool:
    return path.get_extension().to_lower() in extensions

func _is_gdscript_resource_load_line(line: String) -> bool:
    return line.contains("preload(") or line.contains("load(") or line.contains("ResourceLoader.load(")

func _extract_resource_path(text: String) -> String:
    var start := text.find("res://")
    if start == -1:
        return ""

    var end := text.find("\"", start)
    if end == -1:
        return text.substr(start)
    return text.substr(start, end - start)

func _extract_resource_paths_from_line(line: String) -> Array:
    var resource_paths: Array = []
    var search_from := 0

    while true:
        var start := line.find("res://", search_from)
        if start == -1:
            break

        var end := start
        while end < line.length():
            var character := line[end]
            if character == '"' or character == "'" or character == ")" or character == "]" or character == ",":
                break
            end += 1

        resource_paths.append(line.substr(start, end - start).strip_edges())
        search_from = end + 1

    return resource_paths

func _is_folder_empty(path: String) -> bool:
    var dir := DirAccess.open(path)
    if dir == null:
        return false

    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if not entry.begins_with("."):
            dir.list_dir_end()
            return false
        entry = dir.get_next()
    dir.list_dir_end()
    return true

func _is_excluded_directory(path: String) -> bool:
    return path in excluded_directories

func _read_text_file(path: String) -> String:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return ""
    return file.get_as_text()

func _collect_markdown_references(markdown_file_path: String, text: String, markdown_regex: RegEx) -> void:
    var in_fenced_code_block := false

    for line in text.split("\n"):
        var trimmed_line := line.strip_edges()
        if trimmed_line.begins_with("```") or trimmed_line.begins_with("~~~"):
            in_fenced_code_block = not in_fenced_code_block
            continue

        if in_fenced_code_block:
            continue

        for result in markdown_regex.search_all(line):
            var raw_path := result.get_string(1).strip_edges()
            var resolved_path := _resolve_markdown_path(markdown_file_path, raw_path)
            if resolved_path != "":
                referenced_paths[resolved_path] = true

func _resolve_markdown_path(markdown_file_path: String, raw_path: String) -> String:
    if raw_path == "":
        return ""

    var clean_path := raw_path.split("#")[0].split("?")[0].strip_edges()
    if clean_path == "":
        return ""
    if clean_path.begins_with("http://") or clean_path.begins_with("https://"):
        return ""
    if clean_path.begins_with("mailto:") or clean_path.begins_with("data:"):
        return ""

    if clean_path.begins_with("res://"):
        return clean_path

    var project_root_candidate := "res://" + clean_path.trim_prefix("./")
    if _resource_path_exists(project_root_candidate):
        return project_root_candidate

    var base_dir := markdown_file_path.get_base_dir()
    var global_path := ProjectSettings.globalize_path(base_dir.path_join(clean_path))
    var localized_path := ProjectSettings.localize_path(global_path)
    if _resource_path_exists(localized_path):
        return localized_path
    return ""

func _resource_path_exists(resource_path: String) -> bool:
    if FileAccess.file_exists(resource_path):
        return true

    return DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(resource_path))

func _filter_ignored_findings() -> void:
    if ignored_findings.is_empty():
        return

    var filtered_findings: Array[Dictionary] = []
    for finding in findings:
        if not ignored_findings.has(str(finding.get("id", ""))):
            filtered_findings.append(finding)
    findings = filtered_findings

func _get_int_setting(setting_name: String, default_value: int) -> int:
    if not ProjectSettings.has_setting(setting_name):
        return default_value

    return int(ProjectSettings.get_setting(setting_name, default_value))

func _get_string_array_setting(setting_name: String, default_value: Array) -> Array:
    if not ProjectSettings.has_setting(setting_name):
        return default_value.duplicate()

    var raw_value: Variant = ProjectSettings.get_setting(setting_name, default_value)
    var values: Array[String] = []

    if raw_value is PackedStringArray:
        for entry in raw_value:
            values.append(_normalize_resource_setting_path(str(entry)))
        return values

    if raw_value is Array:
        for entry in raw_value:
            values.append(_normalize_resource_setting_path(str(entry)))
        return values

    var text_value := str(raw_value).strip_edges()
    if text_value == "":
        return []

    for entry in text_value.split(",", false):
        values.append(_normalize_resource_setting_path(entry))
    return values

func _normalize_resource_setting_path(path: String) -> String:
    var trimmed_path := path.strip_edges()
    if trimmed_path == "":
        return ""
    if trimmed_path.begins_with("res://"):
        return trimmed_path.trim_suffix("/")
    return ("res://" + trimmed_path.trim_prefix("./")).trim_suffix("/")

func _build_ignored_findings_lookup(ids: Array) -> Dictionary:
    var lookup := {}
    for id in ids:
        if id != "":
            lookup[id] = true
    return lookup

func _load_tool_version() -> String:
    var config := ConfigFile.new()
    var error := config.load("res://addons/project_doctor_mini/plugin.cfg")
    if error != OK:
        return TOOL_VERSION_FALLBACK

    return str(config.get_value("plugin", "version", TOOL_VERSION_FALLBACK))

func _sort_findings() -> void:
    findings.sort_custom(_compare_findings)

func _compare_findings(left: Dictionary, right: Dictionary) -> bool:
    var left_severity := SEVERITY_ORDER.get(left.get("severity", "info"), 2)
    var right_severity := SEVERITY_ORDER.get(right.get("severity", "info"), 2)
    if left_severity != right_severity:
        return left_severity < right_severity

    var left_path := str(left.get("path", ""))
    var right_path := str(right.get("path", ""))
    if left_path != right_path:
        return left_path < right_path

    return str(left.get("id", "")) < str(right.get("id", ""))
