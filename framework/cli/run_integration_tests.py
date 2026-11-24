#!/usr/bin/env python3
"""
run_integration_tests.py
Universal CLI tool for executing deterministic Godot 4.x integration test suites.
Discovers test scenes, runs them with the engine in headless or windowed mode,
and reports pass/fail metrics with exit codes.
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from godot_test import MacOSEmbeddedDebugSession

def find_godot_binary() -> str:
    """Locate the Godot 4 binary."""
    # Check environment variable
    if "GODOT_BIN" in os.environ and Path(os.environ["GODOT_BIN"]).exists():
        return os.environ["GODOT_BIN"]
    
    # Common Mac paths
    mac_paths = [
        "/Applications/Godot.app/Contents/MacOS/Godot",
        os.path.expanduser("~/Applications/Godot.app/Contents/MacOS/Godot"),
    ]
    for p in mac_paths:
        if Path(p).exists():
            return p
            
    # System PATH lookup
    import shutil
    which_godot = shutil.which("godot") or shutil.which("godot4")
    if which_godot:
        return which_godot
        
    raise FileNotFoundError("Godot binary not found. Please set GODOT_BIN environment variable.")

def run_test_scenario(
    godot_bin: str,
    project_dir: str,
    scenario_res: str,
    headless: bool = True,
    timeout_sec: int = 60,
    visible_window: bool = False,
) -> dict:
    """Run a specific test scenario scene."""
    project_path = Path(project_dir).resolve()
    cmd = [
        godot_bin,
        "--path", str(project_path),
    ]
    
    embedded_session = None
    if headless:
        cmd.append("--headless")
        cmd.extend(["--audio-driver", "Dummy"])
    elif sys.platform == "darwin" and not visible_window:
        embedded_session = MacOSEmbeddedDebugSession()
        cmd.extend(embedded_session.cli_args("1280x720"))
    else:
        cmd.extend(["--resolution", "1280x720"])

    cmd.append(scenario_res)
        
    print(f"▶ Executing: {' '.join(cmd)}")
    start_time = time.time()
    
    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        
        output_lines = []
        while True:
            line = process.stdout.readline()
            if not line and process.poll() is not None:
                break
            if line:
                print(f"  [Engine] {line.strip()}")
                output_lines.append(line)
                
        exit_code = process.wait(timeout=timeout_sec)
    except subprocess.TimeoutExpired:
        if embedded_session is not None:
            embedded_session.request_graceful_close(process, grace_timeout=5.0)
        else:
            process.kill()
        print(f"❌ Test scenario timed out after {timeout_sec}s!")
        return {
            "scenario": scenario_res,
            "passed": False,
            "exit_code": -1,
            "error": "Timeout expired",
            "duration_sec": timeout_sec
        }
    finally:
        if embedded_session is not None:
            embedded_session.close()
        
    duration = time.time() - start_time
    
    # Check for generated test report
    report_json_path = project_path / "artifacts" / "test_results.json"
    test_report_data = None
    if report_json_path.exists():
        try:
            with open(report_json_path, "r", encoding="utf-8") as f:
                test_report_data = json.load(f)
        except Exception as e:
            print(f"Warning: Could not parse test report JSON: {e}")
            
    passed = (exit_code == 0)
    return {
        "scenario": scenario_res,
        "passed": passed,
        "exit_code": exit_code,
        "duration_sec": duration,
        "report_data": test_report_data,
        "stdout": "".join(output_lines)
    }

def main():
    parser = argparse.ArgumentParser(description="Godot Integration Test Runner CLI")
    parser.add_argument("--project", default="showcase_mega", help="Target project directory")
    parser.add_argument("--scenario", default="res://test_runner_scene.tscn", help="Test scene resource path")
    parser.add_argument("--windowed", action="store_true", help="Run in windowed mode (default is headless)")
    parser.add_argument("--timeout", type=int, default=60, help="Execution timeout in seconds")
    parser.add_argument("--all", action="store_true", help="Run all known test scenarios in workspace")
    
    args = parser.parse_args()
    
    godot_bin = find_godot_binary()
    print(f"Using Godot binary: {godot_bin}")
    
    scenarios = []
    if args.all:
        scenarios = [
            ("showcase_mega", "res://test_runner_scene.tscn"),
            ("showcase_2d", "res://test_showcase_2d.tscn"),
            ("showcase_3d", "res://test_showcase_3d.tscn"),
        ]
    else:
        scenarios = [(args.project, args.scenario)]
        
    overall_passed = True
    results = []
    
    print("\n========================================================")
    print("🚀 DISPATCHING GODOT INTEGRATION TEST RUN")
    print("========================================================\n")
    
    for proj, scen in scenarios:
        res = run_test_scenario(godot_bin, proj, scen, headless=(not args.windowed), timeout_sec=args.timeout)
        results.append((proj, scen, res))
        if not res["passed"]:
            overall_passed = False
            
    print("\n========================================================")
    print("📋 INTEGRATION TEST SUITE RESULTS")
    print("========================================================")
    for proj, scen, res in results:
        status_icon = "✅ PASS" if res["passed"] else "❌ FAIL"
        rep = res.get("report_data")
        details = ""
        if rep and "summary" in rep:
            s = rep["summary"]
            details = f"({s.get('passed_tests', 0)}/{s.get('total_tests', 0)} tests passed, {s.get('total_assertions', 0)} assertions)"
        print(f"{status_icon} | {proj} :: {scen} | {res['duration_sec']:.2f}s {details}")
        
    print("========================================================\n")
    
    sys.exit(0 if overall_passed else 1)

if __name__ == "__main__":
    main()
