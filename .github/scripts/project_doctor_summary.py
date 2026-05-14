from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any


VALID_MODES = {"report-only", "warn", "fail-on-errors"}
COMMENT_MARKER = "<!-- godot-project-doctor-mini -->"


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize a Project Doctor JSON report for GitHub Actions.")
    parser.add_argument("--report", required=True, help="Path to reports/project-doctor-report.json")
    parser.add_argument("--mode", required=True, choices=sorted(VALID_MODES), help="CI mode to evaluate")
    parser.add_argument("--artifact-name", default="project-doctor-reports", help="Artifact name used in workflow output")
    args = parser.parse_args()

    report = _load_report(args.report)
    summary = report.get("summary", {})
    errors = _as_int(summary.get("errors", 0))
    warnings = _as_int(summary.get("warnings", 0))
    info = _as_int(summary.get("info", 0))
    total_findings = errors + warnings + info
    scan_duration_ms = _as_int(report.get("scan_duration_ms", 0))

    should_fail, mode_status, status_title = _evaluate_mode(args.mode, errors, warnings, info)
    summary_markdown = _build_summary_markdown(
        mode=args.mode,
        mode_status=mode_status,
        status_title=status_title,
        errors=errors,
        warnings=warnings,
        info=info,
        scan_duration_ms=scan_duration_ms,
        artifact_name=args.artifact_name,
    )
    comment_markdown = _build_comment_markdown(
        mode=args.mode,
        status_title=status_title,
        errors=errors,
        warnings=warnings,
        info=info,
        scan_duration_ms=scan_duration_ms,
        artifact_name=args.artifact_name,
    )

    _write_outputs(
        {
            "errors": str(errors),
            "warnings": str(warnings),
            "info": str(info),
            "scan_duration_ms": str(scan_duration_ms),
            "total_findings": str(total_findings),
            "should_fail": "true" if should_fail else "false",
            "mode_status": mode_status,
            "status_title": status_title,
            "summary_markdown": summary_markdown,
            "comment_markdown": comment_markdown,
            "comment_marker": COMMENT_MARKER,
        }
    )

    print(status_title)
    return 0


def _load_report(report_path: str) -> dict[str, Any]:
    try:
        with open(report_path, "r", encoding="utf-8") as handle:
            report = json.load(handle)
    except FileNotFoundError as exc:
        raise SystemExit(f"Project Doctor report not found: {report_path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Project Doctor report is not valid JSON: {exc}") from exc

    if not isinstance(report, dict):
        raise SystemExit("Project Doctor report must be a JSON object.")
    return report


def _evaluate_mode(mode: str, errors: int, warnings: int, info: int) -> tuple[bool, str, str]:
    total_findings = errors + warnings + info

    if mode == "fail-on-errors":
        if errors > 0:
            return True, "failed", f"Failing CI: {errors} error finding(s) reported"
        if total_findings > 0:
            return False, "passed", "Passing CI: warnings/info reported, but no error findings"
        return False, "passed", "Passing CI: no findings reported"

    if mode == "warn":
        if total_findings > 0:
            return False, "warn", f"Warnings emitted: {errors} error(s), {warnings} warning(s), {info} info finding(s)"
        return False, "passed", "Passing CI: no findings reported"

    if total_findings > 0:
        return False, "reported", f"Report only: {errors} error(s), {warnings} warning(s), {info} info finding(s)"
    return False, "reported", "Report only: no findings reported"


def _build_summary_markdown(
    *,
    mode: str,
    mode_status: str,
    status_title: str,
    errors: int,
    warnings: int,
    info: int,
    scan_duration_ms: int,
    artifact_name: str,
) -> str:
    lines = [
        "## Project Doctor",
        "",
        f"Status: **{status_title}**",
        f"Mode: `{mode}`",
        f"Mode Result: `{mode_status}`",
        f"Scan Duration: `{scan_duration_ms} ms`",
        "",
        "| Severity | Count |",
        "| --- | ---: |",
        f"| Error | {errors} |",
        f"| Warning | {warnings} |",
        f"| Info | {info} |",
        "",
        f"Artifact: download `{artifact_name}` from this workflow run.",
        "Reports: `reports/project-doctor-report.md` and `reports/project-doctor-report.json`.",
    ]
    return "\n".join(lines)


def _build_comment_markdown(
    *,
    mode: str,
    status_title: str,
    errors: int,
    warnings: int,
    info: int,
    scan_duration_ms: int,
    artifact_name: str,
) -> str:
    lines = [
        COMMENT_MARKER,
        "## Project Doctor",
        "",
        f"Status: **{status_title}**",
        f"Mode: `{mode}`",
        f"Scan Duration: `{scan_duration_ms} ms`",
        "",
        "| Severity | Count |",
        "| --- | ---: |",
        f"| Error | {errors} |",
        f"| Warning | {warnings} |",
        f"| Info | {info} |",
        "",
        f"Artifact: download `{artifact_name}` from this workflow run.",
        "Reports: `reports/project-doctor-report.md` and `reports/project-doctor-report.json`.",
    ]
    return "\n".join(lines)


def _write_outputs(values: dict[str, str]) -> None:
    github_output = os.environ.get("GITHUB_OUTPUT")
    if not github_output:
        return

    with open(github_output, "a", encoding="utf-8") as handle:
        for key, value in values.items():
            if "\n" in value:
                delimiter = "PROJECT_DOCTOR_EOF"
                handle.write(f"{key}<<{delimiter}\n{value}\n{delimiter}\n")
            else:
                handle.write(f"{key}={value}\n")


def _as_int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        raise SystemExit(f"Expected an integer-compatible value, received: {value!r}")


if __name__ == "__main__":
    sys.exit(main())
