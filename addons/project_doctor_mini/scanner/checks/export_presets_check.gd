@tool
extends RefCounted

func run() -> Array[Dictionary]:
    if FileAccess.file_exists("res://export_presets.cfg"):
        return []

    return [ {
        "id": "export_presets_missing",
        "severity": "warning",
        "title": "Export Presets Missing",
        "path": "res://export_presets.cfg",
        "message": "Export presets are missing.",
        "recommendation": "Create export presets before release builds."
    }]
