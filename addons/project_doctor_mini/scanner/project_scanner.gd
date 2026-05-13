@tool
extends RefCounted

const ProcessUsageCheck = preload("res://addons/project_doctor_mini/scanner/checks/process_usage_check.gd")
const ExportPresetsCheck = preload("res://addons/project_doctor_mini/scanner/checks/export_presets_check.gd")

const LARGE_TEXTURE_THRESHOLD := 2048
const SCENE_NODE_COUNT_THRESHOLD := 250
const EXCLUDED_DIRECTORIES := ["res://reports"]
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

func scan() -> Dictionary:
    var start_ticks := Time.get_ticks_msec()

    findings.clear()
    files.clear()
    folders.clear()
    referenced_paths.clear()

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
    var resource_regex := RegEx.new()
    resource_regex.compile("res://[A-Za-z0-9_./@%+-]+")

    var markdown_regex := RegEx.new()
    markdown_regex.compile("!?\\[[^\\]]*\\]\\(([^)]+)\\)")

    for file_path in files:
        var extension := file_path.get_extension().to_lower()
        if extension != "gd" and not _has_extension(file_path, RESOURCE_TEXT_EXTENSIONS):
            continue

        var text := _read_text_file(file_path)
        if text == "":
            continue

        for line in text.split("\n"):
            if extension == "md":
                _collect_markdown_references(file_path, line, markdown_regex)

            if extension == "gd" and not _is_gdscript_resource_load_line(line):
                continue

            for result in resource_regex.search_all(line):
                var resource_path := result.get_string().strip_edges()
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
        if not FileAccess.file_exists(resource_path) and not DirAccess.dir_exists_absolute(resource_path):
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
        if width > LARGE_TEXTURE_THRESHOLD or height > LARGE_TEXTURE_THRESHOLD:
            _add_finding(
                "large_texture",
                "warning",
                file_path,
                "Texture is %dx%d, above the %dpx threshold." % [width, height, LARGE_TEXTURE_THRESHOLD],
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

        if node_count > SCENE_NODE_COUNT_THRESHOLD:
            _add_finding(
                "scene_too_many_nodes",
                "warning",
                file_path,
                "Scene has %d nodes, above the %d node threshold." % [node_count, SCENE_NODE_COUNT_THRESHOLD],
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
    return path in EXCLUDED_DIRECTORIES

func _read_text_file(path: String) -> String:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return ""
    return file.get_as_text()

func _collect_markdown_references(markdown_file_path: String, line: String, markdown_regex: RegEx) -> void:
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
    if FileAccess.file_exists(project_root_candidate) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(project_root_candidate)):
        return project_root_candidate

    var base_dir := markdown_file_path.get_base_dir()
    var global_path := ProjectSettings.globalize_path(base_dir.path_join(clean_path))
    return ProjectSettings.localize_path(global_path)

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
