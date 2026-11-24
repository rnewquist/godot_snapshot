#!/usr/bin/env python3
"""
gss_cli.py - Standalone CLI for Godot Scene Snapshot (GSS & Live GSS).

Capture static GSS screenshots or Live GSS delta recordings of any Godot 4 scene,
enable in-game hotkeys (F9/F10/F11), launch HTML inspectors in your browser, and
analyze GSS telemetry from the terminal.

Usage:
  python3 gss_cli.py snap <project_path> [--scene res://main.tscn] [--name snap1] [--open]
  python3 gss_cli.py live <project_path> [--scene res://main.tscn] [--frames 60] [--open]
  python3 gss_cli.py open <html_or_json_or_dir>
  python3 gss_cli.py analyze <json_or_dir> [--json]
  python3 gss_cli.py enable-overlay <project_path>
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import webbrowser
from pathlib import Path
from typing import Any, Dict, List, Optional

REPO_ROOT = Path(__file__).resolve().parent.parent
ADDON_CORE_SOURCE = REPO_ROOT / "addons" / "gdtest" / "core"
RUNNER_SCENE_RES = "res://addons/gdtest/core/gss_capture_runner.tscn"


def find_godot_binary() -> str:
    """Locate the Godot 4 executable across macOS, Windows, and Linux."""
    env_bin = os.environ.get("GODOT_BIN", "").strip()
    if env_bin and Path(env_bin).exists():
        return env_bin

    mac_paths = [
        "/Applications/Godot.app/Contents/MacOS/Godot",
        os.path.expanduser("~/Applications/Godot.app/Contents/MacOS/Godot"),
        "/Applications/Godot_mono.app/Contents/MacOS/Godot",
        os.path.expanduser("~/Applications/Godot_mono.app/Contents/MacOS/Godot"),
    ]
    for p in mac_paths:
        if Path(p).exists():
            return p

    win_paths = [
        os.path.expandvars(r"%ProgramFiles%\Godot\Godot.exe"),
        os.path.expandvars(r"%ProgramFiles(x86)%\Godot\Godot.exe"),
        os.path.expandvars(r"%LOCALAPPDATA%\Godot\Godot.exe"),
    ]
    for p in win_paths:
        if Path(p).exists():
            return p

    for candidate in ("godot4", "godot", "godot-bin", "godot.exe", "godot4.exe"):
        found = shutil.which(candidate)
        if found:
            return found

    raise FileNotFoundError(
        "Godot 4 binary not found. Set the GODOT_BIN environment variable to your Godot executable."
    )


def ensure_runner_files(project_dir: Path) -> None:
    """Ensure gss.gd and gss_capture_runner files exist in the target project's addon folder."""
    dest_core = project_dir / "addons" / "gdtest" / "core"
    if not dest_core.exists():
        raise FileNotFoundError(
            f"GDTest addon not found at {dest_core}. "
            f"Install it first with: python3 packages/gdtest/tools/gdtest_cli.py install {project_dir}"
        )
    for fname in ("gss_capture_runner.gd", "gss_capture_runner.tscn", "gss_overlay.gd"):
        src = ADDON_CORE_SOURCE / fname
        dst = dest_core / fname
        if src.exists() and not dst.exists():
            shutil.copy2(src, dst)


def parse_cli_result(stdout: str) -> Optional[Dict[str, Any]]:
    """Extract the JSON payload emitted after [GSS_CLI_RESULT] by gss_capture_runner.gd."""
    marker = "[GSS_CLI_RESULT] "
    for line in reversed(stdout.splitlines()):
        idx = line.find(marker)
        if idx != -1:
            raw = line[idx + len(marker):].strip()
            try:
                return json.loads(raw)
            except json.JSONDecodeError:
                return None
    return None


def check_html_inspector(html_path: Path, is_live: bool) -> List[str]:
    """Verify that the companion HTML file includes the 3-pane interactive GSS inspector."""
    if not html_path.exists():
        return [f"Missing companion HTML report: {html_path.name}"]
    text = html_path.read_text(encoding="utf-8", errors="ignore")
    required = ["tree-container", "bbox-overlay", "props-container"]
    if is_live:
        required.append("frame-scrubber")
    missing = [tok for tok in required if tok not in text]
    if missing:
        return [f"HTML inspector missing DOM element(s): {', '.join(missing)}"]
    return []


def analyze_single_file(json_path: Path) -> Dict[str, Any]:
    """Analyze a single .gss.json or .gss.live.json artifact."""
    try:
        data = json.loads(json_path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {
            "file": json_path.name,
            "path": str(json_path),
            "valid": False,
            "issues": [f"JSON parse error: {exc}"],
        }

    is_live = json_path.name.endswith(".gss.live.json") or "frames" in data
    issues: List[str] = []

    if is_live:
        html_path = json_path.with_name(json_path.name.replace(".gss.live.json", ".gss.live.html"))
        html_issues = check_html_inspector(html_path, is_live=True)
        issues.extend(html_issues)
        analysis = data.get("analysis", {}) or {}
        summary = analysis.get("summary", data.get("summary", {})) or {}
        trajectories = analysis.get("node_trajectories", {}) or {}
        events = analysis.get("events", []) or []
        bounces = [e for e in events if str(e.get("type", "")).lower().find("bounce") != -1]
        top_movers = sorted(
            [
                {
                    "node": Path(k).name or k,
                    "path": k,
                    "distance": round(float(v.get("total_distance", 0.0)), 2),
                    "max_speed": round(float(v.get("max_speed", 0.0)), 2),
                }
                for k, v in trajectories.items()
                if isinstance(v, dict)
            ],
            key=lambda x: -x["distance"],
        )[:5]
        return {
            "file": json_path.name,
            "path": str(json_path),
            "type": "LIVE_GSS",
            "valid": len(issues) == 0,
            "html_path": str(html_path),
            "html_inspector_present": len(html_issues) == 0,
            "total_frames": int(summary.get("total_frames", len(data.get("frames", [])) + 1)),
            "delta_frames": int(summary.get("delta_frames", len(data.get("frames", [])))),
            "duration_ms": int(summary.get("duration_ms", 0)),
            "active_nodes": int(summary.get("active_node_count", 0)),
            "bounces_detected": int(summary.get("bounces_detected", len(bounces))),
            "shaded_nodes": int(summary.get("shaded_node_count", 0)),
            "shader_events": int(summary.get("shader_events_detected", 0)),
            "top_movers": top_movers,
            "issues": issues,
        }

    html_path = json_path.with_name(json_path.name.replace(".gss.json", ".gss.html"))
    html_issues = check_html_inspector(html_path, is_live=False)
    issues.extend(html_issues)
    meta = data.get("metadata", data.get("summary", {})) or {}
    sh_sum = meta.get("shaders_summary", {}) if isinstance(meta, dict) else {}
    shader_list = [
        {
            "shader": str(s.get("shader_path", s.get("shader_key", ""))),
            "mode": str(s.get("shader_mode", "")),
            "uniforms": s.get("uniform_names", []),
        }
        for s in (sh_sum.get("shaders", []) or [])
        if isinstance(s, dict)
    ]
    return {
        "file": json_path.name,
        "path": str(json_path),
        "type": "STATIC_GSS",
        "valid": len(issues) == 0,
        "html_path": str(html_path),
        "html_inspector_present": len(html_issues) == 0,
        "display_server": str(meta.get("display_server", "unknown")),
        "is_synthetic_preview": bool(meta.get("is_synthetic_preview", False)),
        "total_nodes": int(meta.get("total_nodes", len(data.get("flat_nodes", [])))),
        "visible_nodes": int(meta.get("visible_nodes", 0)),
        "shaded_nodes": int(sh_sum.get("shaded_nodes", 0)),
        "unique_shaders": int(sh_sum.get("unique_shader_count", 0)),
        "shaders": shader_list,
        "issues": issues,
    }


def resolve_html_to_open(target: Path) -> Optional[Path]:
    """Resolve a file or directory argument to the best .gss.html / .gss.live.html to open."""
    if not target.exists():
        return None
    if target.is_file():
        if target.name.endswith(".html"):
            return target
        if target.name.endswith(".gss.live.json"):
            cand = target.with_name(target.name.replace(".gss.live.json", ".gss.live.html"))
            return cand if cand.exists() else None
        if target.name.endswith(".gss.json"):
            cand = target.with_name(target.name.replace(".gss.json", ".gss.html"))
            return cand if cand.exists() else None
        return None

    html_files = list(target.rglob("*.gss.html")) + list(target.rglob("*.gss.live.html"))
    if not html_files:
        return None
    html_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return html_files[0]


def enable_overlay_in_project_godot(project_dir: Path) -> bool:
    """Add GSSOverlay as an Autoload in project.godot so F9/F10/F11 hotkeys work in-game."""
    proj_file = project_dir / "project.godot"
    if not proj_file.exists():
        raise FileNotFoundError(f"project.godot not found in {project_dir}")

    ensure_runner_files(project_dir)
    text = proj_file.read_text(encoding="utf-8")
    autoload_line = 'GSSOverlay="*res://addons/gdtest/core/gss_overlay.gd"'

    if "GSSOverlay=" in text:
        return False

    if "[autoload]" in text:
        parts = text.split("[autoload]", 1)
        new_text = parts[0] + "[autoload]\n\n" + autoload_line + parts[1]
    else:
        sep = "\n" if text.endswith("\n") else "\n\n"
        new_text = text + f"{sep}[autoload]\n\n{autoload_line}\n"

    proj_file.write_text(new_text, encoding="utf-8")
    return True


def run_capture(mode: str, args: argparse.Namespace) -> int:
    project_dir = Path(args.project).resolve()
    if not (project_dir / "project.godot").exists():
        sys.stderr.write(f"ERROR: No project.godot found at: {project_dir}\n")
        return 2

    try:
        ensure_runner_files(project_dir)
        godot_bin = find_godot_binary()
    except FileNotFoundError as exc:
        sys.stderr.write(f"ERROR: {exc}\n")
        return 2

    cmd = [godot_bin, "--audio-driver", "Dummy"]
    if args.headless:
        cmd.append("--headless")
    else:
        cmd.extend(["--position", "-2000,-2000"])
    cmd.extend(["--path", str(project_dir), RUNNER_SCENE_RES, "--", f"--gss-mode={mode}"])

    if args.scene:
        cmd.append(f"--gss-scene={args.scene}")
    if args.name:
        cmd.append(f"--gss-name={args.name}")
    if args.out:
        cmd.append(f"--gss-out={args.out}")
    cmd.append(f"--gss-wait={args.wait_frames}")
    if mode == "live":
        cmd.append(f"--gss-frames={args.frames}")
        cmd.append(f"--gss-step-mode={args.step_mode}")

    print(f"Running Godot GSS {mode.upper()} capture on {project_dir.name}...")
    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=args.timeout,
    )

    result = parse_cli_result(proc.stdout)
    if not result or not result.get("success"):
        sys.stderr.write("ERROR: GSS capture failed.\n")
        if result and result.get("error"):
            sys.stderr.write(f"   Reason: {result['error']}\n")
        elif proc.stderr:
            sys.stderr.write(proc.stderr[-1000:] + "\n")
        return 1

    html_path = Path(result.get("html", ""))
    json_path = Path(result.get("json", ""))
    if mode == "live":
        print(
            f"OK: Live GSS saved: {html_path}\n"
            f"   JSON: {json_path}\n"
            f"   Stats: {result.get('total_frames', 0)} frames | "
            f"{result.get('active_nodes', 0)} active nodes | "
            f"{result.get('bounces_detected', 0)} bounces | "
            f"{result.get('shaded_nodes', 0)} shaded nodes"
        )
    else:
        preview_note = " (headless synthetic preview)" if result.get("is_synthetic_preview") else " (GPU rendered)"
        print(
            f"OK: Static GSS saved: {html_path}{preview_note}\n"
            f"   JSON: {json_path}\n"
            f"   PNG:  {result.get('png', '')}\n"
            f"   Stats: {result.get('total_nodes', 0)} nodes ({result.get('visible_nodes', 0)} visible) | "
            f"{result.get('shaded_nodes', 0)} shaded ({result.get('unique_shaders', 0)} unique shaders)"
        )

    if args.open and html_path.exists():
        webbrowser.open(html_path.as_uri())
        print(f"Opened in browser: {html_path.name}")
    return 0


def cmd_open(args: argparse.Namespace) -> int:
    target = Path(args.target).resolve()
    html_file = resolve_html_to_open(target)
    if not html_file:
        sys.stderr.write(f"ERROR: No .gss.html or .gss.live.html found at: {target}\n")
        return 1
    webbrowser.open(html_file.as_uri())
    print(f"Opened GSS Inspector: {html_file}")
    return 0


def cmd_analyze(args: argparse.Namespace) -> int:
    target = Path(args.target).resolve()
    if not target.exists():
        sys.stderr.write(f"ERROR: Path does not exist: {target}\n")
        return 2

    if target.is_file():
        files = [target]
    else:
        files = sorted(target.rglob("*.gss.json")) + sorted(target.rglob("*.gss.live.json"))

    if not files:
        sys.stderr.write(f"ERROR: No .gss.json or .gss.live.json files found in: {target}\n")
        return 1

    records = [analyze_single_file(f) for f in files]
    passed = all(r.get("valid", False) for r in records)
    payload = {
        "target": str(target),
        "count": len(records),
        "static_count": sum(1 for r in records if r.get("type") == "STATIC_GSS"),
        "live_count": sum(1 for r in records if r.get("type") == "LIVE_GSS"),
        "passed": passed,
        "artifacts": records,
    }

    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print(
            f"GSS Analysis: {payload['count']} artifacts "
            f"({payload['static_count']} Static, {payload['live_count']} Live) - "
            f"{'PASS' if passed else 'ISSUES FOUND'}"
        )
        for rec in records:
            insp = "OK" if rec.get("html_inspector_present") else "MISSING"
            if rec.get("type") == "LIVE_GSS":
                print(
                    f"  [LIVE]   {rec['file']} | Inspector:{insp} | "
                    f"frames={rec['total_frames']} ({rec['duration_ms']}ms) | "
                    f"active={rec['active_nodes']} | bounces={rec['bounces_detected']} | "
                    f"shaders={rec['shaded_nodes']} ({rec['shader_events']} Δ)"
                )
                for m in rec.get("top_movers", [])[:3]:
                    if m["distance"] > 0:
                        print(f"           ↳ mover: {m['node']} dist={m['distance']} max_speed={m['max_speed']}")
            else:
                render_tag = "SYNTHETIC" if rec.get("is_synthetic_preview") else f"GPU({rec.get('display_server')})"
                print(
                    f"  [STATIC] {rec['file']} | Inspector:{insp} | {render_tag} | "
                    f"nodes={rec.get('total_nodes', 0)} ({rec.get('visible_nodes', 0)} vis) | "
                    f"shaders={rec.get('shaded_nodes', 0)} ({rec.get('unique_shaders', 0)} unique)"
                )
            for issue in rec.get("issues", []):
                print(f"           WARN: {issue}")
    return 0 if passed else 1


def cmd_enable_overlay(args: argparse.Namespace) -> int:
    project_dir = Path(args.project).resolve()
    try:
        added = enable_overlay_in_project_godot(project_dir)
    except FileNotFoundError as exc:
        sys.stderr.write(f"ERROR: {exc}\n")
        return 2
    if added:
        print(f"OK: Enabled GSSOverlay Autoload in {project_dir / 'project.godot'}")
    else:
        print(f"NOTE: GSSOverlay Autoload is already enabled in {project_dir / 'project.godot'}")
    print("   In-game hotkeys: F9 = Static GSS Snapshot | F10 = Toggle Live GSS | F11 = Open Last Report")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="gss_cli.py",
        description="Standalone CLI to capture, open, and analyze Godot Scene Snapshots (GSS & Live GSS).",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_snap = sub.add_parser("snap", help="Capture a Static GSS Screenshot (.png + .gss.json + .gss.html)")
    p_snap.add_argument("project", help="Path to the Godot 4 project directory")
    p_snap.add_argument("--scene", default="", help="Scene path (res://...tscn). Defaults to project main_scene.")
    p_snap.add_argument("--name", default="", help="Output snapshot name (without extension)")
    p_snap.add_argument("--out", default="res://artifacts/gss", help="Output directory (default: res://artifacts/gss)")
    p_snap.add_argument("--wait-frames", type=int, default=5, help="Frames to wait before capturing (default: 5)")
    p_snap.add_argument("--headless", action="store_true", help="Run headless (fast, synthetic preview image)")
    p_snap.add_argument("--open", action="store_true", help="Open the generated .gss.html in your default browser")
    p_snap.add_argument("--timeout", type=int, default=60, help="Timeout in seconds (default: 60)")

    p_live = sub.add_parser("live", help="Capture a Live GSS Delta Recording (.gss.live.json + .gss.live.html)")
    p_live.add_argument("project", help="Path to the Godot 4 project directory")
    p_live.add_argument("--scene", default="", help="Scene path (res://...tscn). Defaults to project main_scene.")
    p_live.add_argument("--name", default="", help="Output recording name (without extension)")
    p_live.add_argument("--frames", type=int, default=60, help="Number of frames to record (default: 60)")
    p_live.add_argument("--step-mode", choices=["physics", "process"], default="physics", help="Frame stepping mode")
    p_live.add_argument("--out", default="res://artifacts/gss", help="Output directory (default: res://artifacts/gss)")
    p_live.add_argument("--wait-frames", type=int, default=5, help="Frames to wait before recording (default: 5)")
    p_live.add_argument("--headless", action="store_true", help="Run headless (fast, synthetic preview image)")
    p_live.add_argument("--open", action="store_true", help="Open the generated .gss.live.html in your default browser")
    p_live.add_argument("--timeout", type=int, default=90, help="Timeout in seconds (default: 90)")

    p_open = sub.add_parser("open", help="Open a GSS/Live GSS HTML Inspector in your default web browser")
    p_open.add_argument("target", help="Path to a .gss.html, .gss.json, or directory containing GSS reports")

    p_an = sub.add_parser("analyze", help="Analyze GSS / Live GSS JSON telemetry from the terminal")
    p_an.add_argument("target", help="Path to a .gss.json, .gss.live.json, or directory")
    p_an.add_argument("--json", action="store_true", help="Output structured JSON")

    p_ov = sub.add_parser("enable-overlay", help="Register GSSOverlay Autoload in project.godot for F9/F10/F11 hotkeys")
    p_ov.add_argument("project", help="Path to the Godot 4 project directory")

    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command == "snap":
        return run_capture("snap", args)
    if args.command == "live":
        return run_capture("live", args)
    if args.command == "open":
        return cmd_open(args)
    if args.command == "analyze":
        return cmd_analyze(args)
    if args.command == "enable-overlay":
        return cmd_enable_overlay(args)
    return 2


if __name__ == "__main__":
    sys.exit(main())
