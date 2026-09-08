#!/usr/bin/env python3
"""Read-only environment checks for the Direction C production baseline."""

from __future__ import annotations

import argparse
import csv
import os
import platform
import plistlib
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11 can still report a useful failure.
    tomllib = None


SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parents[2]
DEFAULT_CONFIG = SCRIPT_PATH.with_name("toolchain.local.toml")
EXAMPLE_CONFIG = SCRIPT_PATH.with_name("toolchain.example.toml")

DEFAULTS: dict[str, Any] = {
    "project": {
        "primary_platform": "macos-arm64",
        "unity_project": "Game",
        "local_data": "LocalData",
        "reference_manifest": "Reference/Manifests/honey-reference-manifest.csv",
        "asset_manifest": "Reference/Manifests/honey-asset-manifest.csv",
        "tool_manifest": "Tools/tool-manifest.csv",
    },
    "required": {
        "python_min": "3.11",
        "git_min": "2.30",
        "git_lfs_min": "3.0",
        "ffmpeg_min": "6.0",
        "blender_version": "4.5",
        "unity_version": "6000.4.1f1",
        "unity_render_pipeline": "URP",
    },
    "commands": {
        "git": "git",
        "git_lfs": "git-lfs",
        "ffmpeg": "ffmpeg",
        "blender": "blender",
        "unity": "",
    },
}


class Report:
    def __init__(self) -> None:
        self.failures = 0
        self.warnings = 0

    def emit(self, level: str, label: str, message: str) -> None:
        if level == "FAIL":
            self.failures += 1
        elif level == "WARN":
            self.warnings += 1
        print(f"[{level}] {label}: {message}")

    def pass_(self, label: str, message: str) -> None:
        self.emit("PASS", label, message)

    def warn(self, label: str, message: str) -> None:
        self.emit("WARN", label, message)

    def fail(self, label: str, message: str) -> None:
        self.emit("FAIL", label, message)

    def info(self, label: str, message: str) -> None:
        self.emit("INFO", label, message)


def version_tuple(value: str) -> tuple[int, ...]:
    match = re.search(r"(\d+(?:\.\d+)+)", value)
    if not match:
        return ()
    return tuple(int(part) for part in match.group(1).split("."))


def version_at_least(actual: str, minimum: str) -> bool:
    actual_tuple = version_tuple(actual)
    minimum_tuple = version_tuple(minimum)
    if not actual_tuple or not minimum_tuple:
        return False
    length = max(len(actual_tuple), len(minimum_tuple))
    return actual_tuple + (0,) * (length - len(actual_tuple)) >= minimum_tuple + (0,) * (
        length - len(minimum_tuple)
    )


def merge_dict(base: dict[str, Any], overlay: dict[str, Any]) -> dict[str, Any]:
    merged: dict[str, Any] = {}
    for key, value in base.items():
        merged[key] = dict(value) if isinstance(value, dict) else value
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key].update(value)
        else:
            merged[key] = value
    return merged


def load_config(path: Path, report: Report) -> dict[str, Any] | None:
    if tomllib is None:
        report.fail("Python TOML", "需要 Python 3.11+ 的标准库 tomllib")
        return DEFAULTS
    if not path.is_file():
        report.fail("配置", "指定的工具链配置不存在")
        return None
    try:
        with path.open("rb") as handle:
            loaded = tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        report.fail("配置", f"无法读取 TOML: {exc.__class__.__name__}")
        return None
    report.pass_("配置", "已读取本地配置" if path.name.endswith("local.toml") else "已读取示例配置")
    return merge_dict(DEFAULTS, loaded)


def resolve_command(configured: str, fallbacks: list[Path] | None = None) -> str | None:
    if configured:
        candidate = Path(os.path.expanduser(configured))
        if candidate.is_file():
            return str(candidate)
        found = shutil.which(configured)
        if found:
            return found
    for fallback in fallbacks or []:
        if fallback.is_file():
            return str(fallback)
    return None


def run_version(command: str, args: list[str]) -> str | None:
    try:
        result = subprocess.run(
            [command, *args],
            check=False,
            capture_output=True,
            text=True,
            timeout=8,
            env={**os.environ, "LC_ALL": "C"},
        )
    except (OSError, subprocess.SubprocessError):
        return None
    combined = "\n".join(part for part in (result.stdout, result.stderr) if part).strip()
    return combined.splitlines()[0] if combined else None


def check_command(
    report: Report,
    label: str,
    configured: str,
    args: list[str],
    minimum: str,
    fallbacks: list[Path] | None = None,
) -> str | None:
    command = resolve_command(configured, fallbacks)
    if not command:
        report.fail(label, f"未找到；要求 {minimum}+")
        return None
    output = run_version(command, args)
    if not output:
        report.fail(label, "已定位但无法读取版本")
        return command
    if version_at_least(output, minimum):
        match = re.search(r"\d+(?:\.\d+)+", output)
        report.pass_(label, f"版本 {match.group(0) if match else '已验证'}")
    else:
        report.fail(label, f"版本低于 {minimum}；检测结果 {output[:80]}")
    return command


def check_platform(report: Report) -> None:
    system = platform.system()
    machine = platform.machine().lower()
    if system == "Darwin" and machine in {"arm64", "aarch64"}:
        report.pass_("主平台", "macOS Apple Silicon")
    elif system == "Darwin":
        report.fail("主平台", f"macOS 架构为 {machine or 'unknown'}，需要 arm64 原生环境")
    elif system == "Windows":
        report.warn("主平台", "当前为 Windows 辅助环境；正式生产基线为 macOS arm64")
    else:
        report.warn("主平台", f"当前为 {system or 'unknown'}；未列为正式主环境")


def read_blender_version_from_plist() -> str | None:
    plist = Path("/Applications/Blender.app/Contents/Info.plist")
    if not plist.is_file():
        return None
    try:
        with plist.open("rb") as handle:
            data = plistlib.load(handle)
    except (OSError, plistlib.InvalidFileException):
        return None
    value = data.get("CFBundleShortVersionString") or data.get("CFBundleVersion")
    return str(value) if value else None


def check_blender(report: Report, configured: str, expected: str) -> None:
    detected = read_blender_version_from_plist() if platform.system() == "Darwin" else None
    if detected:
        if version_tuple(detected)[:2] == version_tuple(expected)[:2]:
            report.pass_("Blender", f"版本 {detected}")
        else:
            report.fail("Blender", f"检测到 {detected}，要求 {expected}.x LTS")
        return
    command = resolve_command(
        configured,
        [Path("/Applications/Blender.app/Contents/MacOS/Blender")],
    )
    if not command:
        report.fail("Blender", f"未找到；要求 {expected}.x LTS")
        return
    output = run_version(command, ["--version"])
    if output and version_tuple(output)[:2] == version_tuple(expected)[:2]:
        report.pass_("Blender", f"版本 {version_tuple(output)[0]}.{version_tuple(output)[1]}")
    else:
        report.fail("Blender", f"无法确认要求的 {expected}.x LTS")


def check_unity(report: Report, configured: str, expected: str, unity_project: Path) -> None:
    project_version = unity_project / "ProjectSettings" / "ProjectVersion.txt"
    if project_version.is_file():
        try:
            content = project_version.read_text(encoding="utf-8")
        except OSError:
            report.fail("Unity 项目", "存在但无法读取版本文件")
        else:
            match = re.search(r"m_EditorVersion:\s*(\S+)", content)
            actual = match.group(1) if match else "unknown"
            if actual == expected:
                report.pass_("Unity 项目", f"版本 {actual}")
            else:
                report.fail("Unity 项目", f"版本 {actual}，要求 {expected}")
    else:
        report.warn("Unity 项目", "尚未初始化；C0 允许，C6 前必须建立 Game/ URP 工程")

    candidates = [
        Path(f"/Applications/Unity/Hub/Editor/{expected}/Unity.app/Contents/MacOS/Unity"),
        Path(f"C:/Program Files/Unity/Hub/Editor/{expected}/Editor/Unity.exe"),
    ]
    if resolve_command(configured, candidates):
        report.pass_("Unity Editor", f"已定位批准版本 {expected}")
    else:
        report.warn("Unity Editor", f"未定位 {expected}；安装路径可在本地 TOML 配置")


def check_required_paths(report: Report, config: dict[str, Any]) -> None:
    project = config["project"]
    required_files = {
        "参考 manifest": project["reference_manifest"],
        "资产 manifest": project["asset_manifest"],
        "工具 manifest": project["tool_manifest"],
        "LFS 规则": ".gitattributes",
        "版本控制规则": ".gitignore",
    }
    for label, relative in required_files.items():
        if (REPO_ROOT / relative).is_file():
            report.pass_(label, "存在")
        else:
            report.fail(label, "缺失")

    local_data = REPO_ROOT / project["local_data"]
    if local_data.is_dir() and (local_data / "README.md").is_file():
        report.pass_("LocalData", "本地数据边界已建立")
    else:
        report.fail("LocalData", "目录或说明缺失")


def check_csv_schema(report: Report, relative: str, required_fields: set[str], label: str) -> None:
    path = REPO_ROOT / relative
    if not path.is_file():
        return
    try:
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            fields = set(reader.fieldnames or [])
    except (OSError, csv.Error):
        report.fail(label, "CSV 无法解析")
        return
    missing = sorted(required_fields - fields)
    if missing:
        report.fail(label, "缺少字段: " + ", ".join(missing))
    else:
        report.pass_(label, "字段完整")


def check_optional_capabilities(report: Report, config: dict[str, Any]) -> None:
    if platform.system() == "Windows":
        powershell = shutil.which("pwsh") or shutil.which("powershell")
        if powershell:
            report.info("Windows 提取", "PowerShell 可用；其他工具按需在本地配置")
        else:
            report.warn("Windows 提取", "PowerShell 不可用；仅影响可选提取链")
    else:
        report.info("Windows 提取", "非 Windows 主机；可选能力不参与 Gate")

    optional = config.get("optional_hunyuan", {})
    if optional.get("required", False):
        report.warn("Hunyuan3D", "本地配置将其标为 required，但正式方向 C 不要求 CUDA 路线")
    else:
        report.info("Hunyuan3D", "可选历史实验；不检查 CUDA、权重或 vendor")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        type=Path,
        help="TOML 配置；默认优先 toolchain.local.toml，否则使用 example",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = Report()
    config_path = args.config or (DEFAULT_CONFIG if DEFAULT_CONFIG.is_file() else EXAMPLE_CONFIG)
    config = load_config(config_path, report)
    if config is None:
        return 2

    required = config["required"]
    commands = config["commands"]
    project = config["project"]

    print("Direction C environment check (read-only)")
    check_platform(report)

    python_actual = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    if version_at_least(python_actual, required["python_min"]):
        report.pass_("Python", f"版本 {python_actual}")
    else:
        report.fail("Python", f"版本 {python_actual}，要求 {required['python_min']}+")

    check_command(report, "Git", commands["git"], ["--version"], required["git_min"])
    check_command(report, "Git LFS", commands["git_lfs"], ["version"], required["git_lfs_min"])
    check_command(report, "FFmpeg", commands["ffmpeg"], ["-version"], required["ffmpeg_min"])
    check_blender(report, commands.get("blender", ""), required["blender_version"])
    check_unity(
        report,
        commands.get("unity", ""),
        required["unity_version"],
        REPO_ROOT / project["unity_project"],
    )

    check_required_paths(report, config)
    check_csv_schema(
        report,
        project["reference_manifest"],
        {"source_id", "source_url", "local_logical_path", "sha256", "rights_status", "decision"},
        "参考 manifest schema",
    )
    check_csv_schema(
        report,
        project["asset_manifest"],
        {"asset_id", "stage", "source_logical_path", "source_sha256", "lfs_status", "review_status"},
        "资产 manifest schema",
    )
    check_csv_schema(
        report,
        project["tool_manifest"],
        {"tool_path", "platform", "status", "dependencies", "side_effect", "validation"},
        "工具 manifest schema",
    )
    check_optional_capabilities(report, config)

    print(f"Summary: {report.failures} required failure(s), {report.warnings} warning(s)")
    return 1 if report.failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
