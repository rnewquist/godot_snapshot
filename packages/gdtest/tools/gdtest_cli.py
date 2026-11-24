#!/usr/bin/env python3
"""
gdtest_cli.py - Standalone CLI Orchestrator & Installer for GDTest 3.0
Deterministic Integration Testing & Godot Scene Snapshot (GSS) Framework for Godot 4.x.

Usage:
  python3 gdtest_cli.py install <project_path>
  python3 gdtest_cli.py update <project_path>
  python3 gdtest_cli.py generate <project_path> <suite_name> [--type {unit,integration}]
  python3 gdtest_cli.py run [<project_path>] [--suite <name>] [--test <name>] [--type <type>] [--timeout <sec>]
  python3 gdtest_cli.py version
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

VERSION = "3.0.0"
REPO_ROOT = Path(__file__).resolve().parent.parent
ADDON_SOURCE = REPO_ROOT / "addons" / "gdtest"


def find_godot_binary() -> str:
    """Locate the Godot 4 binary across platforms."""
    # 1. Environment Variable
    if "GODOT_BIN" in os.environ and Path(os.environ["GODOT_BIN"]).exists():
        return os.environ["GODOT_BIN"]

    # 2. macOS Application Bundles & Common Paths
    mac_paths = [
        "/Applications/Godot.app/Contents/MacOS/Godot",
        os.path.expanduser("~/Applications/Godot.app/Contents/MacOS/Godot"),
        "/Applications/Godot_mono.app/Contents/MacOS/Godot",
        os.path.expanduser("~/Applications/Godot_mono.app/Contents/MacOS/Godot"),
    ]
    for p in mac_paths:
        if Path(p).exists():
            return p

    # 3. Windows Standard Paths
    win_paths = [
        os.path.expandvars(r"%ProgramFiles%\Godot\Godot.exe"),
        os.path.expandvars(r"%ProgramFiles(x86)%\Godot\Godot.exe"),
        os.path.expandvars(r"%LOCALAPPDATA%\Godot\Godot.exe"),
    ]
    for p in win_paths:
        if Path(p).exists():
            return p

    # 4. PATH search
    candidates = ["godot4", "godot", "godot-bin", "godot.exe", "godot4.exe"]
    for c in candidates:
        found = shutil.which(c)
        if found:
            return found

    raise FileNotFoundError(
        "Godot 4 binary not found. Set the GODOT_BIN environment variable to your Godot executable path."
    )


def install_framework(target_project: str, force: bool = False) -> None:
    """Install the GDTest framework addon and initialize directory structure."""
    proj_path = Path(target_project).resolve()
    if not proj_path.exists():
        raise FileNotFoundError(f"Target project directory not found: {proj_path}")

    # Check for project.godot
    proj_godot = proj_path / "project.godot"
    if not proj_godot.exists():
        print(f"⚠️ Warning: 'project.godot' not found in {proj_path}. Make sure this is a Godot project root.")

    dest_addon = proj_path / "addons" / "gdtest"
    dest_addon.parent.mkdir(parents=True, exist_ok=True)

    if dest_addon.exists():
        if not force:
            print(f"ℹ️ GDTest addon already exists at {dest_addon}. Overwriting with latest files...")
        shutil.rmtree(dest_addon)

    if not ADDON_SOURCE.exists():
        raise FileNotFoundError(f"Source GDTest addon directory not found at: {ADDON_SOURCE}")

    shutil.copytree(ADDON_SOURCE, dest_addon)
    print(f"✅ Installed GDTest v{VERSION} addon to: {dest_addon}")

    # Ensure tests and artifacts directories exist
    tests_dir = proj_path / "tests"
    tests_dir.mkdir(parents=True, exist_ok=True)

    artifacts_dir = proj_path / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    (artifacts_dir / "checkpoints").mkdir(parents=True, exist_ok=True)

    # Enable plugin in project.godot if present
    if proj_godot.exists():
        _enable_plugin_in_project_godot(proj_godot)

    # Create starter test if tests/ is empty
    existing_tests = list(tests_dir.glob("**/*.gd"))
    if not existing_tests:
        sample_test_path = tests_dir / "test_example.gd"
        sample_code = """# test_example.gd
# Sample starter test suite created by GDTest 3.0 CLI
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Starter_Integration_Suite"
	test_type = "integration"

func test_engine_initialization() -> void:
	assert_true(Engine.get_frames_drawn() >= 0, "Engine frame count should be valid")
	assert_eq(typeof(Vector2.ZERO), TYPE_VECTOR2, "Vector2 type must be valid")

func test_fluent_expectations() -> void:
	var value: int = 42
	expect(value).to_equal(42)
	expect(value).to_be_greater_than(10)

func test_node_lifecycle_and_autofree() -> void:
	var node = autofree(Node2D.new())
	add_child(node)
	expect_node(node).to_be_inside_tree()
"""
        sample_test_path.write_text(sample_code, encoding="utf-8")
        print(f"✅ Created starter test suite: {sample_test_path}")

    print(f"🎉 Successfully installed GDTest v{VERSION} in '{proj_path.name}'.")


def _enable_plugin_in_project_godot(proj_godot: Path) -> None:
    """Ensure GDTest plugin is enabled in project.godot."""
    try:
        content = proj_godot.read_text(encoding="utf-8")
        plugin_entry = '"res://addons/gdtest/plugin.cfg"'

        if "res://addons/gdtest/plugin.cfg" in content:
            return  # Already enabled

        if "[editor_plugins]" in content:
            # Append to existing section
            lines = content.splitlines()
            new_lines = []
            in_section = False
            for line in lines:
                if line.strip() == "[editor_plugins]":
                    in_section = True
                    new_lines.append(line)
                    continue
                if in_section and line.startswith("enabled="):
                    # Modify enabled list
                    if "PackedStringArray(" in line:
                        line = line.replace("PackedStringArray(", f"PackedStringArray({plugin_entry}, ")
                    new_lines.append(line)
                    in_section = False
                    continue
                if in_section and line.startswith("["):
                    # New section without finding enabled
                    new_lines.append(f"enabled=PackedStringArray({plugin_entry})")
                    in_section = False
                new_lines.append(line)
            proj_godot.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
        else:
            # Append editor_plugins section
            content += f"\n[editor_plugins]\n\nenabled=PackedStringArray({plugin_entry})\n"
            proj_godot.write_text(content, encoding="utf-8")
        print("✅ Enabled GDTest plugin in project.godot")
    except Exception as e:
        print(f"⚠️ Note: Could not auto-modify project.godot ({e}). Enable plugin via Project Settings -> Plugins.")


def generate_test(target_project: str, suite_name: str, test_type: str = "integration") -> Path:
    """Generate a clean boilerplate GDScript test suite tailored for Unit or Integration testing."""
    proj_path = Path(target_project).resolve()
    tests_dir = proj_path / "tests"
    tests_dir.mkdir(parents=True, exist_ok=True)

    slug = suite_name.lower().replace(" ", "_").replace("-", "_")
    if not slug.startswith("test_"):
        slug = f"test_{slug}"
    file_path = tests_dir / f"{slug}.gd"

    class_title = "".join(part.capitalize() for part in slug.split("_"))

    if test_type == "unit":
        code = f"""# {file_path.name}
# Pure Unit Test Suite: Fast deterministic testing of pure functions, math, data structures & signals
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "{class_title}_Suite"
	test_type = "unit"

func test_pure_logic_and_math() -> void:
	var v1 = Vector3(1, 2, 3)
	var v2 = Vector3(4, 5, 6)
	expect(v1 + v2).to_equal(Vector3(5, 7, 9))
	expect(v1.length()).to_be_approx(3.74165, 0.001)

func test_signal_spy_observation() -> void:
	var emitter = autofree(Node.new())
	emitter.add_user_signal("status_updated", [{{"name": "status", "type": TYPE_STRING}}])
	
	watch_signal(emitter, &"status_updated")
	assert_signal_not_emitted(emitter, &"status_updated")
	
	emitter.emit_signal("status_updated", "ready")
	assert_signal_emitted(emitter, &"status_updated")
	assert_signal_count(emitter, &"status_updated", 1)
"""
    else:  # integration
        code = f"""# {file_path.name}
# Deterministic Integration Test Suite: Physics, Input Simulation & Multi-Node Coordination
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "{class_title}_Integration_Suite"
	test_type = "integration"

func test_simulated_input_and_physics() -> void:
	var body = autofree(RigidBody2D.new())
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	body.add_child(shape)
	add_child(body)
	body.position = Vector2(200, 100)
	
	var initial_y = body.position.y
	await step_physics_frames(10)
	assert_true(body.position.y >= initial_y, "RigidBody2D must descend or stay within physics bounds")
"""
    file_path.write_text(code, encoding="utf-8")
    print(f"✅ Generated {test_type.upper()} test suite: {file_path}")
    return file_path


def run_tests(
    target_project: str = ".",
    suite_filter: str = "",
    test_filter: str = "",
    test_type: str = "",
    tests_dir: str = "",
    headless: bool = True,
    timeout_sec: int = 60,
    output_json: str = "",
    output_junit: str = "",
) -> int:
    """Execute tests on the target Godot project."""
    godot_bin = find_godot_binary()
    proj_path = Path(target_project).resolve()

    if not proj_path.exists():
        raise FileNotFoundError(f"Project path does not exist: {proj_path}")

    # Ensure GDTest addon exists in project
    dest_addon = proj_path / "addons" / "gdtest"
    if not dest_addon.exists():
        if ADDON_SOURCE.exists():
            print("GDTest addon not found in target project. Auto-installing...")
            install_framework(str(proj_path))
        else:
            print("⚠️ Warning: GDTest addon not found in project, and source addon not accessible.")

    artifacts_dir = proj_path / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    engine_log = artifacts_dir / "engine.log"

    cmd = [
        godot_bin,
        "--path",
        str(proj_path),
        "--log-file",
        str(engine_log),
        "res://addons/gdtest/core/test_runner_scene.tscn",
    ]

    if headless:
        cmd.extend(["--headless", "--audio-driver", "Dummy"])
    else:
        cmd.extend(["--resolution", "1280x720"])

    user_args = []
    if suite_filter:
        user_args.append(f"--suite={suite_filter}")
    if test_filter:
        user_args.append(f"--test={test_filter}")
    if test_type:
        user_args.append(f"--type={test_type}")
    if tests_dir:
        user_args.append(f"--dir={tests_dir}")

    if user_args:
        cmd.append("--")
        cmd.extend(user_args)

    print(f"🚀 Running GDTest 3.0 on: {proj_path.name}")
    print(f"▶ Command: {' '.join(cmd)}\n")
    start_time = time.time()

    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )

        for line in iter(process.stdout.readline, ""):
            if line:
                print(f"  {line.rstrip()}")

        exit_code = process.wait(timeout=timeout_sec)
    except subprocess.TimeoutExpired:
        process.kill()
        print(f"\n❌ Test execution timed out after {timeout_sec} seconds!")
        return 1
    except KeyboardInterrupt:
        process.kill()
        print("\n⚠️ Test execution interrupted by user.")
        return 130

    duration = time.time() - start_time
    print(f"\n✨ Test run finished in {duration:.2f}s (Exit code: {exit_code})")

    # Display test summary if JSON exists
    results_json = artifacts_dir / "test_results.json"
    if results_json.exists():
        try:
            with open(results_json, "r", encoding="utf-8") as f:
                data = json.load(f)
            summary = data.get("summary", {})
            print("--------------------------------------------------------")
            print(
                f"📊 Summary: {summary.get('passed_tests', 0)}/{summary.get('total_tests', 0)} tests passed "
                f"across {summary.get('passed_suites', 0)}/{summary.get('total_suites', 0)} suites "
                f"({summary.get('total_assertions', 0)} assertions)"
            )
            print("--------------------------------------------------------")
        except Exception:
            pass

    return exit_code


def print_version() -> None:
    """Print GDTest version information."""
    print(f"GDTest v{VERSION} - Universal Testing Framework for Godot 4.x")
    print("Copyright (c) 2026 GDTest Contributors (MIT License)")


def main():
    parser = argparse.ArgumentParser(
        description=f"GDTest v{VERSION} - Universal CLI Orchestrator & Test Runner for Godot 4.x",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # install command
    install_parser = subparsers.add_parser("install", help="Install GDTest framework to a Godot project")
    install_parser.add_argument("project", help="Path to target Godot project directory")
    install_parser.add_argument("--force", action="store_true", help="Force overwrite existing installation")

    # update command
    update_parser = subparsers.add_parser("update", help="Update GDTest framework in a Godot project")
    update_parser.add_argument("project", help="Path to target Godot project directory")

    # generate command
    gen_parser = subparsers.add_parser("generate", help="Generate a new GDScript test suite")
    gen_parser.add_argument("project", help="Path to target Godot project directory")
    gen_parser.add_argument("suite", help="Name of the test suite (e.g. 'player_movement')")
    gen_parser.add_argument(
        "--type",
        choices=["unit", "integration"],
        default="integration",
        help="Type of test suite (unit, integration)",
    )

    # run command
    run_parser = subparsers.add_parser("run", help="Run tests on a Godot project")
    run_parser.add_argument("project", nargs="?", default=".", help="Path to Godot project (default: current dir)")
    run_parser.add_argument("--suite", default="", help="Filter by test suite name (substring)")
    run_parser.add_argument("--test", "--method", dest="test", default="", help="Filter by test method name")
    run_parser.add_argument(
        "--type", "--tier", dest="test_type", default="", help="Filter by test type ('unit', 'integration')"
    )
    run_parser.add_argument("--dir", default="", help="Override tests directory (default: res://tests/)")
    run_parser.add_argument("--windowed", action="store_true", help="Run in windowed mode (non-headless)")
    run_parser.add_argument("--timeout", type=int, default=60, help="Test execution timeout in seconds (default: 60)")

    # version command
    subparsers.add_parser("version", help="Show GDTest version")

    args = parser.parse_args()

    if args.command == "install":
        install_framework(args.project, force=args.force)
        sys.exit(0)
    elif args.command == "update":
        install_framework(args.project, force=True)
        sys.exit(0)
    elif args.command == "generate":
        generate_test(args.project, args.suite, test_type=args.type)
        sys.exit(0)
    elif args.command == "run":
        code = run_tests(
            target_project=args.project,
            suite_filter=args.suite,
            test_filter=args.test,
            test_type=args.test_type,
            tests_dir=args.dir,
            headless=(not args.windowed),
            timeout_sec=args.timeout,
        )
        sys.exit(code)
    elif args.command == "version":
        print_version()
        sys.exit(0)


if __name__ == "__main__":
    main()
