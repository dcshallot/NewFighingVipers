#!/usr/bin/env python3
"""Cross-platform, read-only project doctor for archive and replay profiles."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import platform
import plistlib
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any
from urllib.parse import unquote

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None

SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parents[2]
DEFAULT_CONFIG = SCRIPT_PATH.with_name("toolchain.local.toml")
EXAMPLE_CONFIG = SCRIPT_PATH.with_name("toolchain.example.toml")
SUPPORTED_SCHEMA_VERSION = 2
PROFILES = {"archive", "blender-replay", "windows-extraction", "unity-dev"}
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
MARKDOWN_LINK_RE = re.compile(r"\[[^]]*\]\(([^)]+)\)")
ABSOLUTE_PATH_RE = re.compile(r"(?:/Users/[^/\s]+/|[A-Za-z]:\\Users\\[^\\\s]+\\)")

DEFAULTS: dict[str, Any] = {
    "schema_version": SUPPORTED_SCHEMA_VERSION,
    "default_profile": "archive",
    "project": {
        "status": "archived-mac-blender-test",
        "local_data_root": "LocalData",
        "unity_project": "Game",
        "reference_manifest": "Reference/Manifests/honey-reference-manifest.csv",
        "intake_manifest": "Reference/Manifests/honey-intake-2026-09-09.csv",
        "selected_views_manifest": "Reference/Manifests/honey-p1-selected-views.csv",
        "asset_manifest": "Reference/Manifests/honey-asset-manifest.csv",
        "tool_manifest": "Tools/tool-manifest.csv",
    },
    "storage": {"external_source_root": "", "external_source_key": "vf-assets-input"},
    "versions": {
        "python_min": "3.11",
        "git_min": "2.30",
        "git_lfs_min": "3.0",
        "ffmpeg_min": "6.0",
        "powershell_min": "7.0",
        "blender_exact": "5.2.1",
        "mpfb_exact": "2.0.17",
        "unity_exact": "6000.6.0f1",
        "unity_render_pipeline": "URP",
        "unity_render_pipeline_exact": "17.6.0",
    },
    "commands": {
        "git": "git",
        "git_lfs": "git-lfs",
        "ffmpeg": "ffmpeg",
        "powershell": "pwsh",
        "blender": "",
        "unity": "",
    },
    "blender": {"mpfb_module": "bl_ext.user_default.mpfb", "mpfb_manifest": ""},
}

MANIFEST_SCHEMAS: dict[str, dict[str, Any]] = {
    "reference": {
        "id": "source_id",
        "required": {
            "schema_version", "source_id", "parent_source_id", "character_state", "view",
            "source_type", "source_url", "storage_key", "relative_path", "availability",
            "sha256", "rights_status", "allowed_use", "decision", "related_note", "notes",
        },
        "required_values": {"schema_version", "source_id", "character_state", "source_type", "storage_key", "availability", "decision"},
    },
    "intake": {
        "id": "intake_id",
        "required": {
            "schema_version", "intake_id", "parent_source_id", "original_name", "classification",
            "sha256", "size_bytes", "storage_key", "relative_path", "availability", "decision", "notes",
        },
        "required_values": {"schema_version", "intake_id", "original_name", "classification", "sha256", "size_bytes", "storage_key", "availability", "decision"},
    },
    "selected": {
        "id": "reference_id",
        "required": {
            "schema_version", "reference_id", "parent_source_id", "intake_id", "view_role", "priority",
            "storage_key", "relative_path", "availability", "sha256", "selection_status", "notes",
        },
        "required_values": {"schema_version", "reference_id", "parent_source_id", "intake_id", "view_role", "priority", "storage_key", "availability", "sha256", "selection_status"},
    },
    "asset": {
        "id": "asset_id",
        "required": {
            "schema_version", "asset_id", "stage", "source_path", "source_sha256", "source_availability",
            "review_artifact_path", "review_sha256", "review_availability", "approved_export_path",
            "approved_export_sha256", "export_availability", "owner", "reviewer", "blender_version",
            "generator", "lfs_status", "lock_status", "review_status", "git_commit_or_tag", "release_status", "notes",
        },
        "required_values": {"schema_version", "asset_id", "stage", "source_availability", "review_availability", "export_availability", "review_status", "release_status"},
    },
    "tool": {
        "id": "tool_path",
        "required": {
            "schema_version", "tool_path", "profiles", "platform", "status", "archive_only", "destructive",
            "network_access", "reproducibility", "dependencies", "input", "output", "side_effect",
            "validation", "alternative", "evidence_note",
        },
        "required_values": {"schema_version", "tool_path", "profiles", "platform", "status", "archive_only", "destructive", "network_access", "reproducibility"},
    },
}

AVAILABILITY = {"local", "external", "missing", "deleted", "not-applicable"}
TOOL_STATUS = {"stable", "experimental", "rejected", "reference"}
BOOLEAN_TEXT = {"true", "false"}


class Report:
    def __init__(self, json_mode: bool = False) -> None:
        self.json_mode = json_mode
        self.records: list[dict[str, str]] = []
        self.failures = 0
        self.warnings = 0

    def emit(self, level: str, label: str, message: str) -> None:
        if level == "FAIL":
            self.failures += 1
        elif level == "WARN":
            self.warnings += 1
        self.records.append({"level": level, "label": label, "message": message})
        if not self.json_mode:
            print(f"[{level}] {label}: {message}")

    def pass_(self, label: str, message: str) -> None: self.emit("PASS", label, message)
    def warn(self, label: str, message: str) -> None: self.emit("WARN", label, message)
    def fail(self, label: str, message: str) -> None: self.emit("FAIL", label, message)
    def info(self, label: str, message: str) -> None: self.emit("INFO", label, message)

    def result(self, profile: str) -> dict[str, Any]:
        return {"profile": profile, "failures": self.failures, "warnings": self.warnings, "checks": self.records}


def deep_merge(base: dict[str, Any], overlay: dict[str, Any]) -> dict[str, Any]:
    merged: dict[str, Any] = {}
    for key, value in base.items():
        merged[key] = deep_merge(value, {}) if isinstance(value, dict) else value
    for key, value in overlay.items():
        merged[key] = deep_merge(merged.get(key, {}), value) if isinstance(value, dict) and isinstance(merged.get(key), dict) else value
    return merged


def version_tuple(value: str) -> tuple[int, ...]:
    match = re.search(r"(\d+(?:\.\d+)+)", value)
    return tuple(int(part) for part in match.group(1).split(".")) if match else ()


def version_at_least(actual: str, minimum: str) -> bool:
    a, m = version_tuple(actual), version_tuple(minimum)
    if not a or not m: return False
    length = max(len(a), len(m))
    return a + (0,) * (length - len(a)) >= m + (0,) * (length - len(m))


def load_config(path: Path, report: Report) -> dict[str, Any] | None:
    if tomllib is None:
        report.fail("config", "Python 3.11+ with tomllib is required")
        return None
    try:
        with path.open("rb") as handle: loaded = tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        report.fail("config", f"cannot read TOML ({exc.__class__.__name__})")
        return None
    if loaded.get("schema_version") != SUPPORTED_SCHEMA_VERSION:
        report.fail("config", f"schema_version must be {SUPPORTED_SCHEMA_VERSION}")
        return None
    report.pass_("config", "local configuration loaded" if path.name.endswith("local.toml") else "example configuration loaded")
    return deep_merge(DEFAULTS, loaded)


def resolve_command(configured: str, fallbacks: tuple[Path, ...] = ()) -> str | None:
    if configured:
        candidate = Path(os.path.expanduser(configured))
        if candidate.is_file(): return str(candidate)
        found = shutil.which(configured)
        if found: return found
    for fallback in fallbacks:
        if fallback.is_file(): return str(fallback)
    return None


def run_version(command: str, args: list[str]) -> str | None:
    try:
        result = subprocess.run([command, *args], capture_output=True, text=True, timeout=10, env={**os.environ, "LC_ALL": "C"})
    except (OSError, subprocess.SubprocessError):
        return None
    output = "\n".join(part for part in (result.stdout, result.stderr) if part).strip()
    return output.splitlines()[0] if output else None


def check_command(report: Report, label: str, configured: str, args: list[str], minimum: str, *, required: bool = True, fallbacks: tuple[Path, ...] = ()) -> str | None:
    command = resolve_command(configured, fallbacks)
    if not command:
        (report.fail if required else report.warn)(label, f"not found; requires {minimum}+")
        return None
    output = run_version(command, args)
    if not output or not version_at_least(output, minimum):
        (report.fail if required else report.warn)(label, f"version check failed; requires {minimum}+")
        return command
    match = re.search(r"\d+(?:\.\d+)+", output)
    report.pass_(label, f"version {match.group(0) if match else 'verified'}")
    return command


def check_python(report: Report, minimum: str) -> None:
    actual = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    (report.pass_ if version_at_least(actual, minimum) else report.fail)("Python", f"version {actual}; requires {minimum}+")


def check_platform(report: Report, profile: str) -> None:
    system, machine = platform.system(), platform.machine().lower()
    if profile == "archive":
        if system in {"Darwin", "Windows", "Linux"}: report.pass_("platform", f"{system} {machine or 'unknown'}")
        else: report.warn("platform", f"unverified system {system}")
    elif profile == "blender-replay":
        if system == "Darwin" and machine in {"arm64", "aarch64"}: report.pass_("platform", "validated macOS Apple Silicon")
        else: report.warn("platform", f"Blender replay is only validated on macOS arm64; current {system} {machine}")
    elif profile == "windows-extraction":
        if system == "Windows": report.pass_("platform", "Windows")
        else: report.fail("platform", "windows-extraction requires Windows")
    elif profile == "unity-dev":
        report.info("platform", f"Unity development profile on {system} {machine}")


def read_blender_version_from_plist() -> str | None:
    plist = Path("/Applications/Blender.app/Contents/Info.plist")
    if not plist.is_file(): return None
    try:
        with plist.open("rb") as handle: data = plistlib.load(handle)
    except (OSError, plistlib.InvalidFileException): return None
    value = data.get("CFBundleShortVersionString") or data.get("CFBundleVersion")
    return str(value) if value else None


def check_blender(report: Report, config: dict[str, Any]) -> None:
    expected = config["versions"]["blender_exact"]
    detected = read_blender_version_from_plist() if platform.system() == "Darwin" else None
    command = resolve_command(config["commands"].get("blender", ""), (Path("/Applications/Blender.app/Contents/MacOS/Blender"),))
    if not detected and command: detected = run_version(command, ["--version"])
    if version_tuple(detected or "") == version_tuple(expected): report.pass_("Blender", f"version {expected}")
    else: report.fail("Blender", f"requires exact version {expected}")


def check_mpfb(report: Report, config: dict[str, Any]) -> None:
    expected = config["versions"]["mpfb_exact"]
    explicit = config.get("blender", {}).get("mpfb_manifest", "")
    candidates: list[Path] = []
    if explicit: candidates.append(Path(os.path.expanduser(explicit)))
    if platform.system() == "Darwin":
        series = ".".join(str(part) for part in version_tuple(config["versions"]["blender_exact"])[:2])
        candidates.append(Path.home() / "Library/Application Support/Blender" / series / "extensions/user_default/mpfb/blender_manifest.toml")
    manifest = next((path for path in candidates if path.is_file()), None)
    if not manifest or tomllib is None:
        report.fail("MPFB", f"manifest not found; requires {expected}")
        return
    try:
        with manifest.open("rb") as handle: version = str(tomllib.load(handle).get("version", ""))
    except (OSError, tomllib.TOMLDecodeError): version = ""
    (report.pass_ if version == expected else report.fail)("MPFB", f"version {version or 'unknown'}; requires {expected}")


def check_unity(report: Report, config: dict[str, Any]) -> None:
    project = REPO_ROOT / config["project"]["unity_project"]
    expected = config["versions"]["unity_exact"]
    version_file = project / "ProjectSettings/ProjectVersion.txt"
    package_file = project / "Packages/manifest.json"
    if not version_file.is_file() or not package_file.is_file():
        report.fail("Unity project", "not initialized; unity-dev is dormant until a new project is approved")
        return
    text = version_file.read_text(encoding="utf-8")
    match = re.search(r"m_EditorVersion:\s*(\S+)", text)
    actual = match.group(1) if match else "unknown"
    if actual == expected: report.pass_("Unity project", f"version {actual}")
    else: report.fail("Unity project", f"version {actual}; requires {expected}")
    try: dependencies = json.loads(package_file.read_text(encoding="utf-8")).get("dependencies", {})
    except (OSError, json.JSONDecodeError): dependencies = {}
    urp = dependencies.get("com.unity.render-pipelines.universal")
    expected_urp = config["versions"]["unity_render_pipeline_exact"]
    (report.pass_ if urp == expected_urp else report.fail)("Unity URP", f"version {urp or 'missing'}; requires {expected_urp}")


def manifest_paths(config: dict[str, Any]) -> dict[str, str]:
    project = config["project"]
    return {
        "reference": project["reference_manifest"], "intake": project["intake_manifest"],
        "selected": project["selected_views_manifest"], "asset": project["asset_manifest"],
        "tool": project["tool_manifest"],
    }


def load_csv(relative: str, report: Report) -> list[dict[str, str]] | None:
    path = REPO_ROOT / relative
    try:
        with path.open("r", encoding="utf-8-sig", newline="") as handle: return list(csv.DictReader(handle))
    except (OSError, csv.Error):
        report.fail("manifest", f"cannot parse {relative}")
        return None


def check_manifests(report: Report, config: dict[str, Any]) -> dict[str, list[dict[str, str]]]:
    loaded: dict[str, list[dict[str, str]]] = {}
    for name, relative in manifest_paths(config).items():
        rows = load_csv(relative, report)
        if rows is None: continue
        loaded[name] = rows
        schema = MANIFEST_SCHEMAS[name]
        fields = set(rows[0].keys()) if rows else set(next(csv.reader((REPO_ROOT / relative).open(encoding="utf-8-sig")), []))
        missing_fields = sorted(schema["required"] - fields)
        if missing_fields:
            report.fail(f"manifest:{name}", "missing fields: " + ", ".join(missing_fields)); continue
        ids = [row[schema["id"]].strip() for row in rows]
        duplicate_ids = sorted({value for value in ids if ids.count(value) > 1})
        missing_values = sorted({row[schema["id"]] for row in rows for field in schema["required_values"] if not row.get(field, "").strip()})
        bad_schema = sorted({row[schema["id"]] for row in rows if row.get("schema_version") != str(SUPPORTED_SCHEMA_VERSION)})
        bad_sha = sorted({row[schema["id"]] for row in rows for key, value in row.items() if "sha256" in key and value and not SHA256_RE.fullmatch(value)})
        problems = []
        if duplicate_ids: problems.append("duplicate IDs: " + ", ".join(duplicate_ids))
        if missing_values: problems.append("missing required values: " + ", ".join(missing_values))
        if bad_schema: problems.append("wrong schema version: " + ", ".join(bad_schema))
        if bad_sha: problems.append("invalid SHA-256: " + ", ".join(bad_sha))
        if name == "tool":
            bad_status = sorted({row["tool_path"] for row in rows if row["status"] not in TOOL_STATUS})
            bad_bool = sorted({row["tool_path"] for row in rows if row["archive_only"] not in BOOLEAN_TEXT or row["destructive"] not in BOOLEAN_TEXT or row["network_access"] not in BOOLEAN_TEXT})
            bad_profiles = sorted({row["tool_path"] for row in rows if any(value.strip() not in PROFILES for value in row["profiles"].split(","))})
            if bad_status: problems.append("invalid status: " + ", ".join(bad_status))
            if bad_bool: problems.append("invalid booleans: " + ", ".join(bad_bool))
            if bad_profiles: problems.append("invalid profiles: " + ", ".join(bad_profiles))
        else:
            for availability_field in (key for key in fields if key.endswith("availability") or key == "availability"):
                invalid = sorted({row[schema["id"]] for row in rows if row.get(availability_field) not in AVAILABILITY})
                if invalid: problems.append(f"invalid {availability_field}: " + ", ".join(invalid))
        if problems: report.fail(f"manifest:{name}", "; ".join(problems))
        else: report.pass_(f"manifest:{name}", f"schema v2, {len(rows)} rows")
    return loaded


def check_cross_references(report: Report, config: dict[str, Any], tables: dict[str, list[dict[str, str]]]) -> None:
    intake_rows = {row["intake_id"]: row for row in tables.get("intake", [])}
    references = {row["source_id"] for row in tables.get("reference", [])}
    bad_selected = []
    for row in tables.get("selected", []):
        intake = intake_rows.get(row["intake_id"])
        if (
            row["parent_source_id"] not in references
            or intake is None
            or intake["parent_source_id"] != row["parent_source_id"]
            or intake["sha256"] != row["sha256"]
            or intake["storage_key"] != row["storage_key"]
            or intake["relative_path"] != row["relative_path"]
            or intake["availability"] != row["availability"]
        ):
            bad_selected.append(row["reference_id"])
    bad_intake = [row["intake_id"] for row in tables.get("intake", []) if row["parent_source_id"] and row["parent_source_id"] not in references]
    storage_keys = {row["storage_key"] for table in ("reference", "intake", "selected") for row in tables.get(table, [])}
    invalid_storage = sorted(storage_keys - {"repo", "local-data", "vf-assets-input", "web", "unknown"})
    expected_external_key = config.get("storage", {}).get("external_source_key", "")
    external_key_mismatch = sorted({row["intake_id"] for row in tables.get("intake", []) if row["availability"] == "external" and row["storage_key"] != expected_external_key})
    if bad_selected or bad_intake or invalid_storage or external_key_mismatch:
        report.fail("manifest references", f"selected={bad_selected}, intake={bad_intake}, storage={invalid_storage}, external={external_key_mismatch}")
    else:
        report.pass_("manifest references", "foreign keys, hashes, storage and availability valid")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""): digest.update(chunk)
    return digest.hexdigest()


def content_or_lfs_pointer_matches(path: Path, expected: str) -> bool:
    if path.stat().st_size < 1024:
        text = path.read_text(encoding="utf-8", errors="ignore")
        oid = re.search(r"^oid sha256:([0-9a-f]{64})$", text, re.MULTILINE)
        if oid:
            return oid.group(1) == expected
    return sha256(path) == expected


def check_manifest_files(report: Report, tables: dict[str, list[dict[str, str]]]) -> None:
    failures: list[str] = []
    for row in tables.get("asset", []):
        for path_key, hash_key, availability_key in (
            ("source_path", "source_sha256", "source_availability"),
            ("review_artifact_path", "review_sha256", "review_availability"),
            ("approved_export_path", "approved_export_sha256", "export_availability"),
        ):
            relative, availability = row.get(path_key, ""), row.get(availability_key, "")
            if availability == "local":
                path = REPO_ROOT / relative
                if not path.is_file() or (row.get(hash_key) and not content_or_lfs_pointer_matches(path, row[hash_key])): failures.append(f"{row['asset_id']}:{path_key}")
    for row in tables.get("tool", []):
        if not (REPO_ROOT / row["tool_path"]).is_file(): failures.append(row["tool_path"])
        evidence = row.get("evidence_note", "")
        if evidence and not (REPO_ROOT / evidence).is_file(): failures.append(evidence)
    if failures: report.fail("manifest files", "missing/hash mismatch: " + ", ".join(failures))
    else: report.pass_("manifest files", "local files and hashes valid")


def check_markdown_links(report: Report) -> None:
    failures: list[str] = []
    for path in [REPO_ROOT / "README.md", *sorted((REPO_ROOT / "Docs").rglob("*.md")), *sorted((REPO_ROOT / "Reference").rglob("*.md")), *sorted((REPO_ROOT / "Tools").rglob("*.md"))]:
        text = path.read_text(encoding="utf-8")
        text_without_code = re.sub(r"```.*?```", "", text, flags=re.DOTALL)
        for raw in MARKDOWN_LINK_RE.findall(text_without_code):
            link = unquote(raw.strip().split("#", 1)[0])
            if not link or link.startswith(("http://", "https://", "mailto:")): continue
            if not (path.parent / link).resolve().exists(): failures.append(f"{path.relative_to(REPO_ROOT)} -> {raw}")
    if failures: report.fail("Markdown links", "; ".join(failures[:20]))
    else: report.pass_("Markdown links", "all local links valid")


def check_absolute_paths(report: Report) -> None:
    failures: list[str] = []
    for root in (REPO_ROOT / "Docs", REPO_ROOT / "Tools"):
        for path in root.rglob("*"):
            if path == SCRIPT_PATH: continue
            if not path.is_file() or path.suffix.lower() not in {".md", ".py", ".ps1", ".cmd", ".toml", ".csv", ".json"}: continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            if ABSOLUTE_PATH_RE.search(text): failures.append(str(path.relative_to(REPO_ROOT)))
    if failures: report.fail("personal paths", "found in: " + ", ".join(failures))
    else: report.pass_("personal paths", "none in active docs/tools")


def check_lfs(report: Report, git: str | None, tables: dict[str, list[dict[str, str]]]) -> None:
    if not git:
        report.warn("Git LFS attributes", "Git unavailable")
        return
    failures = []
    for row in tables.get("asset", []):
        if row.get("source_availability") != "local" or not row.get("source_path", "").endswith((".blend", ".fbx", ".psd", ".spp")): continue
        result = subprocess.run([git, "check-attr", "filter", "--", row["source_path"]], cwd=REPO_ROOT, capture_output=True, text=True)
        if not result.stdout.rstrip().endswith(": lfs"): failures.append(row["source_path"])
    if failures: report.fail("Git LFS attributes", "not tracked by rule: " + ", ".join(failures))
    else: report.pass_("Git LFS attributes", "local binary assets match LFS rules")


def check_tool_inventory(report: Report, tables: dict[str, list[dict[str, str]]]) -> None:
    suffixes = {".py", ".ps1", ".cmd", ".lua", ".disabled", ".json", ".toml", ".txt"}
    expected = {path.relative_to(REPO_ROOT).as_posix() for path in (REPO_ROOT / "Tools").rglob("*") if path.is_file() and path.suffix.lower() in suffixes and path.name != "toolchain.local.toml" and not {"vendor", "cache", "__pycache__"}.intersection(path.parts)}
    listed = {row["tool_path"] for row in tables.get("tool", [])}
    missing, stale = sorted(expected - listed), sorted(listed - expected)
    if missing or stale: report.fail("tool inventory", f"missing={missing}; stale={stale}")
    else: report.pass_("tool inventory", f"covers {len(expected)} files")


def check_external_data(report: Report, config: dict[str, Any], tables: dict[str, list[dict[str, str]]]) -> None:
    configured_root = config.get("storage", {}).get("external_source_root", "").strip()
    if not configured_root:
        report.info("external data", "external_source_root not configured; archive indexes remain auditable")
        return
    root = Path(os.path.expanduser(configured_root))
    if not root.is_dir():
        report.warn("external data", "configured external root is unavailable")
        return
    failures = []
    for row in tables.get("intake", []):
        relative = row.get("relative_path", "")
        if not relative: continue
        path = root / relative
        if not path.is_file() or path.stat().st_size != int(row["size_bytes"]) or sha256(path) != row["sha256"]: failures.append(row["intake_id"])
    if failures: report.fail("external data", "missing/hash mismatch: " + ", ".join(failures))
    else: report.pass_("external data", "all indexed files verified")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, help="TOML config; defaults to local then example")
    parser.add_argument("--profile", choices=sorted(PROFILES), help="override configured profile")
    parser.add_argument("--json", action="store_true", help="emit stable JSON only")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = Report(args.json)
    config_path = args.config or (DEFAULT_CONFIG if DEFAULT_CONFIG.is_file() else EXAMPLE_CONFIG)
    config = load_config(config_path, report)
    if config is None:
        if args.json: print(json.dumps(report.result(args.profile or "unknown"), ensure_ascii=False, indent=2))
        return 2
    profile = args.profile or config.get("default_profile", "archive")
    if profile not in PROFILES:
        report.fail("profile", f"unsupported profile {profile}")
    else:
        report.pass_("profile", profile)
    check_platform(report, profile)
    versions, commands = config["versions"], config["commands"]
    check_python(report, versions["python_min"])
    git = check_command(report, "Git", commands["git"], ["--version"], versions["git_min"])
    if profile == "archive":
        if resolve_command(commands["git_lfs"]):
            check_command(report, "Git LFS", commands["git_lfs"], ["version"], versions["git_lfs_min"], required=False)
        else:
            report.info("Git LFS", "client not installed; archive pointer and attribute checks remain available")
    elif profile == "blender-replay":
        check_command(report, "Git LFS", commands["git_lfs"], ["version"], versions["git_lfs_min"])
        check_command(report, "FFmpeg", commands["ffmpeg"], ["-version"], versions["ffmpeg_min"], required=False)
        check_blender(report, config); check_mpfb(report, config)
    elif profile == "windows-extraction":
        check_command(report, "PowerShell", commands["powershell"], ["--version"], versions["powershell_min"])
        check_command(report, "FFmpeg", commands["ffmpeg"], ["-version"], versions["ffmpeg_min"])
    elif profile == "unity-dev":
        check_command(report, "Git LFS", commands["git_lfs"], ["version"], versions["git_lfs_min"])
        check_unity(report, config)

    for label, relative in {"README": "README.md", "manifest rules": "Reference/Manifests/README.md", "environment and data policy": "Docs/Development/ENVIRONMENT.md"}.items():
        (report.pass_ if (REPO_ROOT / relative).is_file() else report.fail)(label, "exists" if (REPO_ROOT / relative).is_file() else "missing")

    tables = check_manifests(report, config)
    check_cross_references(report, config, tables)
    check_manifest_files(report, tables)
    check_tool_inventory(report, tables)
    check_markdown_links(report)
    check_absolute_paths(report)
    check_lfs(report, git, tables)
    check_external_data(report, config, tables)

    if args.json:
        print(json.dumps(report.result(profile), ensure_ascii=False, indent=2))
    else:
        print(f"Summary: {report.failures} failure(s), {report.warnings} warning(s)")
    return 1 if report.failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
