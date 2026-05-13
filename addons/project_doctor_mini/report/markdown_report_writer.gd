@tool
extends RefCounted

func write(report: Dictionary, output_path: String) -> void:
    var file := FileAccess.open(output_path, FileAccess.WRITE)
    if file == null:
        push_error("Could not write Markdown report: %s" % output_path)
        return

    var summary: Dictionary = report.get("summary", {})
    var lines: Array[String] = []
    lines.append("# Godot Project Doctor Report")
    lines.append("")
    lines.append("Generated: %s" % report.get("generated_at", ""))
    lines.append("Project: %s" % report.get("project_root", "res://"))
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append("| Severity | Count |")
    lines.append("| --- | ---: |")
    lines.append("| Error | %d |" % summary.get("errors", 0))
    lines.append("| Warning | %d |" % summary.get("warnings", 0))
    lines.append("| Info | %d |" % summary.get("info", 0))
    lines.append("")
    lines.append("## Findings")
    lines.append("")

    var findings: Array = report.get("findings", [])
    if findings.is_empty():
        lines.append("No findings.")
    else:
        for finding: Dictionary in findings:
            lines.append("### %s: %s" % [str(finding.get("severity", "info")).capitalize(), finding.get("title", "Finding")])
            lines.append("")
            lines.append("- Path: `%s`" % finding.get("path", ""))
            lines.append("- Check: `%s`" % finding.get("id", "unknown"))
            lines.append("- Message: %s" % finding.get("message", ""))
            lines.append("- Recommendation: %s" % finding.get("recommendation", ""))
            lines.append("")

    file.store_string("\n".join(lines))
